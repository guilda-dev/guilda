function sys = get_ss(obj, Algorithm, opt)
% Get a reduced linear model (Kron / Feedback / DAE).
%
% Returns the linear model of the result (E dx/dt = A x + B u, y = C x + D u). Format
% chooses its form: "ss" (default) is a descriptor state-space model (dss) with
% StateName, InputName and OutputName and needs the Control System Toolbox; "struct" is
% a struct with the fields A, B, C, D, E, StateName, InputName, OutputName (string
% columns) and needs no toolbox. The matrices are the same as those of net.get_sys
% in v3 for each algorithm, including the state order: "Kron" and "DAE" put the states of
% the global controllers first, then the components; "Feedback" puts the components first,
% then the global controllers (in the order they were added). Use StateName to find a state.
% The exception is "Feedback" with a non-unit bus that has components: v3 dropped them, here
% they are absorbed into the admittance matrix, which can change the matrices and adds inputs.
%
% - "Kron": the bus voltages are eliminated from the DAE. States: all states.
%   Inputs: the inputs u. Outputs: the states, in their order, without output names.
% - "Feedback": the bus models in I-to-V form are connected through the admittance
%   matrix, then the global controllers are closed (positive feedback). Non-unit buses (buses without
%   components, and buses without states that have no I-to-V form) are detected automatically
%   and eliminated with the network: their linearized current is absorbed into the admittance
%   matrix and their inputs are kept, so the model is equivalent to "Kron". A network without
%   states has nothing to connect, which is an error (GUILDA:ResultLIN:NoUnitBus).
%   Inputs: the inputs u, in the same order as "Kron". States: the connection removes the
%   states that no input reaches through the nonzero pattern of the model (such as Vst of an
%   AVR without a PSS), so there can be fewer than in "Kron". Outputs: the
%   states of the components and local controllers, including a row for each removed state
%   and leaving out the states of the global controllers, so they differ from the states.
% - "DAE": not reduced: the bus voltages are kept as algebraic states (E is singular), in
%   the coordinates given by Coordinate. Outputs: the dynamic states.
%
% Input and Output select the channels of the model; without them the channels are the
% ones above. The states and their order do not change. Output takes these kinds and
% names, in any mix, and the outputs follow the given order (a repeated one is kept once):
%
% - "x": all states of the model, in the order of sys.StateName (for "DAE", the dynamic
%   states). "Feedback" has no state that its connection removes;
%   naming one stops with the error GUILDA:ResultLIN:StateNotInModel, and
%   "Kron" has them all. Its default outputs are not "x": they leave out the states of the
%   global controllers and keep a row for a removed state.
% - "V": the bus voltages Vre, Vim of each bus (also in "DAE", whatever the Coordinate).
% - "I": the currents Ire, Iim that the components inject at each bus (Y v).
% - "y": the outputs of the components and of their local controllers. An output with the
%   name of a state of its owner is "Y_" + name, as in Bus.get_sys.
% - a name: Label of net.get_variable_map() for x and V, or a name of the kinds "I" and "y"
%   as in the OutputName of the kinds above.
%
% Input takes "u" (all inputs) or Labels of the inputs, and the inputs follow the given
% order. An unknown name stops with GUILDA:ResultLIN:UnknownInput; an unknown Output name
% stops with GUILDA:ResultLIN:UnknownOutput.
%
% For an object-level result (comp.get_sys, bus.get_sys, con.get_sys, gc.get_sys), get_ss
% returns the port model held in the result; Input and Output take names of its inputs
% and outputs, and Algorithm and Coordinate do not apply.
%
% A result with flag false (output.s_issue) stops with an error that repeats output.message:
% GUILDA:ResultLIN:NotFinite for every algorithm, and GUILDA:ResultLIN:SingularAvv
% for "Kron" and "Feedback", which eliminate the bus voltages. "DAE" keeps them and still works.
%
% <@Examples>
% ```matlab
% res = net.linearize();
% sysK = res.get_ss("Kron");                    % ss (Control System Toolbox)
% sysD = res.get_ss("DAE");
% eig(sysK.A, sysK.E)
% sysV = res.get_ss("Kron", Output="V");        % bus voltages as outputs
% sct  = res.get_ss("Kron", Format="struct");   % matrices and names, no toolbox
% ```
%
% See also PowerNetwork.get_sys, ResultLIN.Plot
    arguments (Input)
        obj
        Algorithm (1,1) string {mustBeMember(Algorithm, ["Kron","Feedback","DAE"])} = default_algorithm(obj) % Form of the model.
        opt.Coordinate (1,1) string {mustBeMember(opt.Coordinate, ["theta&V","theta&rho","Vre&Vim"])} = default_coordinate(obj) % Bus variables of "DAE": angle and log magnitude (rho), angle and magnitude, or real and imaginary parts. Default: options.Coordinate of the result.
        opt.Input (1,:) string % Inputs of the model: "u" or Labels. Default: all inputs.
        opt.Output (1,:) string % Outputs of the model: "x", "V", "I", "y" or names. Default: as described for each algorithm.
        opt.Format (1,1) string {mustBeMember(opt.Format, ["ss","struct"])} = "ss" % Form of the model: "ss" (dss; needs the Control System Toolbox) or "struct" (A, B, C, D, E and names).
    end
    arguments (Output)
        sys % Linear model in the form of Format, with StateName, InputName and OutputName.
    end
    if isfield(obj.sct_model, "sct_sys")
        % Object-level result: its port model
        sys = obj.sct_model.sct_sys;
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
    elseif obj.output.s_issue == "SingularAvv" && Algorithm ~= "DAE"
        error(msg("GUILDA:ResultLIN:SingularAvv", obj.output.message, Algorithm))
    end
    switch Algorithm
        case "Kron"
            sys = via_kron(obj);
        case "Feedback"
            sys = via_feedback(obj);
        case "DAE"
            sys = via_dae(obj, opt.Coordinate);
    end
    if isfield(opt, "Output")
        sys = select_output(obj, sys, Algorithm, opt.Coordinate, opt.Output);
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


