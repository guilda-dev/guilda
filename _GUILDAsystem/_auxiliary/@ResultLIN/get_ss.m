function sys = get_ss(obj, Method, opt)
% Get a reduced linear model (Kron / DAE).
%
% Returns the linear model of the result (E dx/dt = A x + B u, y = C x + D u). Format
% chooses its form: "ss" (default) is a descriptor state-space model (dss) with
% StateName, InputName and OutputName and needs the Control System Toolbox; "struct" is
% a struct with the fields A, B, C, D, E, StateName, InputName, OutputName (string
% columns) and needs no toolbox. For the network, "Kron" and "DAE" put the states of the
% global controllers first, then the components (as in v3). Use StateName to find a state.
%
% - "Kron": the bus voltages are eliminated from the DAE. States: all states.
%   Inputs: the inputs u. Outputs: the states, in their order, without output names.
% - "DAE": not reduced: the bus voltages are kept as algebraic states (E is singular), in
%   the coordinates given by Coordinate. Outputs: the dynamic states.
%
% Input and Output select the channels of the model; without them the channels are the
% ones above. The states and their order do not change. Output takes these kinds and
% names, in any mix, and the outputs follow the given order (a repeated one is kept once):
%
% - "x": all states of the model, in the order of sys.StateName (for "DAE", the dynamic
%   states).
% - "V": the bus voltages Vre, Vim of each bus (also in "DAE", whatever the Coordinate).
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
% port model (the bus voltage of the port "I2V" eliminated as in "Kron"); Input and Output
% take names of its inputs and outputs, and Method and Coordinate do not apply.
%
% A result with flag false (output.s_issue) stops with an error that repeats output.message:
% GUILDA:ResultLIN:NotFinite for every algorithm, and GUILDA:ResultLIN:SingularAvv
% for "Kron", which eliminates the bus voltages. "DAE" keeps them and still works.
%
% <@Examples>
% ```matlab
% res = net.get_sys();
% sysK = res.get_ss("Kron");                    % ss (Control System Toolbox)
% sysD = res.get_ss("DAE");
% eig(sysK.A, sysK.E)
% sysV = res.get_ss("Kron", Output="V");        % bus voltages as outputs
% sct  = res.get_ss("Kron", Format="struct");   % matrices and names, no toolbox
% ```
%
% See also PowerSystemModel.get_sys, ResultLIN.plot_eigenvalue
    arguments (Input)
        obj
        Method (1,1) string {mustBeMember(Method, ["Kron","DAE"])} = default_algorithm(obj) % Form of the model.
        opt.Coordinate (1,1) string {mustBeMember(opt.Coordinate, ["theta&V","theta&rho","Vre&Vim"])} = default_coordinate(obj) % Bus variables of "DAE": angle and log magnitude (rho), angle and magnitude, or real and imaginary parts. Default: options.Coordinate of the result.
        opt.Input (1,:) string % Inputs of the model: "u" or Labels. Default: all inputs.
        opt.Output (1,:) string % Outputs of the model: "x", "V", "I", "y" or names. Default: as described for each algorithm.
        opt.Format (1,1) string {mustBeMember(opt.Format, ["ss","struct"])} = "ss" % Form of the model: "ss" (dss; needs the Control System Toolbox) or "struct" (A, B, C, D, E and names).
    end
    arguments (Output)
        sys % Linear model in the form of Format, with StateName, InputName and OutputName.
    end
    if ~is_network(obj)
        % Object-level result: its port model
        if isfield(obj.output, "s_issue") && obj.output.s_issue == "NotFinite"
            error(msg("GUILDA:ResultLIN:NotFinite", obj.output.message))
        end
        sys = port_model(obj.sct_model.sct_sys);
        if isfield(opt, "Output")
            sys = output_by_name(sys, opt.Output);
        end
        if isfield(opt, "Input")
            sys = input_by_index(sys, input_index(sys, opt.Input));
        end
        sys = to_format(sys, opt.Format);
        return
    end
    if obj.output.s_issue == "NotFinite"
        error(msg("GUILDA:ResultLIN:NotFinite", obj.output.message))
    elseif obj.output.s_issue == "SingularAvv" && Method ~= "DAE"
        error(msg("GUILDA:ResultLIN:SingularAvv", obj.output.message, Method))
    end
    switch Method
        case "Kron"
            sys = via_kron(obj);
        case "DAE"
            sys = via_dae(obj, opt.Coordinate);
    end
    if isfield(opt, "Output")
        sys = select_output(obj, sys, Method, opt.Coordinate, opt.Output);
    end
    if isfield(opt, "Input")
        sys = input_by_index(sys, input_index(sys, opt.Input));
    end
    sys = to_format(sys, opt.Format);
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


