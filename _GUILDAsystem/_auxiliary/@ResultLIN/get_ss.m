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
%   (E is zero on their rows and columns), in the bus variables given by Coordinate, and
%   their equations are the current balance of each bus. Outputs: the dynamic states.
% - "ODE": the DAE with the bus voltages eliminated (SolverLIN.reduce). States: the
%   dynamic states. Inputs: the inputs u. Outputs: the states, in their order, without
%   output names. Coordinate does not apply.
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
% port model (voltages in, currents and outputs out); Input and Output take names of its
% inputs and outputs, and Type and Coordinate do not apply.
%
% A result with flag false (output.s_issue) stops with an error that repeats output.message:
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
% ```
%
% See also PowerSystemModel.get_sys, SolverLIN.reduce, ResultLIN.Type, ResultLIN.plot_eigenvalue
    arguments (Input)
        obj
        Type (1,1) string {mustBeMember(Type, ["ODE","DAE"])} = default_type(obj) % Model: "ODE" (the bus voltages eliminated) or "DAE" (the connected model). Default: the Type of the result.
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
        S = obj.sct_model.sct_sys;   % a port model has no algebraic variables
        sys = model(S.A, S.B, S.C, S.D, S.E, S.StateName, S.InputName, S.OutputName);
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
    elseif obj.output.s_issue == "SingularAvv" && Type ~= "DAE"
        error(msg("GUILDA:ResultLIN:SingularAvv", obj.output.message, Type))
    end
    % The DAE; "ODE" eliminates its voltages, which do not need the polar coordinates
    s_coordinate = opt.Coordinate;
    if Type == "ODE"
        s_coordinate = "Vre&Vim";
    end
    sys = via_dae(obj, s_coordinate);
    if isfield(opt, "Output")
        sys = select_output(obj, sys, s_coordinate, opt.Output);
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


function str = default_type(obj)
    str = "ODE";
    if isfield(obj.options, "Type")
        str = obj.options.Type;
    end
end

function str = default_coordinate(obj)
    str = "theta&rho";
    if isfield(obj.options, "Coordinate")
        str = obj.options.Coordinate;
    end
end

function [p, sv_x, sv_u] = legacy_order(obj)
% State order of ODE and DAE: global controllers first, then the components
    tab   = obj.tab_variable;
    tab_x = tab(tab.Kind == "x", :);
    p     = [find(tab_x.Bus == ""); find(tab_x.Bus ~= "")];
    sv_x  = tab_x.Label(p);
    sv_u  = tab.Label(tab.Kind == "u");
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


function sys = select_output(obj, sys, s_coordinate, sv_select)
% Replaces the outputs of the DAE by the selected ones: y = Cx x + Cv v + Du u of the
% connected model, written with the states and inputs of the DAE
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

    [~, filt_i] = coordinate_filter(obj.sct_model.cv_V, s_coordinate);
    p = legacy_order(obj);
    C = [Cx(:,p), Cv(:,[1:2:n_v, 2:2:n_v]) * filt_i];
    D = Du;
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
