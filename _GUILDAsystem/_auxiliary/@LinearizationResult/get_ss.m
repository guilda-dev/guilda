function sys = get_ss(obj, Algorithm, opt)
% <@Desc>
% Reduced linear model of the result, as a descriptor state-space model (dss:
% E dx/dt = A x + B u, y = C x + D u). The matrices are the same as those of net.get_sys
% in v3 for each algorithm, including the state order: "Kron" and "DAE" put the states of
% the global controllers first, then the components; "Feedback" puts the components first,
% then the global controllers (in the order they were added). Use StateName to find a state.
%   "Kron"     : the bus voltages are eliminated from the DAE. States: all states.
%                Inputs: the inputs u. Outputs: the states.
%   "Feedback" : the bus models in I-to-V form are connected through the admittance
%                matrix (non-unit buses, options.NonUnit, are eliminated with the network
%                and their components left out), then the global controllers are closed.
%                Inputs: the inputs u. Outputs: the states.
%   "DAE"      : the bus voltages are kept as algebraic states (E is singular), in the
%                coordinates given by Coordinate. Outputs: the dynamic states.
% <@Role> Static Analysis
% <@Summary> Reduced state-space model (Kron / Feedback / DAE).
% <@Signatures>
% [
%   "sys = result.get_ss()",
%   "sys = result.get_ss(Algorithm)",
%   "sys = result.get_ss(\"DAE\", Coordinate=\"Vre&Vim\")"
% ]
% <@Parameters>
% [
%   {"Name": "Algorithm", "Type": "\"Kron\" | \"Feedback\" | \"DAE\"", "Description": "Reduction.", "Required": false, "Default": "result.options.Algorithm"},
%   {"Name": "Coordinate", "Type": "\"theta&rho\" | \"theta&V\" | \"Vre&Vim\"", "Description": "Bus variables of \"DAE\": angle and log magnitude (rho), angle and magnitude, or real and imaginary parts.", "Required": false, "Default": "\"theta&rho\""}
% ]
% <@Returns>
% [
%   {"Name": "sys", "Type": "ss", "Description": "Descriptor state-space model with StateName, InputName and OutputName."}
% ]
% <@Examples>
% [
%   "```matlab\nres = net.linearize();\nsysK = res.get_ss(\"Kron\");\nsysD = res.get_ss(\"DAE\");\neig(sysK.A, sysK.E)\n```"
% ]
    arguments
        obj
        Algorithm (1,1) string {mustBeMember(Algorithm, ["Kron","Feedback","DAE"])} = default_algorithm(obj)
        opt.Coordinate (1,1) string {mustBeMember(opt.Coordinate, ["theta&V","theta&rho","Vre&Vim"])} = "theta&rho"
    end
    switch Algorithm
        case "Kron"
            sys = via_kron(obj);
        case "Feedback"
            sys = via_feedback(obj);
        case "DAE"
            sys = via_dae(obj, opt.Coordinate);
    end
end


function str = default_algorithm(obj)
    str = "Feedback";
    if isfield(obj.options, "Algorithm")
        str = obj.options.Algorithm;
    end
end

function [p, str_x, str_u] = legacy_order(obj)
% State order of Kron and DAE: global controllers first, then the components
% (Feedback appends the global controllers after the components, as in v3)
    tab   = obj.tab_variable;
    tab_x = tab(tab.Kind == "x", :);
    p     = [find(tab_x.Bus == ""); find(tab_x.Bus ~= "")];
    str_x = tab_x.Label(p);
    str_u = tab.Label(tab.Kind == "u");
end


function sys = via_kron(obj)
    [p, str_x, str_u] = legacy_order(obj);

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

    sys = dss(Ax_ode, Bx_ode, Cx_ode, Dx_ode, E_ode);
    sys.InputName  = str_u;
    sys.StateName  = str_x;
    sys.OutputName = string.empty(0,1);
end


