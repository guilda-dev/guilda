classdef GlobalController < PowerSystemModel
% Abstract class of a controller that acts on several components of a network, such as an AGC.
%
% A global controller is a dynamical system with state $x$, input $u$ and output $y$. It
% observes the controlled components (`controlledUnits`) by the names in `sv_u` and the
% voltages of all buses (its port V), and its outputs drive inputs of those components or of
% their local controllers. Subclasses in the
% `controller` package define the static model functions (`fcn_dx`, `fcn_y`, `fcn_Mass`), their Jacobians and the
% variable names. A global controller is built for a network and added with
% `PowerNetwork.add_global_controller` from its model key `key` (e.g. "agc-PI").
%
% - Owns its parameters (one row per controlled unit), its equations (through its
%   subclass) and its equilibrium. Its parent is the network.
% - The components it acts on, `controlledUnits`, are associations fixed by its
%   constructor, which receives the network only to look them up. While the controller is
%   on the network, its units cannot be removed or replaced, nor their buses removed.
% - Input signals `sv_u`: for each controlled unit, in the order of `controlledUnits`, the
%   outputs `sv_y` of the unit of these names, or its states `sv_x` (an output is read when
%   both have the name, as for a local controller): u = [sv_u of unit 1; sv_u of unit 2; ...].
%   `iv_obsY` / `iv_obsX` hold where each input is read. A tripped unit gives 0.
% - Port V: the voltages of all buses [Vre1; Vim1; Vre2; ...] in the order of `a_Bus`. The
%   flow of a branch is not an input: the controller computes it from V and the branch data.
% - Output signals `sv_y`, one set per controlled unit in the same order: an output goes to
%   every local controller of the unit (nested ones included) that has an input of that name,
%   and then not to the component; the controller input receives the sum of what it reads
%   without the global controller (an output or a state of the component, the output of a
%   nested controller, or its equilibrium) and the output. Otherwise the output is added to
%   the input of that name of the component. These connections are the rows "global" of
%   the connection map (`net.get_variable_map`); `PowerNetwork.add_global_controller`
%   shows them, and an edit of the local controllers of a unit that changes them
%   (`Component.add_local_controller`, `remove_local_controller`) shows what changed as
%   an INFO message.
%   For example, `controller.agc.broadcast_PI_AGC` reads the speed "omega" of each
%   generator and adds to its input "Pmech".
% - The outputs must be 0 at the equilibrium (net.initialize checks it), as they add to
%   inputs whose equilibrium is already set.
% - Unlike a `LocalController`: no nested controller. It does not own its units and is not a
%   child of any bus.
% - Created only by `PowerNetwork.add_global_controller` (the constructors of the concrete
%   classes are accessible only from `PowerNetwork`), so a controller is always on a
%   network. Only the network sets `a_PowerNetwork` (`SetAccess`; add_global_controller
%   logs the attachment as a "Topology" edit), and `PowerNetwork.remove_global_controller`
%   deletes the controller.
% - The handles `f_*` @(t,x,V,u) bind param and omega0; `set_odefcn` builds them,
%   called by `initialize` when they are stale (`sct_stale.odefcn`, or a network
%   frequency other than `r_odefcnHz`).
% - Stale tags (`sct_stale`): `equilibrium` (its dynamics, its addition to the network)
%   and `odefcn` (its dynamics, its attachment). `initialize`, called last by
%   PowerNetwork.initialize, rebuilds them; the equilibrium is also recomputed whenever
%   that initialize found anything stale, since it may read the controlled units.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% g1  = net.a_Bus{1}.a_Component{1};
% g2  = net.a_Bus{2}.a_Component{1};
% agc = net.add_global_controller("agc-PI", {g1, g2}, parameter=struct(alpha=[1;1], beta=[1;1], kP=100, kI=500));
% net.initialize();
% sys = agc.get_sys();
% ```
%
% See also PowerNetwork.add_global_controller, controller.agc.broadcast_PI_AGC, LocalController

    properties(Abstract, Constant, Hidden=true) % Subclass contract
        key (1,1) string                           % Model key that selects the class in PowerNetwork.add_global_controller.
        s_role (1,1) string                        % Role of the controller, e.g. "agc".
        sv_x (:,1) string                          % Names of the states.
        sv_u (:,1) string                          % Names of the inputs, read on each controlled unit (its outputs, else its states).
        sv_y (:,1) string                          % Names of the outputs, for each controlled unit (inputs of its local controllers, else of the unit).
        sv_para (:,1) string                       % Names of the dynamic parameters passed to the model functions.
    end

    properties(SetAccess=protected) % Cached function handles
        f_Mass                                     % Mass matrix function @(t,x,V,u) with the parameters bound.
        f_dx                                       % State equation function @(t,x,V,u) with the parameters bound.
        f_Y                                        % Output function @(t,x,V,u) with the parameters bound.
        f_JacobiDx                                 % Jacobian function of f_dx.
        f_JacobiY                                  % Jacobian function of f_Y.
    end
    properties (SetAccess={?PowerNetwork}) % Layer Structure
        a_PowerNetwork = []                        % PowerNetwork the controller belongs to (set by add_global_controller). <@Type> PowerNetwork
    end
    properties (SetAccess=protected, Hidden) % Layer Structure
        controlledUnits                            % Controlled components, in the order given to the constructor.
        iv_obsY (:,1) double = zeros(0,1)          % Index in sv_y of its unit of each input (0: not read from sv_y), units in order.
        iv_obsX (:,1) double = zeros(0,1)          % Index in sv_x of its unit of each input (0: not read from sv_x), units in order.
    end
    properties(SetAccess=protected, Hidden) % Cached function handles
        r_odefcnHz double = []                     % [Hz] Network frequency bound into the f_* handles (empty: never built).
    end
    properties(SetAccess=protected) % Steady State
        rv_Xequilibrium (:,1) double = zeros(0,1)  % State equilibrium (from get_equilibrium, set by PowerNetwork.initialize).
        rv_Uequilibrium (:,1) double = zeros(0,1)  % Equilibrium of the inputs (the observed outputs or states), one entry per input of each unit.
    end
    properties(Dependent, Access=protected) % Layer Structure
        parent                                     % Parent in the layer structure: the network.
        children                                   % Children in the layer structure: none.
    end

    methods (Abstract)
        % Return the state and input equilibria of the controller.
        %
        % Returns x (nx x 1) and u (one entry per input of each unit). PowerNetwork.initialize
        % calls it after the equilibria of the buses and components are set, so it may read
        % them.
        [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj)
    end
    methods (Abstract, Static)        
        % Return the state derivatives of the controller.
        %
        % The arguments of all model functions are the time t [s], the states x, the
        % voltages of all buses V = [Vre1; Vim1; Vre2; ...] [pu] (in the order of a_Bus),
        % the inputs u, the dynamic parameters param and the nominal frequency omega0 [Hz].
        dx = fcn_dx(t, x, V, u, param, omega0)

        % Return the outputs of the controller: the outputs sv_y for each controlled unit, in order.
        y  = fcn_y(t, x, V, u, param, omega0)

        % Return the mass matrix of the state equation.
        %
        % It must be constant: simulate calls it with empty t, x, V and u.
        M  = fcn_Mass(t, x, V, u, param, omega0)
    end       

    methods
        function obj = GlobalController(net, tag, varargin)
            % Create a global controller of the network net that controls the given components.
            %
            % `varargin` lists the controlled components of net, as Component objects or
            % tags. Anything else stops with GUILDA:GlobalController:InvalidComponent.
            arguments (Input)
                net (1,1) PowerNetwork   % Network whose components are controlled.
                tag (1,1) string         % Class header and number of the tag (e.g. "AGC1"); the tag of net is put in front.
            end
            arguments (Input, Repeating)
                varargin   % Controlled components of net, as Component objects or tags.
            end
            arguments (Output)
                obj   % New GlobalController object.
            end
            obj.s_tag = net.s_tag + tag;
            obj.sct_stale = struct("equilibrium", obj.s_notInitialized, "odefcn", obj.s_notInitialized);
            % tab_parameter column dynamics: one row per controlled unit (row names: the unit
            % tags); the sv_para columns are passed as param
            a_Pd = Parameter(obj,"dynamics");
            obj.a_Parameter = {a_Pd};

            cls_comp = tools.cellfun(@(b) b.a_Component, net.a_Bus);            
            cls_comp = vertcat(cls_comp{:});            

            idx = 1;
            while idx <= nargin-2
                arg = varargin{idx};
                if isa(arg, 'Component')
                    varargin{idx} = arg.s_tag;
                end

                lv_comp = strcmp(varargin{idx}, string(cls_comp));
                % A component of another network can have the same tag as one of net
                if all(~lv_comp) || (isa(arg, 'Component') && cls_comp{lv_comp} ~= arg)
                    if isa(arg, 'Component') || isstring(arg) || ischar(arg)
                        s_arg = char(strjoin(string(varargin{idx})));
                    else
                        s_arg = class(arg);
                    end
                    error(msg("GUILDA:GlobalController:InvalidComponent", s_arg, char(obj.s_tag), char(net.s_tag)))
                end

                obj.controlledUnits = [obj.controlledUnits; cls_comp(lv_comp)];

                idx = idx + 1;
            end

            % Where each input is read on its unit: an output, else a state (fixed: the
            % units and their variable names do not change while the controller exists)
            n_unit = numel(obj.controlledUnits);
            obj.iv_obsY = zeros(n_unit*numel(obj.sv_u), 1);
            obj.iv_obsX = zeros(n_unit*numel(obj.sv_u), 1);
            for idx = 1:n_unit
                unit = obj.controlledUnits{idx};
                [~, iv_y] = ismember(obj.sv_u, unit.sv_y);
                [~, iv_x] = ismember(obj.sv_u, unit.sv_x);
                iv_x(iv_y > 0) = 0;
                iv_k = (idx-1)*numel(obj.sv_u) + (1:numel(obj.sv_u));
                obj.iv_obsY(iv_k) = iv_y;
                obj.iv_obsX(iv_k) = iv_x;
            end

        end

    end
    methods
        % Variable map (rows x, Vre, Vim, uc, yc and their equilibrium)
        tab = get_variable_map(obj)
    end
    methods (Hidden)
        % Linearization (get_sys connects the blocks)
        sct_block = get_linear_block(obj, x, V, u)
    end
    methods (Access=protected)
        sct_port = get_linear_port(obj)
        set_odefcn(obj)
        handle_edit(obj, a_layer, tag, log)
        sct_page = gui_content(obj)
    end
    methods (Access={?PowerNetwork})
        initialize(obj, l_equilibrium)
    end
    methods        
        function p = get.parent(obj)
            p = obj.a_PowerNetwork;
        end
        function p = get.children(~) 
            p = {};
        end
    end
end