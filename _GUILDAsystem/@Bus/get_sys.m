function [sys, varargout] = get_sys(obj, opt)
% Linearize the bus with its components (V to I, or I to V).
%
% Linear model of the bus: its components (with their local controllers) connected at
% the bus.
%
% - inputs: the port (bus voltage [Vre; Vim] for port "V2I", the current [Ire; Iim]
%   injected by the components for "I2V"), then the inputs of each component and of its
%   controllers (as Component.get_sys)
% - states: the states of the components and their controllers
% - outputs: the other port, then the outputs of each component and of its controllers
%
% Port "I2V" stops with the error GUILDA:Bus:NoI2V when D of the "V2I" model is singular.
% The states are not outputs, so that every name is unique (see Component.get_sys).
% Point gives the point of the linearization in the same form as net.linearize: [] for
% the equilibrium, a vector in the order of bus.get_variable_map(), or {sim, t}.
% The model is not changed.
%
% Format chooses the form of the model: "GUILDAorigin" (default) returns a ResultLIN whose
% properties A, B, C, D, E, StateName, InputName and OutputName hold the model
% (E dx/dt = A x + B u, y = C x + D u), with tab_variable (bus.get_variable_map()),
% rv_point and the Jacobian blocks rm_Axx, rm_Axv, rm_Bx (the inputs of the components)
% and rm_E in the order of tab_variable for port "V2I" (rm_E only for "I2V"); "struct"
% returns a struct with the same eight fields; "ss" returns a descriptor state-space model
% (dss) and needs the Control System Toolbox.
%
% Without Point, a bus on a network stops with the error GUILDA:Bus:Stale when
% net.initialize() is needed (a stale tag of the network or of its components).
%
% See also Component.get_sys, Bus.get_variable_map, PowerNetwork.get_sys
%
% <@Group> Called by analyses
    arguments (Input)
        obj
        opt.port (1,1) {mustBeMember(opt.port, ["V2I", "I2V"])} = "V2I"   % Input and output ports.
        opt.full (1,1) logical = false     % Ignored; kept for old calls (the states are not outputs).
        opt.con  (1,1) logical = false     % Ignored; kept for old calls.
        opt.Point = []   % Point of the linearization: [] (the equilibrium), a vector in the order of bus.get_variable_map(), or {sim, t}.
        opt.Format (1,1) string {mustBeMember(opt.Format, ["GUILDAorigin","struct","ss"])} = "GUILDAorigin"   % Form of the model: GUILDAorigin (a ResultLIN), struct or ss (dss; needs the Control System Toolbox).
    end
    arguments (Output)
        sys   % Linear model in the form of Format, with state, input and output names.
    end
    arguments (Output, Repeating)
        varargout   % StateName, InputName and OutputName (cellstr), kept as in Component.get_sys.
    end
    t0 = tic;

    l_equilibrium = isempty(opt.Point) && ~iscell(opt.Point);
    if l_equilibrium && ~isempty(obj.a_PowerNetwork)
        % stale tags of the network and the components (Component.get_sys checks their controllers)
        net = obj.a_PowerNetwork;
        if ~isempty(net.sct_stale.input)   % edited inputs: initialize(Method="FixedInput")
            sv_in = unique(net.sct_stale.input, "stable");
            error(msg("GUILDA:Bus:InputEdited", char(net.s_tag), char(join(sv_in(1:min(end,3)), "; "))))
        end
        sv  = [net.sct_stale.powerflow; net.sct_stale.odefcn];
        for k = 1:numel(obj.a_Component)
            sv = [sv; obj.a_Component{k}.sct_stale.equilibrium; obj.a_Component{k}.sct_stale.odefcn]; %#ok<AGROW>
        end
        if ~isempty(sv)
            sv = unique(sv, "stable");
            s_reason = join(sv(1:min(end,3)), "; ");
            if numel(sv) > 3
                s_reason = s_reason + "; ...";
            end
            error(msg("GUILDA:Bus:Stale", char(obj.s_tag), char(s_reason)))
        end
    end

    rv_point = zeros(0,1);     % the equilibrium is read only for a ResultLIN
    if l_equilibrium
        sys = tools.cellfun(@(c) c.get_sys("port", "V2I", "Format", "struct"), obj.a_Component);
    else
        rv_point   = SolverLIN.point_vector(obj, opt.Point);
        [~, c_idx] = obj.get_variable_map();
        sys = cell(size(obj.a_Component));
        for j = 1:numel(obj.a_Component)
            iv_j = c_idx{j}(c_idx{j} <= numel(rv_point));   % its rows x, Vre, Vim, u
            sys{j} = obj.a_Component{j}.get_sys("port", "V2I", "Point", rv_point(iv_j), "Format", "struct");
        end
    end
    if isempty(sys)     % no components: no states, and the bus takes no current (I = 0)
        sys = {struct("A", zeros(0), "B", zeros(0,2), "C", zeros(2,0), "D", zeros(2), "E", zeros(0), ...
                      "StateName", strings(0,1), "InputName", ["Vre";"Vim"], "OutputName", ["Ire";"Iim"])};
    end

    % Each component model: inputs [V; u], outputs [I; y]
    Ax  = tools.cellfun(@(ss) ss.A                 , sys);
    Bv  = tools.cellfun(@(ss) ss.B(:,1:2)          , sys);
    Bu  = tools.cellfun(@(ss) ss.B(:,3:end)        , sys);
    Cx  = tools.cellfun(@(ss) ss.C(1:2,:)          , sys);
    Dv  = tools.cellfun(@(ss) ss.D(1:2,1:2)        , sys);    
    Du  = tools.cellfun(@(ss) ss.D(1:2,3:end)      , sys);    
    Cy  = tools.cellfun(@(ss) ss.C(3:end,:)        , sys);
    Dyv = tools.cellfun(@(ss) ss.D(3:end,1:2)      , sys);    
    Dyu = tools.cellfun(@(ss) ss.D(3:end,3:end)    , sys);    

    E = tools.cellfun(@(ss) ss.E, sys);

    StateNames  = tools.cellfun(@(ss) string(ss.StateName)        , sys);
    InputNames  = tools.cellfun(@(ss) string(ss.InputName(3:end))  , sys);
    OutputNames = tools.cellfun(@(ss) string(ss.OutputName(3:end)) , sys);

    Vport = arrayfun(@(str) obj.attach_tag(str), ["Vre";"Vim"]);
    Iport = arrayfun(@(str) obj.attach_tag(str), ["Ire";"Iim"]);

    Bv_all  = vertcat(Bv{:});
    Bu_all  = blkdiag(Bu{:});
    Cx_all  = horzcat(Cx{:});
    Dv_sum  = sum( cat(3,Dv{:}),3 );
    Du_all  = horzcat(Du{:});
    Cy_all  = blkdiag(Cy{:});
    Dyv_all = vertcat(Dyv{:});
    Dyu_all = blkdiag(Dyu{:});
    
    switch opt.port
        case "V2I"
            A =  blkdiag(Ax{:});            
            B = [Bv_all, Bu_all];
            C = [Cx_all; Cy_all];
            D = [Dv_sum, Du_all; Dyv_all, Dyu_all];

            InputNames  = [Vport; vertcat(strings(0,1), InputNames{:})];
            OutputNames = [Iport; vertcat(strings(0,1), OutputNames{:})];

        case "I2V"
            % A bus without components or with P = Q = 0 loads has no I-to-V form
            if ~(rcond(Dv_sum) > 1e-12)
                error(msg("GUILDA:Bus:NoI2V", obj.s_tag))
            end

            % V = inv_Dv (I - Cx x - Du u)
            inv_Dv = Dv_sum^-1;
            A = blkdiag(Ax{:}) - Bv_all * inv_Dv * Cx_all;                       
            B = [Bv_all * inv_Dv, Bu_all - Bv_all * inv_Dv * Du_all];            
            C = [-inv_Dv * Cx_all; Cy_all - Dyv_all * inv_Dv * Cx_all];
            D = [inv_Dv, -inv_Dv * Du_all; Dyv_all * inv_Dv, Dyu_all - Dyv_all * inv_Dv * Du_all];

            InputNames  = [Iport; vertcat(strings(0,1), InputNames{:})];
            OutputNames = [Vport; vertcat(strings(0,1), OutputNames{:})];
    end    

    sys = struct("A", A, "B", B, "C", C, "D", D, "E", blkdiag(E{:}), ...
                 "StateName", vertcat(strings(0,1), StateNames{:}), ...
                 "InputName", InputNames, "OutputName", OutputNames);

    varargout{1} = cellstr(sys.StateName);
    varargout{2} = cellstr(sys.InputName);
    varargout{3} = cellstr(sys.OutputName);

    if opt.Format ~= "struct"
        sys = object_result(obj, sys, opt, rv_point, l_equilibrium, t0);
        if opt.Format == "ss"
            sys = sys.get_ss(Format="ss");
        end
    end
