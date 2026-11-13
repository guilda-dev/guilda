function [sct_value, sct_mask] = get_contribution(obj, target)
% Get the part of elements in the matrices of the DAE.
%
% The DAE of the result (get_ss("DAE") with the Input, Output and Coordinate of get_sys)
% is the sum of the parts of its elements: the components, the local and global
% controllers, the branches and the buses. get_contribution returns the part of the
% elements in target, summed: sct_value has the fields A, B, C, D and E of the size of the
% DAE, with its StateName, InputName and OutputName, so that the parts of all the
% elements sum to the DAE. sct_mask has the same fields as logical matrices: true where
% the targets change the entry.
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
% stops with GUILDA:ResultLIN:UnknownTarget. The parts are in the Coordinate of the
% result; they are a deviation model like the DAE. The result of a component, bus or
% controller has no algebraic variables: the parts split its port model in the same way.
%
% <@Examples>
% ```matlab
% res = net.get_sys();
% sct = res.get_contribution("B001SG1");                  % one generator
% sct = res.get_contribution(["LocalController","Branch"]);   % all local controllers and branches
% [sct, msk] = res.get_contribution("controller.avr");
% spy(msk.A)                                             % the entries the AVRs change
% ```
%
% See also ResultLIN.get_ss, SolverLIN.solve, PowerSystemModel.get_sys
    arguments (Input)
        obj
        target (1,:) string {mustBeNonempty}   % Tags and class (or package) names of the elements; several are summed.
    end
    arguments (Output)
        sct_value struct   % Part of the targets: A, B, C, D, E (the size of the DAE), StateName, InputName, OutputName.
        sct_mask struct    % Entries the targets change: A, B, C, D, E (logical), StateName, InputName, OutputName.
    end
    if isfield(obj.output, "s_issue") && obj.output.s_issue == "NotFinite"
        error(msg("GUILDA:ResultLIN:NotFinite", obj.output.message))
    end
    S = obj.sct_model.sct_sys;
    T = S.sct_term;
    sv_sel = owners(S.tab_owner, target);
    lv_sel = ismember(T.sv_owner, sv_sel);

    c_nv = cell(1,0);
    for str = ["Input","Output"]
        if isfield(obj.options, str)
            c_nv = [c_nv, {str, obj.options.(str)}]; %#ok<AGROW>
        end
    end
    l_net = isfield(obj.output, "s_layer") && obj.output.s_layer == "PowerNetwork";
    s_coordinate = "Vre&Vim";
    if isfield(obj.options, "Coordinate")
        s_coordinate = obj.options.Coordinate;
    end

    % The part of the targets in the connected model, as a model of its own
    n_xv = size(S.A, 1);
    S_part = S;
    S_part.A = gather_terms(T.A, lv_sel, size(S.A));
    S_part.B = gather_terms(T.B, lv_sel, size(S.B));
    S_part.C = gather_terms(T.C, lv_sel, size(S.C));
    S_part.D = gather_terms(T.D, lv_sel, size(S.D));
    S_part.E = gather_terms(T.E, lv_sel, size(S.E));
    if isfield(S, "cm_Y")
        n_v = S.n_v;
        Yr = gather_terms(T.Y, lv_sel, [n_v, n_v]);
        S_part.cm_Y = Yr(1:2:end, 1:2:end) + 1j*Yr(2:2:end, 1:2:end);
    end
    sct_opt = obj.options;
    sct_opt.Type = "DAE";
    sct_out = obj.output;
    sct_out.s_issue = "";
    res_part = ResultLIN(obj.a_PowerNetwork, obj.s_solver, sct_opt, true, sct_out, NaN, obj.tab_variable, obj.rv_point, S_part);
    sct_value = res_part.get_ss("DAE", c_nv{:}, Format="struct");
    sct_mask  = res_part.get_ss("DAE", c_nv{:}, Coordinate="Vre&Vim", Format="struct");   % no mixing of the voltages
    for s = ["A","B","C","D","E"]
        sct_mask.(s) = sct_mask.(s) ~= 0;
    end

    if l_net
        % The outputs that are a state or a bus voltage belong to its owner (the DAE writes
        % them as identity rows, not from the terms)
        tab = obj.tab_variable;
        lv_xv = tab.Kind == "x" | tab.Kind == "Vre" | tab.Kind == "Vim";
        [lv_id, iv_id] = ismember(sct_value.OutputName, tab.Label(lv_xv));
        if any(lv_id)
            sv_own = tab.Owner(lv_xv);
            lv_mine = false(size(lv_id));
            lv_mine(lv_id) = ismember(sv_own(iv_id(lv_id)), sv_sel);
            sct_full  = obj.get_ss("DAE", c_nv{:}, Format="struct");
            fullR = obj.get_ss("DAE", c_nv{:}, Coordinate="Vre&Vim", Format="struct");
            sct_value.C(lv_id,:) = sct_full.C(lv_id,:) .* lv_mine(lv_id);
            sct_value.D(lv_id,:) = sct_full.D(lv_id,:) .* lv_mine(lv_id);
            sct_mask.C(lv_id,:)  = (fullR.C(lv_id,:) ~= 0) & lv_mine(lv_id);
            sct_mask.D(lv_id,:)  = (fullR.D(lv_id,:) ~= 0) & lv_mine(lv_id);
        end
        if s_coordinate ~= "Vre&Vim"
            % the polar bus variables mix Vre and Vim of the same bus: theta_i with rho_i
            n_x = n_xv - S.n_v;
            n_b = S.n_v/2;
            sct_mask.A = pair(pair(sct_mask.A, n_x, n_b, 1), n_x, n_b, 2);
            sct_mask.B = pair(sct_mask.B, n_x, n_b, 1);
            sct_mask.C = pair(sct_mask.C, n_x, n_b, 2);
        end
    end
    for s = ["StateName","InputName","OutputName"]
        sct_mask.(s) = sct_value.(s);
    end
end


function sv_sel = owners(tab_owner, target)
% Tags of the elements that the targets name: a tag, a class (with its subclasses) or a package
    lv_sel = false(height(tab_owner),1);
    sv_class = unique(tab_owner.Class);
    c_super = cell(size(sv_class));
    for k = 1:numel(sv_class)
        c_super{k} = [sv_class(k); reshape(string(superclasses(char(sv_class(k)))), [], 1)];
    end
    for t = target
        lv_t = tab_owner.Owner == t;
        if ~any(lv_t)
            lv_cls = cellfun(@(c) any(c == t) || any(startsWith(c, t + ".")), c_super);
            lv_t = ismember(tab_owner.Class, sv_class(lv_cls));
        end
        if ~any(lv_t)
            error(msg("GUILDA:ResultLIN:UnknownTarget", t))
        end
        lv_sel = lv_sel | lv_t;
    end
    sv_sel = tab_owner.Owner(lv_sel);
end


function M = gather_terms(rm_term, lv_owner, iv_size)
% Sum of the terms [Row, Column, Owner, Value] of the selected owners
    lv = lv_owner(rm_term(:,3));
    M = full(sparse(rm_term(lv,1), rm_term(lv,2), rm_term(lv,4), iv_size(1), iv_size(2)));
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
