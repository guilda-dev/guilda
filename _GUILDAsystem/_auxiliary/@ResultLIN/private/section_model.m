function sys = section_model(obj, S, s_issue, s_message, Type, opt)
% Model of one section as a struct: the connected model S (a section of c_section, or the
% part of elements in it, contribution_part) written as get_ss writes it (Type, Port, Form,
% Input, Output of opt). get_ss, get_contribution and plot_contribution use it, so that a
% part of a section is written without a ResultLIN of its own.
%
% A part (S with the field sv_selected) keeps of the outputs that are a state or a bus
% voltage (identity rows of the DAE, not terms of the elements) only those of its owners.
    arguments (Input)
        obj    ResultLIN            % The result (variable map, options, layer).
        S      struct               % Connected model of the section, or a part of it.
        s_issue (1,1) string        % Issue of the section ("", "NotFinite", "SingularAvv").
        s_message (1,1) string      % Message of the section.
        Type   (1,1) string         % "ODE" or "DAE".
        opt    struct               % Port, Form, and optionally Input and Output (as get_ss).
    end
    arguments (Output)
        sys struct                  % A, B, C, D, E, StateName, InputName, OutputName.
    end
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
    if isfield(S, "sv_selected")
        sys = owned_outputs(obj, sys, S.sv_selected);
    end
    if Type == "ODE"
        n_x = nnz(obj.tab_variable.Kind == "x");
        sys = SolverLIN.reduce(sys, n_x+1:numel(sys.StateName));
        if ~isfield(opt, "Output")
            sys.OutputName = strings(n_x,1);   % the states, without output names
        end
    end
end


function sys = owned_outputs(obj, sys, sv_selected)
% The outputs of a part that are a state or a bus voltage: identity rows of the DAE,
% kept only for the states and buses that the part owns
    arguments (Input)
        obj ResultLIN                % The result.
        sys struct                   % Model of the part.
        sv_selected (:,1) string     % Owners of the part.
    end
    arguments (Output)
        sys struct                   % The model with the rows of the other owners zero.
    end
    tab = obj.tab_variable;
    lv_xv = tab.Kind == "x" | tab.Kind == "Vre" | tab.Kind == "Vim";
    [lv_id, iv_id] = ismember(sys.OutputName, tab.Label(lv_xv));
    sv_own = tab.Owner(lv_xv);
    lv_other = lv_id;
    lv_other(lv_id) = ~ismember(sv_own(iv_id(lv_id)), sv_selected);
    sys.C(lv_other, :) = 0;
    sys.D(lv_other, :) = 0;
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