end


function result = object_result(obj, sct_sys, opt, rv_point, l_eq, t0)
% ResultLIN holding the port model, the variable map and the Jacobian blocks
    tab = obj.get_variable_map();
    tab = tab(ismember(tab.Kind, ["x","Vre","Vim","u"]), :);    % the variables of the linearization
    if l_eq
        rv_point = SolverLIN.point_vector(obj, []);
    end
    sct_block = struct("E", sct_sys.E);
    if opt.port == "V2I"
        [~, iv_u] = ismember(tab.Label(tab.Kind == "u"), sct_sys.InputName);
        sct_block.Axx = sct_sys.A;
        sct_block.Axv = sct_sys.B(:,1:2);
        sct_block.Bx  = sct_sys.B(:,iv_u);
    end
    sct_output = struct("message", "Linearized the bus " + obj.s_tag + " at the equilibrium.", ...
                        "s_issue", "", "l_equilibrium", l_eq, "s_layer", "Bus");
    if ~l_eq
        sct_output.message = "Linearized the bus " + obj.s_tag + " at the given point.";
    end
    result = ResultLIN(obj.a_PowerNetwork, "", struct("Port", opt.port, "Point", {opt.Point}), true, sct_output, t0, ...
                       tab, rv_point, sct_block, struct("sct_sys", sct_sys));
end
