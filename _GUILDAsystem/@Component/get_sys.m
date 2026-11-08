function [sys, varargout] = get_sys(obj, x, V, I, u, opt)
% Linearize the component with its local controllers (V to I, or I to V).
%
% Linear model of the component with its local controllers.
%
% - inputs: the port (bus voltage [Vre; Vim] for port "V2I", current [Ire; Iim] for
%   "I2V"), the inputs u of the component, then the inputs of its controllers (depth
%   first)
% - states: the states of the component, then the states of its controllers
% - outputs: the other port (current for "V2I", voltage for "I2V"), the outputs of the
%   component, then the outputs of its controllers
%
% Port "I2V" stops with the error GUILDA:Component:NoI2V when D of the "V2I" model is
% singular.
%
% The states are not outputs, so that every name is unique: an output with the name
% of a state of its owner is labelled "Y_" + name (e.g. Y_omega_SG1B001_B001_PowerNetwork).
% An input of the component or of a controller that a controller also drives (e.g.
% Vfield under an AVR) adds to that signal. The signals from the component to its
% controllers (its outputs, its states read by name or "Xall", and the voltage) are
% connected inside.
%
% The point of the linearization is x, V, I, u (default: the equilibrium; the local
% controllers are then linearized at their equilibrium), or Point in the same form as
% net.linearize: a vector in the order of comp.get_variable_map() (states of the
% component and its controllers, Vre, Vim, inputs), or {sim, t}. With Point, I is
% fcn_I at the point and the inputs of the controllers are the outputs they are
% connected to (as in the simulation). The model is not changed.
%
% Format chooses the form of the model: "GUILDAorigin" (default) returns a ResultLIN whose
% properties A, B, C, D, E, StateName, InputName and OutputName hold the model
% (E dx/dt = A x + B u, y = C x + D u), with tab_variable (comp.get_variable_map()),
% rv_point and the Jacobian blocks rm_Axx, rm_Axv, rm_Bx (the inputs of the component)
% and rm_E in the order of tab_variable for port "V2I" (rm_E only for "I2V"); "struct"
% returns a struct with the same eight fields; "ss" returns a descriptor state-space model
% (dss) and needs the Control System Toolbox.
%
% Without Point, a component on a network stops with the error GUILDA:Component:Stale
% when net.initialize() is needed (a stale tag of the network, the component or its
% controllers); a component without a network builds its stale handles and those of its
% controllers first.
%
% See also Component.get_variable_map, Bus.get_sys, PowerNetwork.get_sys
%
% <@Group> Called by analyses
    arguments (Input)
        obj 
        x        (:,1) double = obj.rv_Xequilibrium   % States (default: the equilibrium).
        V        (:,1) double = [real(obj.c_Vequilibrium); imag(obj.c_Vequilibrium)]   % [pu] Bus voltage [Vre; Vim] (default: the equilibrium).
        I        (:,1) double = [real(obj.c_Iequilibrium); imag(obj.c_Iequilibrium)]   % [pu] Current [Ire; Iim] (default: the equilibrium).
        u        (:,1) double = obj.rv_Uequilibrium   % Inputs (default: the equilibrium).
        opt.port (1,1) {mustBeMember(opt.port, ["V2I", "I2V"])} = "V2I"   % Input and output ports.
        opt.full (1,1) logical = false     % Ignored; kept for old calls (the states are not outputs).
        opt.tag  (1,1) logical = true   % Name the states, inputs and outputs with the component tag.
        opt.con  (1,1) logical = false     % Ignored; kept for old calls (the local controllers are always included).
        opt.Point = []   % Point of the linearization; overrides x, V, I, u.
        opt.Format (1,1) string {mustBeMember(opt.Format, ["GUILDAorigin","struct","ss"])} = "GUILDAorigin"   % Form of the model: GUILDAorigin (a ResultLIN), struct or ss (dss; needs the Control System Toolbox).
    end
    arguments (Output)
        sys   % Linear model in the form of Format, with state, input and output names.
    end
    arguments (Output, Repeating)
        varargout   % StateName, InputName and OutputName (cellstr), kept for old calls.
    end
    t0 = tic;

    l_equilibrium = isempty(opt.Point) && ~iscell(opt.Point);

    % All controllers in the tree (e.g. PSS attached under AVR) are separate blocks connected by signal names
    a_LC = all_controllers(obj);

    if isempty(obj.a_Bus) || isempty(obj.a_Bus.a_PowerNetwork)
        build_stale(obj);    % no network to initialize: the handles are built here
    elseif l_equilibrium
        % stale tags of the network, the component and its controllers
        net = obj.a_Bus.a_PowerNetwork;
        sv  = [net.sct_stale.powerflow; net.sct_stale.odefcn; obj.sct_stale.equilibrium; obj.sct_stale.odefcn];
        for k = 1:numel(a_LC)
            sv = [sv; a_LC{k}.sct_stale.equilibrium; a_LC{k}.sct_stale.odefcn]; %#ok<AGROW>
        end
        if ~isempty(sv)
            sv = unique(sv, "stable");
            s_reason = join(sv(1:min(end,3)), "; ");
            if numel(sv) > 3
                s_reason = s_reason + "; ...";
            end
            error(msg("GUILDA:Component:Stale", char(obj.s_tag), char(s_reason)))
        end
    end
    if l_equilibrium
        sysCON = tools.cellfun(@(d) d.get_sys_alone("tag",false), a_LC);
        rv_point = [x; tools.vcellfun(@(d) reshape(d.rv_Xequilibrium, [], 1), a_LC); V; u];
    else
        rv_point = SolverLIN.point_vector(obj, opt.Point);
        [x, V, I, u, c_con] = point_values(obj, a_LC, rv_point);
        sysCON = tools.cellfun(@(d,p) d.get_sys_alone(p{:},"tag",false), a_LC, c_con);
    end

    % The component with the outputs and the voltage its controllers read
    SYS = obj.get_sys_alone(x,V,I,u,"port",opt.port,"controllerPorts",true);

    % Inputs of the controllers that read states of the component (iv_obsX) connect
    % to extra state outputs of SYS, named apart from the outputs of the same name
    [SYS, sysCON] = connect_states(SYS, sysCON, a_LC);

    % External inputs: the port and inputs of the component and the inputs of the
    % controllers (not their voltage); outputs: the port and outputs of the component
    % and the outputs of the controllers
    iv_in  = 1:numel(SYS.InputName);
    iv_out = 1:2+numel(obj.sv_y);
    n_in   = numel(SYS.InputName);
    n_out  = numel(SYS.OutputName);
    for k = 1:numel(sysCON)
        iv_in  = [iv_in,  n_in  + (3:numel(sysCON{k}.InputName))];   %#ok<AGROW>
        iv_out = [iv_out, n_out + (1:numel(sysCON{k}.OutputName))];  %#ok<AGROW>
        n_in   = n_in  + numel(sysCON{k}.InputName);
        n_out  = n_out + numel(sysCON{k}.OutputName);
    end

    % The controllers are connected to the component and to each other by name
    sys = connect_blocks([{SYS}; sysCON(:)], iv_in, iv_out);

    % Names
    if opt.port == "V2I"
        sv_portIn = ["Vre";"Vim"];  sv_portOut = ["Ire";"Iim"];
    else
        sv_portIn = ["Ire";"Iim"];  sv_portOut = ["Vre";"Vim"];
    end
    a_all  = [{obj}; a_LC];
    c_x    = cellfun(@(o) label(o, o.sv_x, opt.tag), a_all, 'UniformOutput', false);
    c_u    = cellfun(@(o) label(o, o.sv_u, opt.tag), a_all, 'UniformOutput', false);
    c_y    = cellfun(@(o) label(o, output_name(o), opt.tag), a_all, 'UniformOutput', false);
    sys.StateName  = vertcat(strings(0,1), c_x{:});
    sys.InputName  = [label(obj, sv_portIn, opt.tag);  vertcat(strings(0,1), c_u{:})];
    sys.OutputName = [label(obj, sv_portOut, opt.tag); vertcat(strings(0,1), c_y{:})];

    varargout{1} = cellstr(sys.StateName);
    varargout{2} = cellstr(sys.InputName);
    varargout{3} = cellstr(sys.OutputName);

    if opt.Format ~= "struct"
        l_eq = l_equilibrium && ~isempty(obj.a_Bus) && isequal(rv_point, SolverLIN.point_vector(obj, []));
        sys  = object_result(sys, rv_point, l_eq, t0);
        if opt.Format == "ss"
            sys = sys.get_ss(Format="ss");
        end
    end

    function result = object_result(sct_sys, rv_point, l_eq, t0)
        % ResultLIN holding the port model, the variable map and the Jacobian blocks
        nu = numel(obj.sv_u);
        sct_block = struct("E", sct_sys.E);
        if opt.port == "V2I"
            sct_block.Axx = sct_sys.A;
            sct_block.Axv = sct_sys.B(:,1:2);
            sct_block.Bx  = sct_sys.B(:,2+(1:nu));
        end
        sct_output = struct("message", "Linearized the component " + obj.s_tag + " at the equilibrium.", ...
                            "s_issue", "", "l_equilibrium", l_eq, "s_layer", "Component");
        if ~l_eq
            sct_output.message = "Linearized the component " + obj.s_tag + " at the given point.";
        end
        net = [];
        if ~isempty(obj.a_Bus)
            net = obj.a_Bus.a_PowerNetwork;
        end
        result = ResultLIN(net, "", struct("Port", opt.port, "Point", {opt.Point}), true, sct_output, t0, ...
                           obj.get_variable_map(), rv_point, sct_block, struct("sct_sys", sct_sys), zeros(0,1));
    end

    function [SYS, sysCON] = connect_states(SYS, sysCON, a_LC)
        iv_x = zeros(0,1);
        for k = 1:numel(a_LC)
            lv = a_LC{k}.iv_obsX > 0;
            if any(lv)
                iv_in = numel(sysCON{k}.InputName) - numel(lv) + find(lv);    % the inputs sv_u come after Vre, Vim
                sysCON{k}.InputName(iv_in) = "X__" + obj.sv_x(a_LC{k}.iv_obsX(lv));
                iv_x = [iv_x; a_LC{k}.iv_obsX(lv)]; %#ok<AGROW>
            end
        end
        if isempty(iv_x)
            return
        end
        iv_x = unique(iv_x);
        Ex   = eye(size(SYS.A,1));
        SYS.C = [SYS.C; Ex(iv_x,:)];
        SYS.D = [SYS.D; zeros(numel(iv_x), size(SYS.B,2))];
        SYS.OutputName = [SYS.OutputName; "X__" + reshape(obj.sv_x(iv_x), [], 1)];
    end

    function sv = label(owner, sv_name, l_tag)
        sv_name = reshape(string(sv_name), [], 1);
        if l_tag && ~isempty(sv_name)
            sv = reshape(string(owner.attach_tag(sv_name)), [], 1);
        else
            sv = sv_name;
        end
    end

    function sv = output_name(owner)
        % Outputs with the name of a state of their owner are labelled "Y_" + name
        sv = reshape(string(owner.sv_y), [], 1);
        lv = ismember(sv, owner.sv_x);
        sv(lv) = "Y_" + sv(lv);
    end

    function build_stale(layer)
        layer.set_odefcn();
        for k = 1:numel(layer.a_LocalController)
            build_stale(layer.a_LocalController{k});
        end
    end

    function list = all_controllers(parent)
        list = cell(0,1);
        for k = 1:numel(parent.a_LocalController)
            con  = parent.a_LocalController{k};
            list = [list; {con}; all_controllers(con)]; %#ok<AGROW>
        end
    end

