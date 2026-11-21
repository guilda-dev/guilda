function sct_reduced = get_reduced_matrix(obj, target, opt)
% Get the Jacobian of the DAE with the variables of elements eliminated (Schur complement).
%
% J is the full state matrix A of get_ss("DAE") over [x; v] (the dynamic states and the
% bus variables) in the Port of the result. The variables owned by the elements in target
% are eliminated, the rest r are kept. The row i of the result is the equation of the
% kept variable i (the state equation of a state; for a bus, the balance w of the Port:
% P for theta, Q for rho in "PQ"). State chooses how the dynamic states of the targets
% enter (a variable is dynamic when its row of E is not zero, algebraic otherwise):
%
% - "settled" (default): every variable x of the targets, the states included, is
%   eliminated by the Schur complement
%
%   ```
%   J_red = Jrr - Jrx / Jxx * Jxr
%   ```
%
%   so the equations of x are held at zero (E dx/dt = 0): the states follow the other
%   variables quasi-statically.
% - "fixed": the dynamic states of the targets are held at the point
%   (Delta x = 0): their rows and columns are removed, with no Schur term. Only the
%   algebraic variables a of the targets (the theta, rho of a target bus, or a variable
%   with a zero row of E) are eliminated, by the Schur complement
%
%   ```
%   J_red = Jrr - Jra / Jaa * Jar
%   ```
%
%   which is J(r, r) when the targets have no algebraic variables. The held states are
%   in sv_held.
%
% target selects elements as in get_contribution: tags (the Owner column of the variable
% map, or the tag of a bus) and class names, a class taking every element of that class or
% of its subclasses and a package every class in it; a target that matches no element
% stops with GUILDA:ResultLIN:UnknownTarget. The bus variables (theta, rho, ...) are owned
% by their bus (class "Bus"). Eliminating everything but the bus variables, e.g. target
% ["Component","LocalController"] (with "GlobalController" when the model has one; a class
% without elements stops as in get_contribution), gives the reduced admittance-like
% matrix seen from the buses (縮約アドミタンス): with State "settled" the steady-state
% dI/dV (the states follow), with "fixed" the instantaneous one (the states held). Elements without
% variables (branches, components without states) eliminate nothing. A singular Jxx
% ("settled") or Jaa ("fixed") stops with GUILDA:ResultLIN:SingularReduction.
%
% Index chooses the section (default res.Index; see ResultLIN), and Time, when given, the
% section whose time rv_t is nearest to it. Index "all" returns a 1 x n_t struct array.
% Only a result of the network (output.s_layer "PowerNetwork") has a DAE with bus
% variables; another layer stops with GUILDA:ResultLIN:NetworkOnly.
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% net.initialize();
% res = net.get_sys();
% sv_dev = ["Component","LocalController"];                  % no global controller here
% sct = res.get_reduced_matrix(sv_dev);                      % steady state: the states follow ("settled")
% sct.sv_row                                                 % theta1 ... theta9, rho1 ... rho9
% sctF = res.get_reduced_matrix(sv_dev, State="fixed");      % instantaneous: the states held
% sct = res.get_reduced_matrix("controller.avr");            % the AVRs settled
% ```
%
% See also ResultLIN.get_contribution, ResultLIN.get_ss, ResultLIN.get_kernel
    arguments (Input)
        obj
        target (1,:) string {mustBeNonempty}    % Tags and class (or package) names of the elements whose variables are eliminated.
        opt.State (1,1) string {mustBeMember(opt.State, ["settled","fixed"])} = "settled"  % Dynamic states of the targets: "settled" (eliminated, E dx/dt = 0) or "fixed" (held at the point, removed).
        opt.Index {mustBeSection} = obj.Index   % Section (1 ... numel(rv_t)) or "all" (a struct array, one per section); res.Index when omitted.
        opt.Time (1,1) double {mustBeReal}      % [s] Time: the section whose rv_t is nearest; overrides Index.
    end
    arguments (Output)
        sct_reduced struct  % rm_value (the reduced matrix), sv_row, sv_column (names of the kept variables), sv_eliminated (all target variables), sv_held (the held states), s_state (1 x n_t for Index "all").
    end
    if ~(isfield(obj.output, "s_layer") && obj.output.s_layer == "PowerNetwork")
        error(msg("GUILDA:ResultLIN:NetworkOnly", "get_reduced_matrix"))
    end
    iv_sec = section_list(obj, opt);
    c_red = cell(1, numel(iv_sec));
    for i = 1:numel(iv_sec)
        k = iv_sec(i);
        sys = obj.get_ss("DAE", Index=k, Format="struct");
        J = full(sys.A);
        sv_name = sys.StateName;
        lv_x = ismember(state_owner(obj, sv_name), target_owner(obj.c_section{k}.tab_owner, target));
        lv_held = false(size(lv_x));
        if opt.State == "fixed"
            lv_held = lv_x & any(sys.E, 2);   % dynamic states of the targets: removed
        end
        lv_a = lv_x & ~lv_held;               % eliminated by the Schur complement
        lv_r = ~lv_x;
        Jaa = J(lv_a, lv_a);
        r_rcond = rcond(Jaa);
        if any(lv_a) && ~(r_rcond > 1e-14)
            error(msg("GUILDA:ResultLIN:SingularReduction", sprintf("%.3g", r_rcond)))
        end
        rm_value = J(lv_r, lv_r);
        if any(lv_a)
            rm_value = rm_value - J(lv_r, lv_a) * (Jaa \ J(lv_a, lv_r));
        end
        c_red{i} = struct("rm_value", rm_value, "sv_row", sv_name(lv_r), "sv_column", sv_name(lv_r), ...
            "sv_eliminated", sv_name(lv_x), "sv_held", sv_name(lv_held), "s_state", opt.State);
    end
    sct_reduced = [c_red{:}];
end