function sys = via_dae(obj, opt)
    [p, str_x, input] = legacy_order(obj);
    output = str_x;

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

    Vc_st = obj.s_model.cv_V;

    rm_Vr = diag(real(Vc_st));
    rm_Vi = diag(imag(Vc_st));
    rm_V  = diag(abs( Vc_st));

    switch opt
        case "theta&V"
            filt_o = [-    rm_Vi,       rm_Vr ;
                       rm_V\rm_Vr, rm_V\rm_Vi];
            filt_i = [-    rm_Vi,  rm_V\rm_Vr ;
                           rm_Vr,  rm_V\rm_Vi];
            str_busvar = ["theta";"V"];
        case "theta&rho"
            filt_o = [-rm_Vi,  rm_Vr ;
                       rm_Vr,  rm_Vi];
            filt_i = [-rm_Vi,  rm_Vr ;
                       rm_Vr,  rm_Vi];
            str_busvar = ["theta";"rho"];
        case "Vre&Vim"
            filt_o = eye(n_v);
            filt_i = eye(n_v);
            str_busvar = ["Vre";"Vim"];
    end
    A_dae = blkdiag(eye(n_x),filt_o)      ...
            * A_dae                       ...
            * blkdiag(eye(n_x),filt_i);
    B_dae = blkdiag(eye(n_x),filt_o)      ...
            * B_dae;

    str_busvar = reshape(str_busvar+(1:n_b),2,[]);
    str_busvar = reshape(str_busvar',1,[]);

    sys = dss(A_dae, B_dae, C_dae, D_dae, E_dae);
    sys.InputName  = input;
    sys.StateName  = [output(:)',str_busvar];
    sys.OutputName = output;
end


function sys = via_feedback(obj)
    s     = obj.s_model;
    n_bus = numel(s.c_sysBus);

    % A bus without states whose current does not depend on V in an invertible way (e.g. a load
    % with P = Q = 0) has no I-to-V form, so it is eliminated with the network like a non-unit bus
    l_isU = false(n_bus,1);
    for i = 1:n_bus
        l_isU(i) = ~s.lv_nonUnit(i) && has_I2V(s.c_sysBus{i});
    end

    ssFromBus = tools.cellfun(@i2v_full, s.c_sysBus(l_isU));
    ssG = blkdiag(ssFromBus{:});

    busInames = tools.cellfun(@(S) string(S.InputName(1:2)),  ssFromBus);
    busVnames = tools.cellfun(@(S) string(S.OutputName(end-1:end)), ssFromBus);

    input  = cellfun(@(c) string(c), ssG.InputName);
    output = cellfun(@(c) string(c), ssG.OutputName);

    lv_input  = ismember(input, vertcat(strings(0,1), busInames{:}));
    lv_output = ismember(output,vertcat(strings(0,1), busVnames{:}));

    Ymat = complex2matrix(s.cm_Y);
    ssN  = ss(Ymat);
    ssN.InputName  = vertcat(busVnames{:});
    ssN.OutputName = vertcat(busInames{:});

    sysODE = connect(ssG, ssN, input(~lv_input), output(~lv_output));

    % Global controllers (all of them, one after another, as in Kron and DAE):
    % their inputs are component outputs (e.g. omega) and their outputs add to component inputs (e.g. Pmech)
    for k = 1:numel(s.c_sysGC)
        sysGC = s.c_sysGC{k};
        [lv_out, feedout] = ismember(string(sysGC.InputName),  string(sysODE.OutputName));
        [lv_in,  feedin ] = ismember(string(sysGC.OutputName), string(sysODE.InputName));
        if ~all(lv_out) || ~all(lv_in)
            error("GUILDA:LinearizationResult:GlobalControllerPort", ...
                  "The ports of the global controller with states %s are not found in the linearized system.", ...
                  join(string(sysGC.StateName), ", "))
        end
        sysODE = feedback(sysODE, sysGC, feedin, feedout, +1);
    end
    sys = sysODE;

    function rm_Ymat = complex2matrix(Ymat)
        rm_Ymat = cell2mat( arrayfun(@(M) [real(M), -imag(M); imag(M), real(M)], Ymat, 'UniformOutput', false) );
        lv_Unit = logical( kron(l_isU,ones(2,1)) );
        rm_Ymat = rm_Ymat(lv_Unit,lv_Unit) - rm_Ymat(lv_Unit,~lv_Unit) * rm_Ymat(~lv_Unit,~lv_Unit)^-1 * rm_Ymat(~lv_Unit,lv_Unit);
    end
end

function tf = has_I2V(sys)
    tf = ~isempty(sys.A) || rcond(sys.D(:,1:2)) > 1e-12;
end

function sys = i2v_full(sysV2I)
% I-to-V form of a bus model (Bus.get_sys("port","I2V","full",true)) from its V-to-I
% form (Bus.get_sys("port","V2I","full",false)), with the same operations as Bus.get_sys
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

    sys = dss(A,B,C,D,sysV2I.E);
    sys.StateName  = sysV2I.StateName;
    sys.InputName  = [sysV2I.OutputName; sysV2I.InputName(3:end)];
    sys.OutputName = [sysV2I.StateName; sysV2I.InputName(1:2)];
end