end


function sys = connect_blocks(c_blk, iv_in, iv_out)
% Connects the blocks by name, keeping all states in the order of the blocks: an input
% takes the sum of the outputs of the same name (outputs of the first block do not feed
% its own inputs) plus the external input. iv_in and iv_out pick the external inputs and
% the outputs among the inputs and outputs of all blocks.
    A = tools.cellfun(@(S) S.A, c_blk);  B = tools.cellfun(@(S) S.B, c_blk);
    C = tools.cellfun(@(S) S.C, c_blk);  D = tools.cellfun(@(S) S.D, c_blk);
    E = tools.cellfun(@(S) S.E, c_blk);
    A = blkdiag(A{:});  B = blkdiag(B{:});  C = blkdiag(C{:});  D = blkdiag(D{:});  E = blkdiag(E{:});
    sv_in  = tools.cellfun(@(S) S.InputName,  c_blk);   sv_in  = vertcat(strings(0,1), sv_in{:});
    sv_out = tools.cellfun(@(S) S.OutputName, c_blk);   sv_out = vertcat(strings(0,1), sv_out{:});

    K = double(sv_in == sv_out.');      % K(i,j) = 1: output j feeds input i
    K(1:numel(c_blk{1}.InputName), 1:numel(c_blk{1}.OutputName)) = 0;
    P = eye(numel(sv_in));
    P = P(:, iv_in);                    % external inputs

    % u = P w + K y,  y = C x + D u  =>  y = (I - D K) \ (C x + D P w)
    M  = eye(numel(sv_out)) - D*K;
    Cy = M \ C;
    Dy = M \ (D*P);
    sys = struct("A", A + B*K*Cy, "B", B*(P + K*Dy), "C", Cy(iv_out,:), "D", Dy(iv_out,:), "E", E, ...
                 "StateName", strings(0,1), "InputName", sv_in(iv_in), "OutputName", sv_out(iv_out));
end
