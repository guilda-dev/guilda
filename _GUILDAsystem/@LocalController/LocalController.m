classdef LocalController < PowerSystemModel
% Abstract class of a controller attached to one component, such as an AVR, a PSS, a governor or an LQR.
%
% A local controller is a dynamical system with state $x$, input $u$ and output $y$.
% It observes the component it is attached to (directly, or through the controllers
% above it) by the names of its input signals sv_u: a name in sv_y of the component reads that
% output, otherwise a name in sv_x reads that state (an output is read when both have
% the name). The reserved inputs "Xall" / "Yall" observe all the states / all the
% outputs. An input of the name of an output of a nested controller (e.g. Vpss) reads
% that output; other inputs stay at the equilibrium. The output signals sv_y of the controller
% drive the inputs of the same name of the component (or of the controller above it); an
% input event or a global controller on such an input of the component adds to them.
% The parent voltage V is available to it.
%
% Role in the model:
%
% - Owns its parameters, its equations (through its subclass), its equilibrium and at most
%   one nested controller (the PSS under an AVR). Its parent is a component, or the AVR
%   for a PSS. A PSS observes the same component as its AVR, and its output Vpss drives
%   the AVR input of that name.
% - Gives no current to the network (no `fcn_I`). It receives the parent voltage V in its
%   functions, but does not own the voltage or the frequency, and is not a child of the
%   bus.
% - Created with its constructor and attached with `Component.add_local_controller`, which
%   calls `set_parent`; that resolves the observed inputs. A
%   controller object attaches to one parent at a time.
% - Differs from `Component` on purpose: no `fcn_I`, the output function is `fcn_y`, and
%   the Jacobians are required. Inputs named X or Y are not allowed.
% - `resolve_observe` (called by `set_parent`) expands "Xall" / "Yall" (`sr_reserved`) and
%   sets where each input sv_u(k) is read on the observed component: iv_obsY(k) is its
%   index in sv_y, iv_obsX(k) its index in sv_x, and both are 0 for an input that is not
%   observed (its equilibrium value, or the output of a nested controller of the same name).
% - The handles `f_*` @(t,x,V,I,u) bind param and omega0 (there is no f_I);
%   `apply_edit("odefcn")` builds them, called by `check_edit` at the start of every
%   analysis. An edit of `tab_parameter` makes the equilibrium stale.
%
% Subclasses in the `controller` package define the static model functions (`fcn_dx`,
% `fcn_y`, `fcn_Mass`), their Jacobians and the variable names. Controllers are attached
% with `Component.add_local_controller`: the key says where (an "avr" or "local"
% controller and a "governor" on the component, a "pss" under the AVR).
% The two top-level controllers of a component drive different inputs.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% gen = net.a_Bus{1}.a_Component{1};
% avr = controller.avr.AVR_ST1("avr1");
% pss = controller.pss.PSS1("pss1");
% gen.add_local_controller(avr, pss);          % the PSS is attached under the AVR
% net.initialize();
% avr.rv_Xequilibrium
% ```
%
% See also Component.add_local_controller, controller.avr.AVR_ST1, controller.pss.PSS1, controller.governor.IEEJ_LPT1, controller.local_LQR

%% Abstract properties/methods    
    properties(Abstract, SetAccess=protected, Hidden) % Subclass contract
        key (1,1) string  % Kind: "avr", "pss", "local" (attached in the place of an AVR) or "governor" (beside it).
        sv_x (:,1) string  % Names of the states.
        sv_u (:,1) string  % Names of the inputs.
        sv_y (:,1) string  % Names of the outputs.
        sv_para (:,1) string  % Names of the dynamic parameters passed to the model functions.
    end
    methods (Abstract)
        % Set rv_Xequilibrium and rv_Uequilibrium of the controller and of its nested controllers.
        %
        % Called by Component.set_equilibrium during PowerNetwork.initialize; V is the voltage
        % phasor of the parent [pu] and u the equilibrium input of the component.
        get_equilibrium(obj, V, u)
    end
    methods (Abstract, Static)        
        % Return the state derivatives of the controller.
        %
        % The arguments of all model functions are the time t [s], the states x, the
        % parent voltage V = [Vre; Vim] [pu] and current I = [Ire; Iim] [pu], the inputs u,
        % the dynamic parameters param (in the order of sv_para) and the nominal frequency
        % omega0 [Hz]. A subclass may define them as ordinary methods instead, with obj before t.
        dx = fcn_dx(t, x, V, I, u, param, omega0)

        % Return the outputs of the controller.
        y  = fcn_y(t, x, V, I, u, param, omega0)

        % Return the mass matrix of the state equation.
        %
        % It must be constant: simulate calls it with empty t, x, V, I and u.
        M  = fcn_Mass(t, x, V, I, u, param, omega0)

        % Return the Jacobians of fcn_dx with respect to x, V, I and u.
        [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0)        

        % Return the Jacobians of fcn_y with respect to x, V, I and u.
        [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0)
    end   
    
%% Parameter    
    properties(SetAccess=protected) % Layer Structure
        a_Component  % Parent: the component, or the AVR for a PSS ([] when detached).
        a_LocalController = cell(0,1)  % Nested controller (the PSS under an AVR), 0x1 or 1x1. <@Stale> equilibrium
    end
    properties(SetAccess=protected) % Cached function handles
        f_Mass  % Mass matrix function @(t,x,V,I,u) with the parameters bound.
        f_dx  % State equation function @(t,x,V,I,u) with the parameters bound.
        f_Y  % Output function @(t,x,V,I,u) with the parameters bound.
        f_JacobiDx  % Jacobian function of f_dx.
        f_JacobiY  % Jacobian function of f_Y.
    end
    properties (SetAccess={?SolverODE}, Hidden) % Simulation working data
        iv_odeX = zeros(0,1);  % Positions of the states in the simulation vector.
        iv_odeU = zeros(0,1);  % Positions of the inputs in the simulation vector.
        iv_odeY = zeros(0,1);  % Positions of the parent inputs driven by the outputs sv_y, matched by name.
        lv_odeUfromLC = false(0,1);  % Inputs driven by an output of a nested controller.
        iv_odeYtoU = zeros(0,1);  % Index of each such input in the outputs of the nested controllers, stacked in order.
        rv_Xoffset = 0  % State offset added to the initial state (0 for a local controller).
        rv_Uoffset = @(t) 0  % Input change over time (zero for a local controller).
        l_hasController (1,1) logical = false  % Whether a nested controller is attached.
    end
    properties (SetAccess=private, Hidden) % Layer Structure
        iv_obsY (:,1) double = zeros(0,1)  % Index in sv_y of the observed component of each input (0: not read from sv_y).
        iv_obsX (:,1) double = zeros(0,1)  % Index in sv_x of the observed component of each input (0: not read from sv_x).
    end
    properties (Access=private) % Layer Structure
        sv_uRequest (:,1) string = strings(0,1)  % sv_u as defined, before "Xall" / "Yall" are expanded.
    end
    properties (Constant, Hidden) % Layer Structure
        sr_reserved = ["Xall","Yall"]  % Reserved input names: all the states sv_x / all the outputs sv_y of the component.
    end
    properties(SetAccess=protected) % Steady State
        rv_Xequilibrium (:,1) double = zeros(0,1)  % State equilibrium (set by get_equilibrium of the subclass).
        rv_Uequilibrium (:,1) double = zeros(0,1)  % Input equilibrium (set by get_equilibrium of the subclass).
    end

    properties(Dependent) % Steady State
        c_Vequilibrium  % [pu] Voltage equilibrium of the parent (zeros(0,1) without a parent).
        c_Iequilibrium  % [pu] Current equilibrium of the parent (zeros(0,1) without a parent).
    end

    properties(SetAccess=protected) % Parameter
        para_dynamics  % Dynamic parameters; the sv_para columns are passed to the model functions as param.
    end
    properties(Dependent) % Parameter
        tab_parameter  % Parameter table: the para_* tables side by side; writing it writes the parameters.
    end
    properties(Dependent, Access=protected) % Layer Structure
        parent  % Parent in the layer structure: the component, or the AVR for a PSS.
        children  % Children in the layer structure: the nested controller.
    end
    
%% Constructor    
    methods
        function obj = LocalController(tag)
            % Create a local controller with the given tag (called by the subclass constructors).
            arguments (Input)
                tag (1,1) string   % Tag of the controller.
            end
            arguments (Output)
                obj   % New controller, not attached yet.
            end
            obj.s_tag = tag;
            obj.para_dynamics = Parameter(obj,"dynamics");
        end        
    end    

%% Methods    
    methods (Hidden)
        sv = driven_inputs(obj, comp)
    end

    methods (Access={?Component,?LocalController})
        add_local_controller(obj,a_Controller)

        remove_local_controller(obj)

        set_parent(obj,a_Component)

        resolve_observe(obj)

        % get dx and y
        [DAEvec, y] = get_dx_algebraic(obj, t, x, Vi, Ii, obs, DAEvec)

    end

    methods (Access=protected)
        resolve_ports(obj, comp)

        set_inputs(obj, sv_name)

        comp = observed_component(obj)

    end

    methods (Access=protected)
        apply_edit(obj, s_target)
    end
    methods (Access=private)
        val = parent_equilibrium(obj, s_prop)
    end


%% Analysis
    methods
        % get sys (public: the linear model of the controller alone)
        [sys, varargout] = get_sys(obj,x,V,I,u,opt)
    end
    methods (Hidden)
        % get_sys without the edit checks (inner step of Component.get_sys)
        sys = get_sys_alone(obj,x,V,I,u,opt)
    end

%% Get Methods    
    methods        
        function V = get.c_Vequilibrium(obj)
            V = obj.parent_equilibrium("c_Vequilibrium");
        end
        function I = get.c_Iequilibrium(obj)
            I = obj.parent_equilibrium("c_Iequilibrium");
        end
        function p = get.parent(obj)
            p = obj.a_Component;
        end
        function p = get.children(obj) 
            p = obj.a_LocalController;
        end
        function tab = get.tab_parameter(obj)
            tab_tab  = obj.para_dynamics.tab_parameter;
            tab_name = obj.para_dynamics.s_tag;
            tab = table(tab_tab, 'VariableNames', tab_name);
        end
    end

%% Set Methods
    methods
        function set.tab_parameter(obj,val)
            fieldname = val.Properties.VariableNames;
            for i = 1:numel(fieldname)
                propname = "para_"+fieldname{i};
                tabdata  = val.(fieldname{i});
                paraname = tabdata.Properties.VariableNames;
                for j = 1:numel(paraname)
                    obj.(propname).(paraname{j}) = tabdata.(paraname{j});
                end
            end
        end
    end
end