function str = default_algorithm(obj)
    str = "Feedback";
    if isfield(obj.options, "Algorithm")
        str = obj.options.Algorithm;
    end
end

function str = default_coordinate(obj)
    str = "theta&rho";
    if isfield(obj.options, "Coordinate")
        str = obj.options.Coordinate;
    end
end

function [p, sv_x, sv_u] = legacy_order(obj)
% State order of Kron and DAE: global controllers first, then the components
% (Feedback appends the global controllers after the components, as in v3)
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


function sys = select_output(obj, sys, Algorithm, s_coordinate, sv_select)
% Replaces the outputs of the model by the selected ones: y = Cx x + Cv v + Du u of the
% unreduced DAE, written with the states and inputs of the model
    tab  = obj.tab_variable;
    sv_x = tab.Label(tab.Kind == "x");
    sv_v = tab.Label(tab.Kind == "Vre" | tab.Kind == "Vim");
    sv_u = tab.Label(tab.Kind == "u");
    n_x  = numel(sv_x);
    n_v  = numel(sv_v);
    n_u  = numel(sv_u);
    sct_y = obj.sct_model.sct_output;
    sv_model = sys.StateName;
    sv_model = sv_model(ismember(sv_model, sv_x));

    % Every output, in the order of the kinds x, V, I, y
    c_kind = {["x";"V";"I";"y"], {sv_model; sv_v; obj.sct_model.sv_I; sct_y.sv_name}};
    sv_all = [sv_x; sv_v; obj.sct_model.sv_I; sct_y.sv_name];
    Cx = [eye(n_x); zeros(2*n_v, n_x); sct_y.Cx];
    Cv = [zeros(n_x, n_v); eye(n_v); tools.complex2matrix(obj.sct_model.cm_Y); sct_y.Cv];
    Du = [zeros(n_x+2*n_v, n_u); sct_y.Du];

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
    lv_missing = ismember(sv_name, sv_x) & ~ismember(sv_name, sv_model);
    if any(lv_missing)
        error(msg("GUILDA:ResultLIN:StateNotInModel", sv_name(find(lv_missing,1)), Algorithm))
    end
    Cx = Cx(iv_all,:);
    Cv = Cv(iv_all,:);
    Du = Du(iv_all,:);

    if Algorithm == "DAE"
        [~, filt_i] = coordinate_filter(obj.sct_model.cv_V, s_coordinate);
        p = legacy_order(obj);
        C = [Cx(:,p), Cv(:,[1:2:n_v, 2:2:n_v]) * filt_i];
        D = Du;
    else
        % The voltages are eliminated; "Feedback" has the same states, except those it removes
        [~, iv_x] = ismember(sv_model, sv_x);
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


