function sys = get_ss(obj, Type, opt)
% Get the linear model of a Type (ODE / DAE).
%
% Returns the linear model of the result (E dx/dt = A x + B u, y = C x + D u). Format
% chooses its form: "ss" (default) is a descriptor state-space model (dss) with
% StateName, InputName and OutputName and needs the Control System Toolbox; "struct" is
% a struct with the fields A, B, C, D, E, StateName, InputName, OutputName (string
% columns) and needs no toolbox. For the network, "ODE" and "DAE" put the states of the
% global controllers first, then the components. Use StateName to find a state.
%
% - "DAE": the connected model of the result: the bus voltages are algebraic variables
%   (E is zero on their rows and columns), and their equations are the current balance
%   of each bus. Port chooses how each bus is written as a port, the bus variables v
%   (columns) and the balance w (rows): "PI" v = [theta, V], w = [P, Q/V]; "PQ"
%   v = [theta, rho] (rho = log V), w = [P, Q]; "I" v = [Vre, Vim], w = [-Iim, Ire]. The
%   states are named theta, V, rho, Vre, Vim + bus number. Outputs: the dynamic states.
% - "ODE": the DAE with the bus voltages eliminated (SolverLIN.reduce). States: the
%   dynamic states. Inputs: the inputs u. Outputs: the states, in their order, without
%   output names. Port does not apply.
%
% Input and Output select the channels of the model; without them the channels are the
% ones above. The states and their order do not change. Output takes these kinds and
% names, in any mix, and the outputs follow the given order (a repeated one is kept once):
%
% - "x": all states of the model, in the order of sys.StateName (for "DAE", the dynamic
%   states).
% - "V": the bus voltages Vre, Vim of each bus (also in "DAE", whatever the Port).
% - "I": the currents Ire, Iim that the components inject at each bus (Y v).
% - "y": the outputs of the components and of the local and global controllers (rows y
%   and yc of the variable map). An output with the name of a state of its owner is
%   "Y_" + name.
% - a name: Label of net.get_variable_map() for x, V and y, or a name of the kind "I" as
%   in the OutputName of that kind.
%
% Input takes "u" (all inputs) or Labels of the inputs, and the inputs follow the given
% order. An unknown name stops with GUILDA:ResultLIN:UnknownInput; an unknown Output name
% stops with GUILDA:ResultLIN:UnknownOutput.
%
% For a result of comp.get_sys, bus.get_sys, con.get_sys or gc.get_sys, get_ss returns the
% port model (voltages in, currents and outputs out); Input and Output take names of its
% inputs and outputs, and Type and Port do not apply.
%
% Index chooses the section (default res.Index; see ResultLIN), and Time, when given, the
% section whose time rv_t is nearest to it.
%
% Form chooses the view (default res.Form; see ResultLIN): "descriptor", "absorbed"
% (E^-1 in the state rows; every result) or "hessian" (the energy-function form of a
% result of net.get_sys(Form="hessian"), Port "PI" or "PQ" for "DAE"; "ODE" eliminates its
% bus variables, E = -inv(R)). "hessian" stops with GUILDA:ResultLIN:NoHessianForm
% without the form, GUILDA:ResultLIN:HessianPort with Port "I" and
% GUILDA:ResultLIN:NetworkOnly for a port model; "absorbed" with
% GUILDA:ResultLIN:SingularE when the time constants of the states are not invertible.
%
% A section that is not usable (output.sv_issue of the section) stops with an error that repeats the message of the section (output.sv_message):
% GUILDA:ResultLIN:NotFinite for every Type, and GUILDA:ResultLIN:SingularAvv for "ODE",
% which eliminates the bus voltages. "DAE" keeps them and still works.
%
% <@Examples>
% ```matlab
% res = net.get_sys();
% sysO = res.get_ss("ODE");                     % ss (Control System Toolbox)
% sysD = res.get_ss("DAE");
% eig(sysO.A, sysO.E)
% sysV = res.get_ss("ODE", Output="V");         % bus voltages as outputs
% sct  = res.get_ss("ODE", Format="struct");    % matrices and names, no toolbox
% sct3 = res.get_ss(Index=3, Format="struct");  % section 3 of a result with time sections
% sctA = res.get_ss("ODE", Form="absorbed", Format="struct");   % E = I
% ```
%
% See also PowerSystemModel.get_sys, SolverLIN.reduce, ResultLIN.Type, ResultLIN.plot_eigenvalue
    arguments (Input)
        obj
        Type (1,1) string {mustBeMember(Type, ["ODE","DAE"])} = obj.Type  % Model: "ODE" (the bus voltages eliminated) or "DAE" (the connected model); the Type of the result when omitted.
        opt.Port (1,1) string {mustBeMember(opt.Port, ["PI","PQ","I"])} = default_port(obj)  % Bus port of "DAE" (v, w): "PI" ([theta,V], [P,Q/V]), "PQ" ([theta,rho], [P,Q]) or "I" ([Vre,Vim], [-Iim,Ire]); options.Port of the result when omitted.
        opt.Input (1,:) string   % Inputs of the model: "u" or Labels. Default: all inputs.
        opt.Output (1,:) string  % Outputs of the model: "x", "V", "I", "y" or names. Default: as described for each algorithm.
        opt.Format (1,1) string {mustBeMember(opt.Format, ["ss","struct"])} = "ss"  % Form of the model: "ss" (dss; needs the Control System Toolbox) or "struct" (A, B, C, D, E and names).
        opt.Index (1,1) double {mustBeInteger, mustBePositive} = obj.Index  % Section of the model (1 ... numel(rv_t)); res.Index when omitted.
        opt.Time (1,1) double {mustBeReal}  % [s] Time: the section whose rv_t is nearest; overrides Index.
        opt.Form (1,1) string {mustBeMember(opt.Form, ["descriptor","absorbed","hessian"])} = obj.Form  % View: "descriptor", "absorbed" (E^-1 in the dynamic rows) or "hessian" (energy-function form); res.Form when omitted.
    end
    arguments (Output)
        sys  % Linear model in the form of Format, with StateName, InputName and OutputName.
    end
    % The section
    k = opt.Index;
    if isfield(opt, "Time")
        [~, k] = min(abs(obj.rv_t - opt.Time));
    end
    n_t = numel(obj.c_section);
    if k > n_t
        error(msg("GUILDA:ResultLIN:IndexRange", string(n_t)))
    end
    S = obj.c_section{k};
    s_issue   = obj.output.sv_issue(k);
    s_message = obj.output.sv_message(k);
    if ~(isfield(obj.output, "s_layer") && obj.output.s_layer == "PowerNetwork")
        % Object-level result: its port model (no algebraic variables)
        if s_issue == "NotFinite"
            error(msg("GUILDA:ResultLIN:NotFinite", s_message))
        end
        if opt.Form == "hessian"
            error(msg("GUILDA:ResultLIN:NetworkOnly", 'Form "hessian"'))
        end
        sys = model(S.A, S.B, S.C, S.D, S.E, S.StateName, S.InputName, S.OutputName);
        if opt.Form == "absorbed"
            sys = absorb(sys, 1:size(sys.A,1));
        end
        if isfield(opt, "Output")
            % the outputs by name, in the given order (a repeated one is kept once)
            sv_name = unique(reshape(opt.Output, [], 1), "stable");
            [lv_known, iv] = ismember(sv_name, sys.OutputName);
            if ~all(lv_known)
                error(msg("GUILDA:ResultLIN:UnknownOutput", sv_name(find(~lv_known,1))))
            end
            sys.C = sys.C(iv, :);
            sys.D = sys.D(iv, :);
            sys.OutputName = sys.OutputName(iv);
        end
        if isfield(opt, "Input")
            sys = input_by_index(sys, input_index(sys, opt.Input));
        end
        sys = to_format(sys, opt.Format);
        return
    end
    if s_issue == "NotFinite"
        error(msg("GUILDA:ResultLIN:NotFinite", s_message))
    elseif s_issue == "SingularAvv" && Type ~= "DAE"
        error(msg("GUILDA:ResultLIN:SingularAvv", s_message, Type))
    end
    % The DAE; "ODE" eliminates its voltages, which do not need the polar coordinates
    s_port = opt.Port;
    if opt.Form == "hessian"
        if ~isfield(S, "sct_hessian")
            error(msg("GUILDA:ResultLIN:NoHessianForm"))
        elseif Type == "ODE"
            s_port = "PI";   % the reduction does not depend on the port
        elseif s_port == "I"
            error(msg("GUILDA:ResultLIN:HessianPort"))
        end
    elseif Type == "ODE"
        s_port = "I";
    end
    % the state order of ODE and DAE: the global controllers first, then the components
    tab   = obj.tab_variable;
    tab_x = tab(tab.Kind == "x", :);
    p     = [find(tab_x.Bus == ""); find(tab_x.Bus ~= "")];
    sv_x  = tab_x.Label(p);
    sv_u  = tab.Label(tab.Kind == "u");

    % the Jacobian blocks of the section (rm_Axx ... rm_E of the result)
    n_v = S.n_v;
    n_x = size(S.A,1) - n_v;
    ix  = 1:n_x;
    iv  = n_x+1:n_x+n_v;
    Axx = S.A(ix,ix);
    Axx = Axx(p,p);
    Axv = S.A(ix(p),iv);
    Avx = S.A(iv,ix(p));
    Ex  = S.E(ix,ix);
    Ex  = Ex(p,p);
    Ev  = zeros(n_v);
    n_b = n_v/2;
    n_u = size(S.B,2);

    A_temp = [Axx, Axv; Avx, S.A(iv,iv)];
    B_temp = [S.B(ix(p),:); S.B(iv,:)];

    A_dae = A_temp([1:n_x,(n_x+1):2:end,(n_x+2):2:end],[1:n_x,(n_x+1):2:end,(n_x+2):2:end]);
    B_dae = B_temp([1:n_x,(n_x+1):2:end,(n_x+2):2:end],:);
    C_dae = [eye(n_x),zeros(n_x,n_v)];
    D_dae = zeros(n_x,n_u);
    E_dae = blkdiag(Ex, Ev);

    ir_x   = 1:n_x;
    ir_Vre = n_x + (1:n_b);
    ir_Vim = n_x + n_b + (1:n_b);

    A_dae = [ A_dae(ir_x  ,:);
             -A_dae(ir_Vim,:);
              A_dae(ir_Vre,:)];
    B_dae = [ B_dae(ir_x  ,:);
             -B_dae(ir_Vim,:);
              B_dae(ir_Vre,:)];

    [filt_o, filt_i, sr_busvar] = port_filter(S.cv_V, s_port);
    A_dae = blkdiag(eye(n_x),filt_o)      ...
            * A_dae                       ...
            * blkdiag(eye(n_x),filt_i);
    B_dae = blkdiag(eye(n_x),filt_o)      ...
            * B_dae;

    sr_busvar  = reshape(sr_busvar+(1:n_b),2,[]);
    sr_busvar  = reshape(sr_busvar',1,[]);

    sys = model(A_dae, B_dae, C_dae, D_dae, E_dae, [sv_x(:); sr_busvar(:)], sv_u, sv_x);
    if opt.Form == "absorbed"
        sys = absorb(sys, 1:n_x);
    elseif opt.Form == "hessian"
        % The energy-function form over [x; theta; V] (PI) of SolverLIN.solve, in the
        % state order p; PQ by the port transform dV = V drho, dQ = V d(Q/V) (the term
        % (Q/V) dV of the balance vanishes where the balance holds). B: the rows of the
        % states of the descriptor B times E_h E^-1, the bus rows as they are; C, D as in
        % the descriptor model (the same variables).
        Sh = S.sct_hessian;
        iv_z = [p(:); n_x + (1:n_v).'];
        H  = Sh.H(iv_z, iv_z);
        Eh = -(Sh.R(p,p) \ eye(n_x));
        if s_port == "PQ"
            rv_T = [ones(n_x + n_b, 1); abs(S.cv_V(:))];
            H = rv_T .* H .* rv_T.';
        end
        sys.B(1:n_x,:) = Eh * (Ex \ sys.B(1:n_x,:));
        sys.A = H;
        sys.E = blkdiag(Eh, Ev);
    end
    if isfield(opt, "Output")
        % The selected outputs replace those of the DAE: y = Cx x + Cv v + Du u of the
        % connected model, written with the states and inputs of the DAE
        sv_xTab = tab.Label(tab.Kind == "x");
        sv_v   = tab.Label(tab.Kind == "Vre" | tab.Kind == "Vim");
        n_x    = numel(sv_xTab);
        n_v    = numel(sv_v);
        n_u    = numel(sv_u);
        sv_y   = S.OutputName;               % outputs y and yc over [x; v] and u
        sv_I   = S.sv_I;

        % Every output, in the order of the kinds x, V, I, y
        c_kind = {["x";"V";"I";"y"], {sys.StateName(ismember(sys.StateName, sv_xTab)); sv_v; sv_I; sv_y}};
        sv_all = [sv_xTab; sv_v; sv_I; sv_y];
        Cx = [eye(n_x); zeros(2*n_v, n_x); S.C(:,1:n_x)];
        Cv = [zeros(n_x, n_v); eye(n_v); tools.complex2matrix(S.cm_Y); S.C(:,n_x+1:end)];
        Du = [zeros(n_x+2*n_v, n_u); S.D];

        sv_name = strings(0,1);
        for str = opt.Output(:)'
            lv_kind = c_kind{1} == str;
            if any(lv_kind)
                sv_name = [sv_name; c_kind{2}{lv_kind}]; %#ok<AGROW>
            else
                sv_name = [sv_name; str]; %#ok<AGROW>
            end
        end
        sv_name = unique(sv_name, "stable");

        [lv_known, iv_all] = ismember(sv_name, sv_all);
        if ~all(lv_known)
            error(msg("GUILDA:ResultLIN:UnknownOutput", sv_name(find(~lv_known,1))))
        end
        Cx = Cx(iv_all,:);
        Cv = Cv(iv_all,:);
        Du = Du(iv_all,:);

        % filt_i and p of the DAE above
        [~, iv_u] = ismember(sys.InputName, sv_u);
        sys.C = [Cx(:,p), Cv(:,[1:2:n_v, 2:2:n_v]) * filt_i];
        sys.D = Du(:,iv_u);
        sys.OutputName = sv_name;
    end
    if isfield(opt, "Input")
        sys = input_by_index(sys, input_index(sys, opt.Input));
    end
    if Type == "ODE"
        n_x = nnz(obj.tab_variable.Kind == "x");
        sys = SolverLIN.reduce(sys, n_x+1:numel(sys.StateName));
        if ~isfield(opt, "Output")
            sys.OutputName = strings(n_x,1);   % the states, without output names
        end
    end
    sys = to_format(sys, opt.Format);
end

function sys = absorb(sys, iv_x)
% The absorbed form: E^-1 of the dynamic rows (the rows of iv_x where E is not zero)
% multiplied into A and B, E = I there; a state without a time constant (a zero row of E)
% keeps its row, and E stays zero on it
    lv_d = false(size(sys.A,1), 1);
    lv_d(iv_x) = any(sys.E(iv_x,:) ~= 0, 2);
    Ed = full(sys.E(lv_d, lv_d));
    if any(sys.E(lv_d, ~lv_d) ~= 0, "all") || ~(rcond(Ed) > 1e-14)
        error(msg("GUILDA:ResultLIN:SingularE", sprintf("%g", rcond(Ed))))
    end
    sys.A(lv_d,:) = Ed \ sys.A(lv_d,:);
    sys.B(lv_d,:) = Ed \ sys.B(lv_d,:);
    sys.E(lv_d,lv_d) = eye(nnz(lv_d));
end


function sys = to_format(sct_sys, s_format)
% The model as a struct or as a dss with the names
    sys = sct_sys;
    if s_format == "ss"
        tools.require_toolbox("control", "ResultLIN.get_ss(Format=""ss"")");
        sys = dss(sct_sys.A, sct_sys.B, sct_sys.C, sct_sys.D, sct_sys.E);
        sys.StateName  = cellstr(sct_sys.StateName);
        sys.InputName  = cellstr(sct_sys.InputName);
        sys.OutputName = cellstr(sct_sys.OutputName);
    end
end


function sys = model(A, B, C, D, E, sv_x, sv_u, sv_y)
% Model struct; the names are string columns
    sys = struct("A", A, "B", B, "C", C, "D", D, "E", E, ...
                 "StateName", reshape(string(sv_x), [], 1), ...
                 "InputName", reshape(string(sv_u), [], 1), ...
                 "OutputName", reshape(string(sv_y), [], 1));
end


function sys = input_by_index(sys, iv)
    sys.B = sys.B(:, iv);
    sys.D = sys.D(:, iv);
    sys.InputName = sys.InputName(iv);
end


function str = default_port(obj)
    str = "PQ";
    if isfield(obj.options, "Port")
        str = obj.options.Port;
    end
end


function [filt_o, filt_i, sv_busvar] = port_filter(Vc_st, s_port)
% Bus port of "DAE": [Vre...; Vim...] = filt_i * v (columns), w = filt_o * (current balance) (rows)
    n_v = 2*numel(Vc_st);

    rm_Vr = diag(real(Vc_st));
    rm_Vi = diag(imag(Vc_st));
    rm_V  = diag(abs( Vc_st));

    switch s_port
        case "PI"
            filt_o = [-    rm_Vi,       rm_Vr ;
                       rm_V\rm_Vr, rm_V\rm_Vi];
            filt_i = [-    rm_Vi,  rm_V\rm_Vr ;
                           rm_Vr,  rm_V\rm_Vi];
            sv_busvar = ["theta";"V"];
        case "PQ"
            filt_o = [-rm_Vi,  rm_Vr ;
                       rm_Vr,  rm_Vi];
            filt_i = [-rm_Vi,  rm_Vr ;
                       rm_Vr,  rm_Vi];
            sv_busvar = ["theta";"rho"];
        case "I"
            filt_o = eye(n_v);
            filt_i = eye(n_v);
            sv_busvar = ["Vre";"Vim"];
    end
end


function iv = input_index(sys, sv_select)
% Positions of the selected inputs in the model
    sv_u    = sys.InputName;
    sv_name = strings(0,1);
    for str = sv_select(:)'
        if str == "u"
            sv_name = [sv_name; sv_u]; %#ok<AGROW>
        else
            sv_name = [sv_name; str]; %#ok<AGROW>
        end
    end
    sv_name = unique(sv_name, "stable");
    [lv_known, iv] = ismember(sv_name, sv_u);
    if ~all(lv_known)
        error(msg("GUILDA:ResultLIN:UnknownInput", sv_name(find(~lv_known,1))))
    end
end
