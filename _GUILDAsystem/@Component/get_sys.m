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
% Out-of-date f_* handles are built first. Without Point, a component on a network stops
% with the error GUILDA:PowerNetwork:EquilibriumStale when net.initialize() is needed.
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
    end
    arguments (Output)
        sys   % Descriptor state-space model with state, input and output names.
    end
    arguments (Output, Repeating)
        varargout   % sys.StateName, sys.InputName and sys.OutputName, kept for old calls.
    end

    l_equilibrium = isempty(opt.Point) && ~iscell(opt.Point);
    obj.check_edit();
    if l_equilibrium && ~isempty(obj.a_Bus) && ~isempty(obj.a_Bus.a_PowerNetwork)
        net = obj.a_Bus.a_PowerNetwork;
        if net.s_edit.str_flag == "unset" || net.s_edit.l_staleEquilibrium
            net.check_edit("RequireEquilibrium", true);
        end
    end

    % All controllers in the tree (e.g. PSS attached under AVR) are separate blocks connected by signal names
    a_LC = all_controllers(obj);
    if l_equilibrium
        sysCON = tools.cellfun(@(d) d.get_sys_alone("tag",false), a_LC);
    else
        [x, V, I, u, c_con] = point_values(obj, a_LC, SolverLIN.point_vector(obj, opt.Point));
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

    if isempty(sysCON)
        sys = SYS(iv_out, iv_in);
    else
        blksys = append(SYS,sysCON{:});            

        blkConnect = connectCondition(blksys.InputGroup,blksys.OutputGroup);
        sysConnect = connectCondition(SYS.InputGroup,SYS.OutputGroup);

        lv_connect = ismember(blkConnect,sysConnect,"rows");                        

        sys = connect(blksys,blkConnect(~lv_connect,:),iv_in,iv_out,connectOptions("Simplify",false));
    end

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
    sv_x   = vertcat(strings(0,1), c_x{:});
    sv_in  = [label(obj, sv_portIn, opt.tag);  vertcat(strings(0,1), c_u{:})];
    sv_out = [label(obj, sv_portOut, opt.tag); vertcat(strings(0,1), c_y{:})];

    sys.StateName  = cellstr(sv_x);
    sys.InputName  = cellstr(sv_in);
    sys.OutputName = cellstr(sv_out);
    sys.InputGroup  = struct();     % no groups, so that sys(outputName, inputName) works
    sys.OutputGroup = struct();

    varargout{1} = cellstr(sv_x);
    varargout{2} = cellstr(sv_in);
    varargout{3} = cellstr(sv_out);

    function [SYS, sysCON] = connect_states(SYS, sysCON, a_LC)
        iv_x = zeros(0,1);
        for k = 1:numel(a_LC)
            lv = a_LC{k}.iv_obsX > 0;
            if any(lv)
                sv_in = string(sysCON{k}.InputName);
                iv_in = numel(sv_in) - numel(lv) + find(lv);    % the inputs sv_u come after Vre, Vim
                sv_in(iv_in) = "X__" + obj.sv_x(a_LC{k}.iv_obsX(lv));
                sysCON{k} = set_names(sysCON{k}, sv_in, string(sysCON{k}.OutputName));
                iv_x = [iv_x; a_LC{k}.iv_obsX(lv)]; %#ok<AGROW>
            end
        end
        if isempty(iv_x)
            return
        end
        iv_x = unique(iv_x);
        Ex   = eye(size(SYS.A,1));
        Cx   = Ex(iv_x,:);
        sv_y = [string(SYS.OutputName); "X__" + obj.sv_x(iv_x)];
        SYS2 = dss(SYS.A, SYS.B, [SYS.C; Cx], [SYS.D; zeros(numel(iv_x), size(SYS.B,2))], SYS.E);
        SYS2.StateName = SYS.StateName;
        SYS = set_names(SYS2, string(SYS.InputName), sv_y);
    end

    function sys = set_names(sys, sv_in, sv_out)
        sys.InputName   = cellstr(sv_in);
        sys.OutputName  = cellstr(sv_out);
        sys.InputGroup  = cell2struct(arrayfun(@(n) {n}, (1:numel(sv_in))'), cellstr(sv_in));
        sys.OutputGroup = cell2struct(arrayfun(@(n) {n}, (1:numel(sv_out))'), cellstr(sv_out));
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

    function list = all_controllers(parent)
        list = cell(0,1);
        for k = 1:numel(parent.a_LocalController)
            con  = parent.a_LocalController{k};
            list = [list; {con}; all_controllers(con)]; %#ok<AGROW>
        end
    end

    function Connect = connectCondition(in,out)
        Connect = zeros(0,2);

        fi = fieldnames(in);
        fo = fieldnames(out);
    
        idx = 1;
        nv_all = 0;
        while idx<=numel(fo)
            lv = strcmp(fi,fo(idx));
            if any(lv)
                str_i = fi{lv};
                rv_val = in.(str_i);
                nv = numel(rv_val);                
    
                Connect(nv_all+(1:nv), :) = [rv_val', repmat(out.(fo{idx}), [nv,1])];
                
                nv_all = nv_all + nv;            
            end
            
            idx = idx + 1;
        end
    end
    
end