function sys = via_feedback(obj)
    s     = obj.sct_model;
    n_bus = numel(s.c_sysBus);

    v3_nonunit_dynamic(obj.options, s.c_sysBus);    % COMPAT(v3)
    if all(tools.vcellfun(@(S) isempty(S.A), s.c_sysBus))
        error(msg("GUILDA:ResultLIN:NoUnitBus"))
    end

    lv_noI2V = tools.vcellfun(@(S) ~isempty(S.A) && ~is_invertible(S.D(:,1:2)), s.c_sysBus);
    if any(lv_noI2V)
        error(msg("GUILDA:ResultLIN:NoI2V", num2str(find(lv_noI2V(:)'))))
    end

    % A bus without states whose current does not depend on V in an invertible way (e.g. a load
    % with P = Q = 0) has no I-to-V form, so it is eliminated with the network like a non-unit bus
    l_isU = false(n_bus,1);
    for i = 1:n_bus
        l_isU(i) = ~s.lv_nonUnit(i) && has_I2V(s.c_sysBus{i});
    end

    ssFromBus = tools.cellfun(@i2v_full, s.c_sysBus(l_isU));

    busInames = tools.cellfun(@(S) S.InputName(1:2),  ssFromBus);
    busVnames = tools.cellfun(@(S) S.OutputName(end-1:end), ssFromBus);

    input  = obj.tab_variable.Label(obj.tab_variable.Kind == "u");

    % Non-unit buses n have no states, so Div_n V_n + Diu_n u_n is their current and
    % I_u = (Y_uu - Y_un Ybar_nn^-1 Y_nu) V_u + Y_un Ybar_nn^-1 Diu_n u_n, with Ybar_nn = Y_nn - Div_n
    sysNon = s.c_sysBus(~l_isU);
    Div = tools.dcellfun(@(S) S.D(:,1:2)  , sysNon);
    Diu = tools.dcellfun(@(S) S.D(:,3:end), sysNon);
    nonUnames = tools.cellfun(@(S) S.InputName(3:end), sysNon);

    [Ymat, Hmat] = complex2matrix(s.cm_Y, Div, Diu);
    ssN = model(zeros(0), zeros(0,size(Ymat,2)+size(Hmat,2)), zeros(size(Ymat,1),0), [Ymat, Hmat], zeros(0), ...
                strings(0,1), [vertcat(busVnames{:}); vertcat(strings(0,1), nonUnames{:})], vertcat(busInames{:}));

    % The bus models and the network connected by name; outputs: the states of the bus models
    sv_x   = tools.cellfun(@(S) S.StateName, ssFromBus);
    sysODE = connect_by_name([ssFromBus(:); {ssN}], input, vertcat(strings(0,1), sv_x{:}));
    sysODE = remove_unreachable_states(sysODE);

    % Global controllers (all of them, one after another, as in Kron and DAE):
    % their inputs are component outputs (e.g. omega) and their outputs add to component inputs (e.g. Pmech)
    for k = 1:numel(s.c_sysGC)
        sysGC = s.c_sysGC{k};
        [lv_out, feedout] = ismember(sysGC.InputName,  sysODE.OutputName);
        [lv_in,  feedin ] = ismember(sysGC.OutputName, sysODE.InputName);
        if ~all(lv_out) || ~all(lv_in)
            error(msg("GUILDA:ResultLIN:GlobalControllerPort", join(sysGC.StateName, ", ")))
        end
        sysODE = positive_feedback(sysODE, sysGC, feedin, feedout);
    end
    sys = sysODE;

    function [rm_Ymat, rm_Hmat] = complex2matrix(Ymat, Div, Diu)
        rm_Ymat = cell2mat( arrayfun(@(M) [real(M), -imag(M); imag(M), real(M)], Ymat, 'UniformOutput', false) );
        lv_Unit = logical( kron(l_isU,ones(2,1)) );
        inv_Ynn = (rm_Ymat(~lv_Unit,~lv_Unit) - Div)^-1;
        rm_Hmat = rm_Ymat(lv_Unit,~lv_Unit) * inv_Ynn * Diu;
        rm_Ymat = rm_Ymat(lv_Unit,lv_Unit) - rm_Ymat(lv_Unit,~lv_Unit) * inv_Ynn * rm_Ymat(~lv_Unit,lv_Unit);
    end
end

function tf = has_I2V(sys)
    tf = ~isempty(sys.A) || is_invertible(sys.D(:,1:2));
end

function tf = is_invertible(D)
    tf = rcond(D) > 1e-12;
end

function sys = i2v_full(sysV2I)
% I-to-V form of a bus model (Bus.get_sys("port","I2V") with the states as outputs) from
% its V-to-I form, with the same operations as Bus.get_sys
    Ax = sysV2I.A;
    Bv = sysV2I.B(:,1:2);
    Bu = sysV2I.B(:,3:end);

    inv_Dv = sysV2I.D(:,1:2)^-1;
    inv_Cx = sysV2I.C;
    inv_Du = sysV2I.D(:,3:end);
    inv_Ax = Ax - Bv * inv_Dv * inv_Cx;
    inv_Bv = Bv * inv_Dv;
    inv_Bu = Bu - Bv * inv_Dv * inv_Du;

    A =  inv_Ax;
    B = [inv_Bv, inv_Bu];

    nx = size(A,1);
    nu = size(B,2);

    C  = [  eye(nx,nx); -inv_Dv*inv_Cx];
    D  = [zeros(nx,nu); [inv_Dv, -inv_Dv*inv_Du]];

    sys = model(A, B, C, D, sysV2I.E, sysV2I.StateName, ...
                [sysV2I.OutputName; sysV2I.InputName(3:end)], [sysV2I.StateName; sysV2I.InputName(1:2)]);
end

function sys = connect_by_name(c_blk, sv_input, sv_output)
% Connects the blocks by name, keeping the states in the order of the blocks: an input
% takes the sum of the outputs of the same name and the external input of the same name.
% sv_input and sv_output name the external inputs and the outputs.
    A = tools.cellfun(@(S) S.A, c_blk);  B = tools.cellfun(@(S) S.B, c_blk);
    C = tools.cellfun(@(S) S.C, c_blk);  D = tools.cellfun(@(S) S.D, c_blk);
    E = tools.cellfun(@(S) S.E, c_blk);
    A = blkdiag(A{:});  B = blkdiag(B{:});  C = blkdiag(C{:});  D = blkdiag(D{:});  E = blkdiag(E{:});
    sv_x   = tools.cellfun(@(S) S.StateName,  c_blk);   sv_x   = vertcat(strings(0,1), sv_x{:});
    sv_in  = tools.cellfun(@(S) S.InputName,  c_blk);   sv_in  = vertcat(strings(0,1), sv_in{:});
    sv_out = tools.cellfun(@(S) S.OutputName, c_blk);   sv_out = vertcat(strings(0,1), sv_out{:});

    K = double(sv_in == sv_out.');              % K(i,j) = 1: output j feeds input i
    P = double(sv_in == sv_input(:).');         % external inputs
    [~, iv_out] = ismember(sv_output, sv_out);

    % u = P w + K y,  y = C x + D u  =>  y = (I - D K) \ (C x + D P w)
    M  = eye(numel(sv_out)) - D*K;
    Cy = M \ C;
    Dy = M \ (D*P);
    sys = model(A + B*K*Cy, B*(P + K*Dy), Cy(iv_out,:), Dy(iv_out,:), E, sv_x, sv_input, sv_output);
end

function sys = remove_unreachable_states(sys)
% Structural reduction, as connect does: removes the states that no input reaches and the
% states that reach no output, through the nonzero pattern of A, E, B and C. The outputs do
% not change (a removed state stays at zero).
    G = (sys.A ~= 0) | (sys.E ~= 0);            % G(i,j): state j acts on state i
    lv_in = any(sys.B ~= 0, 2);
    lv_out = reshape(any(sys.C ~= 0, 1), [], 1);
    n_in = -1;   n_out = -1;
    while nnz(lv_in) ~= n_in || nnz(lv_out) ~= n_out
        n_in = nnz(lv_in);   n_out = nnz(lv_out);
        lv_in  = lv_in  | any(G(:, lv_in), 2);
        lv_out = lv_out | reshape(any(G(lv_out, :), 1), [], 1);
    end
    lv = lv_in & lv_out;
    sys.A = sys.A(lv,lv);
    sys.B = sys.B(lv,:);
    sys.C = sys.C(:,lv);
    sys.E = sys.E(lv,lv);
    sys.StateName = sys.StateName(lv);
end

function sys = positive_feedback(sys1, sys2, feedin, feedout)
% Positive feedback of sys2 around sys1: the inputs feedin of sys1 add the outputs of sys2,
% whose inputs are the outputs feedout of sys1. States [x1; x2]; inputs and outputs of sys1.
    n1 = size(sys1.A,1);   n2 = size(sys2.A,1);
    S = zeros(numel(feedout), numel(sys1.OutputName));
    S(sub2ind(size(S), 1:numel(feedout), reshape(feedout,1,[]))) = 1;     % w2 = S y1
    T = zeros(numel(sys1.InputName), numel(feedin));
    T(sub2ind(size(T), reshape(feedin,1,[]), 1:numel(feedin))) = 1;       % u1 = v + T z2

    % y1 = C1 x1 + D1 (v + T (C2 x2 + D2 S y1))
    M  = eye(numel(sys1.OutputName)) - sys1.D*T*sys2.D*S;
    Cy = M \ [sys1.C, sys1.D*T*sys2.C];
    Dy = M \ sys1.D;
    Cz = [zeros(size(sys2.C,1), n1), sys2.C] + sys2.D*S*Cy;           % z2
    Dz = sys2.D*S*Dy;

    A = [sys1.A, zeros(n1,n2); zeros(n2,n1), sys2.A] + [sys1.B*T*Cz; sys2.B*S*Cy];
    B = [sys1.B + sys1.B*T*Dz; sys2.B*S*Dy];
    sys = model(A, B, Cy, Dy, blkdiag(sys1.E, sys2.E), [sys1.StateName; sys2.StateName], ...
                sys1.InputName, sys1.OutputName);
end