function sys = output_by_name(sys, sv_select)
% Outputs of a port model by name, in the given order (a repeated one is kept once)
    sv_name = unique(reshape(sv_select, [], 1), "stable");
    [lv_known, iv] = ismember(sv_name, sys.OutputName);
    if ~all(lv_known)
        error(msg("GUILDA:ResultLIN:UnknownOutput", sv_name(find(~lv_known,1))))
    end
    sys.C = sys.C(iv, :);
    sys.D = sys.D(iv, :);
    sys.OutputName = sys.OutputName(iv);
end


function tf = is_network(obj)
    tf = isfield(obj.output, "s_layer") && obj.output.s_layer == "PowerNetwork";
end


function sys = port_model(S)
% The connected model of a layer without its algebraic variables (eliminated as in Kron)
    n_x = size(S.A,1) - S.n_v;
    ix = 1:n_x;
    iv = n_x+1:size(S.A,1);
    if S.n_v == 0
        sys = model(S.A, S.B, S.C, S.D, S.E, S.StateName, S.InputName, S.OutputName);
        return
    end
    Avv = S.A(iv,iv);
    Kx  = Avv \ S.A(iv,ix);
    Ku  = Avv \ S.B(iv,:);
    sys = model(S.A(ix,ix) - S.A(ix,iv)*Kx, S.B(ix,:) - S.A(ix,iv)*Ku, ...
                S.C(:,ix) - S.C(:,iv)*Kx, S.D - S.C(:,iv)*Ku, S.E(ix,ix), ...
                S.StateName(ix), S.InputName, S.OutputName);
end


function str = default_algorithm(obj)
    str = "Kron";
    if isfield(obj.options, "Method")
        str = obj.options.Method;
    end
end

function str = default_coordinate(obj)
    str = "theta&rho";
    if isfield(obj.options, "Coordinate")
        str = obj.options.Coordinate;
    end
end

function [p, sv_x, sv_u] = legacy_order(obj)
% State order of Kron and DAE: global controllers first, then the components (as in v3)
    tab   = obj.tab_variable;
    tab_x = tab(tab.Kind == "x", :);
    p     = [find(tab_x.Bus == ""); find(tab_x.Bus ~= "")];
    sv_x  = tab_x.Label(p);
    sv_u  = tab.Label(tab.Kind == "u");
end


function sys = via_kron(obj)
    [p, sv_x, sv_u] = legacy_order(obj);

    Ax_dae = obj.rm_Axx(p,p);
    Bv_dae = obj.rm_Axv(p,:);
    Bu_dae = obj.rm_Bx(p,:);
    Cx_dae = -obj.rm_Avx(:,p);
    Du_dae = -obj.rm_Bv;
    Dv_dae = -obj.rm_Avv;
    E_ode  = obj.rm_E(p,p);

    mat_v2x = Bv_dae / Dv_dae;

    n_x = size(Ax_dae,1);
    n_u = size(Bu_dae,2);

    Ax_ode = Ax_dae - mat_v2x * Cx_dae;
    Bx_ode = Bu_dae - mat_v2x * Du_dae;
    Cx_ode = eye(n_x);
    Dx_ode = zeros(n_x,n_u);

    sys = model(Ax_ode, Bx_ode, Cx_ode, Dx_ode, E_ode, sv_x, sv_u, strings(n_x,1));   % no output names
end


