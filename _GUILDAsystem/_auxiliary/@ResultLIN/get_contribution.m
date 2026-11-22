function [res_e, sct_mask] = get_contribution(obj, target)
% Get the part of elements in the DAE, as a result of its own.
%
% The DAE of the result (get_ss("DAE") with the Input, Output and Port of get_sys)
% is the sum of the parts of its elements: the components, the local and global
% controllers, the branches and the buses. get_contribution returns the part of the
% elements in target, summed, as a ResultLIN res_e with every section of the result: the
% same rv_t, Index, variable map, points, options (Input, Output, Port), output and
% sct_network, each section holding the part of the connected model (the terms of the
% targets over [x; v]). So res_e.A ... res_e.OutputName are the part in the Port of the
% result for section res_e.Index, res_e.get_ss("DAE", Index=k) the part in section k, and
% the parts of all the elements sum to the DAE in every section. res_e.sv_target holds the
% targets.
%
% res_e is a part of a DAE, not a model of its own: its Type is "DAE" and cannot be
% "ODE" (setting it, get_ss("ODE") or a method with Type "ODE" stops with
% GUILDA:ResultLIN:ContributionDAE), and it has no Form "hessian". Form "absorbed" works.
% The other methods compute on the matrices of the part (eigenvalues, modes,
% participation, kernel, reduction, contribution and the plots); on a contribution result
% the numbers are of the part alone and have no meaning for the whole system.
%
% sct_mask is a 1 x n_t struct array, one per section: the fields A, B, C, D and E as
% logical matrices, true where the targets change the entry, with StateName, InputName
% and OutputName. sct_mask(res_e.Index) is the section shown by res_e.
%
% A term belongs to the element that owns its equation row:
%
% - A state row belongs to the owner of the state, with every term of it: the terms
%   through its inputs too (B_con C_gen of a controller that reads a component belongs to
%   the controller).
% - A row of the current balance of a bus is split: the current terms of each component
%   belong to that component, and the admittance matrix Y to the branches (each its
%   2-by-2 stamp) and to the bus (its shunt).
% - An output row belongs to the owner of the output: a state to its owner, a bus voltage
%   to the bus, an output y or yc to its component or controller, and a bus current
%   (Y v) to the branches and buses as in Y.
%
% target is a string array of tags (the Owner column of the variable map, or the tag of a
% branch or bus) and class names. A class name takes every element of that class or of
% its subclasses (e.g. "LocalController", "component.generator.abstract"); a package
% name takes every class in it (e.g. "controller.avr"). A target that matches no element
% stops with GUILDA:ResultLIN:UnknownTarget. The parts are a deviation model like the
% DAE. The result of a component, bus or controller has no algebraic variables: the
% parts split its port model in the same way. A section that is not usable keeps its
% issue (get_ss of it stops as for the result) and its mask has empty fields.
%
% <@Examples>
% ```matlab
% res = net.get_sys();
% res_g = res.get_contribution("B001SG1");                % one generator
% res_g.A                                                 % its part of the DAE
% [res_avr, msk] = res.get_contribution("controller.avr");
% spy(msk(res_avr.Index).A)                               % the entries the AVRs change
% res_avr.Index = 2;                                      % another section (sct_mask(2))
% ```
%
% See also ResultLIN.get_ss, ResultLIN.plot_contribution, SolverLIN.solve, PowerSystemModel.get_sys
    arguments (Input)
        obj
        target (1,:) string {mustBeNonempty}  % Tags and class (or package) names of the elements; several are summed.
    end
    arguments (Output)
        res_e ResultLIN   % Part of the targets: a result with every section (Type "DAE"), sv_target the targets.
        sct_mask struct   % Entries the targets change, one per section (1 x n_t): A, B, C, D, E (logical), StateName, InputName, OutputName.
    end
    n_t = numel(obj.c_section);
    l_net = isfield(obj.output, "s_layer") && obj.output.s_layer == "PowerNetwork";
    s_port = "I";
    if isfield(obj.options, "Port")
        s_port = obj.options.Port;
    end
    sct_opt = obj.options;
    sct_opt.Type = "DAE";
    sct_opt.Form = "descriptor";
    if obj.Form == "absorbed"
        sct_opt.Form = "absorbed";
    end
    c_nv = struct();
    for str = ["Input","Output"]
        if isfield(obj.options, str)
            c_nv.(str) = obj.options.(str);
        end
    end

    % The part of every section (an unusable section stays as it is)
    c_part = obj.c_section;
    l_found = false;
    for k = 1:n_t
        S = obj.c_section{k};
        if ~isfield(S, "sct_term")
            continue
        end
        c_part{k} = contribution_part(S, target_owner(S.tab_owner, target));
        l_found = true;
    end
    if ~l_found
        error(msg("GUILDA:ResultLIN:NotFinite", obj.output.sv_message(1)))
    end
    res_e = ResultLIN(obj.a_PowerNetwork, obj.s_solver, sct_opt, obj.flag, obj.output, NaN, ...
        obj.tab_variable, obj.rm_point, c_part, obj.rv_t, obj.sct_network);
    res_e.sv_target = target;
    res_e.Index = obj.Index;

    % The mask of every section: the entries of the part in the Port "I" (no mixing of the voltages)
    c_mask = cell(1, n_t);
    for k = 1:n_t
        sct_m = struct("A", false(0), "B", false(0), "C", false(0), "D", false(0), "E", false(0), ...
            "StateName", strings(0, 1), "InputName", strings(0, 1), "OutputName", strings(0, 1));
        S = c_part{k};
        if isfield(S, "sv_selected") && obj.output.sv_issue(k) ~= "NotFinite"
            sct_v = section_model(obj, S, obj.output.sv_issue(k), obj.output.sv_message(k), "DAE", ...
                setfield(setfield(c_nv, "Port", s_port), "Form", "descriptor")); %#ok<SFLD>
            sct_m = section_model(obj, S, obj.output.sv_issue(k), obj.output.sv_message(k), "DAE", ...
                setfield(setfield(c_nv, "Port", "I"), "Form", "descriptor")); %#ok<SFLD>
            for s = ["A","B","C","D","E"]
                sct_m.(s) = sct_m.(s) ~= 0;
            end
            if l_net && s_port ~= "I"
                % the polar bus variables mix Vre and Vim of the same bus: theta_i with rho_i
                n_x = size(S.A, 1) - S.n_v;
                n_b = S.n_v/2;
                sct_m.A = pair(pair(sct_m.A, n_x, n_b, 1), n_x, n_b, 2);
                sct_m.B = pair(sct_m.B, n_x, n_b, 1);
                sct_m.C = pair(sct_m.C, n_x, n_b, 2);
            end
            for s = ["StateName","InputName","OutputName"]
                sct_m.(s) = sct_v.(s);
            end
        end
        c_mask{k} = sct_m;
    end
    sct_mask = [c_mask{:}];
end


function M = pair(M, n_x, n_b, i_dim)
% Marks theta_i and rho_i (positions n_x+i and n_x+n_b+i) together along dimension i_dim
    if n_b == 0
        return
    end
    i1 = n_x + (1:n_b);
    i2 = n_x + n_b + (1:n_b);
    if i_dim == 1
        m = M(i1,:) | M(i2,:);
        M(i1,:) = m;  M(i2,:) = m;
    else
        m = M(:,i1) | M(:,i2);
        M(:,i1) = m;  M(:,i2) = m;
    end
end