function sys = via_dae(obj, opt)
    [p, sv_x, input] = legacy_order(obj);
    output = sv_x;

    Axx  = obj.rm_Axx(p,p);
    Axv  = obj.rm_Axv(p,:);
    Avx  = obj.rm_Avx(:,p);
    Ex   = obj.rm_E(p,p);
    Ev   = zeros(size(obj.rm_Avv));

    n_x = size(Axx,1);
    n_v = size(obj.rm_Avv,1);
    n_b = n_v/2;
    n_u = size(obj.rm_Bx,2);

    A_temp = [Axx, Axv; Avx, obj.rm_Avv];
    B_temp = [obj.rm_Bx(p,:); obj.rm_Bv];

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

    [filt_o, filt_i, sr_busvar] = coordinate_filter(obj.sct_model.cv_V, opt);
    A_dae = blkdiag(eye(n_x),filt_o)      ...
            * A_dae                       ...
            * blkdiag(eye(n_x),filt_i);
    B_dae = blkdiag(eye(n_x),filt_o)      ...
            * B_dae;

    sr_busvar  = reshape(sr_busvar+(1:n_b),2,[]);
    sr_busvar  = reshape(sr_busvar',1,[]);

    sys = model(A_dae, B_dae, C_dae, D_dae, E_dae, [output(:); sr_busvar(:)], input, output);
end


function [filt_o, filt_i, sv_busvar] = coordinate_filter(Vc_st, s_coordinate)
% Change of the bus variables of "DAE": [Vre...; Vim...] = filt_i * (bus variables)
    n_v = 2*numel(Vc_st);

    rm_Vr = diag(real(Vc_st));
    rm_Vi = diag(imag(Vc_st));
    rm_V  = diag(abs( Vc_st));

    switch s_coordinate
        case "theta&V"
            filt_o = [-    rm_Vi,       rm_Vr ;
                       rm_V\rm_Vr, rm_V\rm_Vi];
            filt_i = [-    rm_Vi,  rm_V\rm_Vr ;
                           rm_Vr,  rm_V\rm_Vi];
            sv_busvar = ["theta";"V"];
        case "theta&rho"
            filt_o = [-rm_Vi,  rm_Vr ;
                       rm_Vr,  rm_Vi];
            filt_i = [-rm_Vi,  rm_Vr ;
                       rm_Vr,  rm_Vi];
            sv_busvar = ["theta";"rho"];
        case "Vre&Vim"
            filt_o = eye(n_v);
            filt_i = eye(n_v);
            sv_busvar = ["Vre";"Vim"];
    end
end


function sys = select_output(obj, sys, Method, s_coordinate, sv_select)
% Replaces the outputs of the model by the selected ones: y = Cx x + Cv v + Du u of the
% unreduced DAE, written with the states and inputs of the model
    tab  = obj.tab_variable;
    sv_x = tab.Label(tab.Kind == "x");
    sv_v = tab.Label(tab.Kind == "Vre" | tab.Kind == "Vim");
    sv_u = tab.Label(tab.Kind == "u");
    n_x  = numel(sv_x);
    n_v  = numel(sv_v);
    n_u  = numel(sv_u);
    S    = obj.sct_model.sct_sys;     % outputs y and yc over [x; v] and u
    sv_y = S.OutputName;
    sv_I = obj.sct_model.sv_I;

    % Every output, in the order of the kinds x, V, I, y
    c_kind = {["x";"V";"I";"y"], {sys.StateName(ismember(sys.StateName, sv_x)); sv_v; sv_I; sv_y}};
    sv_all = [sv_x; sv_v; sv_I; sv_y];
    Cx = [eye(n_x); zeros(2*n_v, n_x); S.C(:,1:n_x)];
    Cv = [zeros(n_x, n_v); eye(n_v); tools.complex2matrix(obj.sct_model.cm_Y); S.C(:,n_x+1:end)];
    Du = [zeros(n_x+2*n_v, n_u); S.D];

    sv_name = strings(0,1);
    for str = sv_select(:)'
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

    if Method == "DAE"
        [~, filt_i] = coordinate_filter(obj.sct_model.cv_V, s_coordinate);
        p = legacy_order(obj);
        C = [Cx(:,p), Cv(:,[1:2:n_v, 2:2:n_v]) * filt_i];
        D = Du;
    else
        % The voltages are eliminated
        [~, iv_x] = ismember(sys.StateName, sv_x);
        C = Cx(:,iv_x) - Cv * (obj.rm_Avv \ obj.rm_Avx(:,iv_x));
        D = Du - Cv * (obj.rm_Avv \ obj.rm_Bv);
    end
    [~, iv_u] = ismember(sys.InputName, sv_u);

    sys.C = C;
    sys.D = D(:,iv_u);
    sys.OutputName = sv_name;
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
