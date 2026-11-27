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
% - Built and attached by `Component.add_local_controller` from its model key `key` (the
%   constructors of the concrete classes are accessible only from `Component`), which
%   sets `a_Component` (`SetAccess`), resolves the observed inputs and logs a "Topology"
%   edit, so a controller is always on a component of a network. A controller attaches
%   to one parent at a time. A removed or replaced controller is deleted.
% - Differs from `Component` on purpose: no `fcn_I`, the output function is `fcn_y`, and
%   the Jacobians are required. Inputs named X or Y are not allowed.
% - `resolve_observe` (called by `Component.add_local_controller` on attachment) expands
%   "Xall" / "Yall" (`sr_reserved`) and sets where each input sv_u(k) is read on the observed component: iv_obsY(k) is its
%   index in sv_y, iv_obsX(k) its index in sv_x, and both are 0 for an input that is not
%   observed (its equilibrium value, or the output of a nested controller of the same name).
% - The handles `f_*` @(t,x,V,u) bind param and omega0 (there is no f_I);
%   `set_odefcn` builds them, called by `initialize` when they are stale
%   (`sct_stale.odefcn`, or a network frequency other than `r_odefcnHz`).
% - Stale tags (`sct_stale`): `equilibrium` (its dynamics, a nested controller, its
%   attachment) and `odefcn` (its dynamics, its attachment). The component recomputes the
%   equilibria of its controllers when one of them is stale (Component.set_equilibrium
%   stores the outputs of their get_equilibrium), then calls `initialize(true)`, with
%   which each controller clears its own tag.
%
% Subclasses in the `controller` package define the static model functions (`fcn_dx`,
% `fcn_y`, `fcn_Mass`), their Jacobians and the variable names. A concrete class has a
% model key `key` (e.g. "avr-ST1"), with which `Component.add_local_controller` builds and
% attaches it, and a role `s_role` that says where it goes (an "avr" or "local"
% controller and a "governor" on the component, a "pss" under the AVR).
% The two top-level controllers of a component drive different inputs.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% gen = net.a_Bus{1}.a_Component{1};
% avr = gen.add_local_controller("avr-ST1");
% pss = gen.add_local_controller("pss-PSS1");   % the PSS is attached under the AVR
% net.initialize();
% avr.rv_Xequilibrium
% ```
%
% See also Component.add_local_controller, controller.avr.AVR_ST1, controller.pss.PSS1, controller.governor.IEEJ_LPT1, controller.local_LQR

%% Abstract properties
    properties(Abstract, Constant, Hidden) % Subclass contract
        key (1,1) string                           % Model key that selects the class in Component.add_local_controller (concrete classes only).
        s_role (1,1) string                        % Role: "avr", "pss", "local" (attached in the place of an AVR) or "governor" (beside it).
    end
    properties(Abstract, SetAccess=protected, Hidden) % Subclass contract
        sv_x (:,1) string                          % Names of the states.
        sv_u (:,1) string                          % Names of the inputs.
        sv_y (:,1) string                          % Names of the outputs.
        sv_para (:,1) string                       % Names of the dynamic parameters passed to the model functions.
    end
    
%% Parameter    
    properties(SetAccess={?Component, ?LocalController}) % Layer Structure
        a_Component = []                           % Parent: the component, or the AVR for a PSS (set by Component.add_local_controller). <@Type> Component or LocalController
    end
    properties(SetAccess=protected) % Layer Structure
        a_LocalController = cell(0,1)              % Nested controller (the PSS under an AVR), 0x1 or 1x1. <@Stale> equilibrium
    end
    properties(SetAccess=protected) % Cached function handles
        f_Mass                                     % Mass matrix function @(t,x,V,u) with the parameters bound.
        f_dx                                       % State equation function @(t,x,V,u) with the parameters bound.
        f_Y                                        % Output function @(t,x,V,u) with the parameters bound.
        f_JacobiDx                                 % Jacobian function of f_dx.
        f_JacobiY                                  % Jacobian function of f_Y.
    end
    properties (SetAccess={?SolverODE}, Hidden) % Simulation working data
        l_hasController (1,1) logical = false      % Whether a nested controller is attached.
    end
    properties (SetAccess=private, Hidden) % Layer Structure
        iv_obsY (:,1) double = zeros(0,1)          % Index in sv_y of the observed component of each input (0: not read from sv_y).
        iv_obsX (:,1) double = zeros(0,1)          % Index in sv_x of the observed component of each input (0: not read from sv_x).
    end
    properties (Access=private) % Layer Structure
        sv_uRequest (:,1) string = strings(0,1)    % sv_u as defined, before "Xall" / "Yall" are expanded.
    end
    properties (Constant, Hidden) % Layer Structure
        sr_reserved = ["Xall","Yall"]              % Reserved input names: all the states sv_x / all the outputs sv_y of the component.
    end
    properties(SetAccess=protected, Hidden) % Cached function handles
        r_odefcnHz double = []                     % [Hz] Network frequency bound into the f_* handles (empty: never built).
    end
    properties(SetAccess={?Component,?LocalController}) % Steady State
        rv_Xequilibrium (:,1) double = zeros(0,1)  % State equilibrium (the output of get_equilibrium, stored by Component.set_equilibrium).
        rv_Uequilibrium (:,1) double = zeros(0,1)  % Input equilibrium (the output of get_equilibrium, stored by Component.set_equilibrium).
    end

    properties(Dependent) % Steady State
        c_Vequilibrium                             % [pu] Voltage equilibrium of the parent.
        c_Iequilibrium                             % [pu] Current equilibrium of the parent.
    end

    properties(Dependent, Access=protected) % Layer Structure
        parent                                     % Parent in the layer structure: the component, or the AVR for a PSS.
        children                                   % Children in the layer structure: the nested controller.
    end

%% Abstract methods
    methods (Abstract)
        % Return the state and input equilibria of the controller.
        %
        % Returns x (numel(sv_x) x 1) and u (numel(sv_u) x 1) from its arguments only and
        % stores nothing (no property is written or read for the point, the nested controller
        % is not called). Component.set_equilibrium calls it for the controller and each
        % nested controller (depth first) during PowerNetwork.initialize and stores the
        % values; the continuation power flow and the stability-constrained OPF call it at
        % other points. V is the voltage phasor of the component [pu], u its input and x its
        % state at the point (the observed component: the generator for a PSS under an AVR).
        % The fourth argument x is optional: a subclass with get_equilibrium(obj, V, u) is
        % called with three (get_equilibrium_at). Work that changes the controller (e.g.
        % the design of a gain) goes in initialize(obj, l_equilibrium), called next.
        [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, V, u, x)
    end
    methods (Abstract, Static)        
        % Return the state derivatives of the controller.
        %
        % The arguments of all model functions are the time t [s], the states x, the
        % voltage V = [Vre; Vim] [pu] of the bus of the observed component, the inputs u,
        % the dynamic parameters param (in the order of sv_para) and the nominal frequency
        % omega0 [Hz]. A subclass may define them as ordinary methods instead, with obj before t.
        dx = fcn_dx(t, x, V, u, param, omega0)

        % Return the outputs of the controller.
        y  = fcn_y(t, x, V, u, param, omega0)

        % Return the mass matrix of the state equation.
        %
        % It must be constant: simulate calls it with empty t, x, V and u.
        M  = fcn_Mass(t, x, V, u, param, omega0)

        % Return the Jacobians of fcn_dx with respect to x, V and u.
        [Axx,Bxv,Bxu] = Jacobi_dx(t,x,V,u,param,omega0)

        % Return the Jacobians of fcn_y with respect to x, V and u.
        [Cyx,Dyv,Dyu] = Jacobi_Y(t,x,V,u,param,omega0)
    end   
    
%% Constructor    
    methods
        function obj = LocalController(tag)
            % Create a local controller with the given tag (called by the subclass constructors).
            arguments (Input)
                tag (1,1) string  % Tag of the controller.
            end
            arguments (Output)
                obj  % New controller, not attached yet.
            end
            obj.s_tag = tag;
            obj.sct_stale = struct("equilibrium", obj.s_notInitialized, "odefcn", obj.s_notInitialized);
            % tab_parameter column dynamics: the sv_para columns are passed to the model functions as param
            obj.a_Parameter = {Parameter(obj,"dynamics")};
        end        
    end    

%% Methods    
    methods (Hidden)
        sv = driven_inputs(obj, comp)
        % Constructor arguments outside the dynamics table (written by net.export)
        sct = get_option(obj)
    end

    methods (Hidden, Sealed)
        % get_equilibrium with the state x of the component, or without it for a subclass with three arguments
        [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium_at(obj, V, u, x)
    end

    methods (Access={?Component,?LocalController})
        add_local_controller(obj,a_Controller)

        remove_local_controller(obj)

        initialize(obj, l_equilibrium)
        set_odefcn(obj)

        resolve_observe(obj)

    end

    methods (Access=protected)
        resolve_ports(obj, comp)

        set_inputs(obj, sv_name)

        comp = observed_component(obj)

    end

    methods (Access=protected)
        handle_edit(obj, a_layer, tag, log)
        sct_page = gui_content(obj)
    end
    methods (Access=private)
        val = parent_equilibrium(obj, s_prop)
    end


%% Analysis
    methods
        % Variable map (rows x, Vre, Vim, uc, yc and their equilibrium)
        tab = get_variable_map(obj)
        % Energy-function Hessian (port "PI"; overridden by the classes that support it)
        sct_hessian = get_hessian(obj, x, V, u)
        % Inputs and outputs of the model functions at a point
        tab = disp_io(obj, x, V, u)
    end
    methods (Hidden)
        % Linearization (get_sys connects the blocks)
        sct_block = get_linear_matrix(obj, x, V, u)
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
    end

%% Set Methods
    methods
        function set.a_LocalController(obj, a_con)
            % Every write keeps the nested slot: one PSS under an AVR, nothing under the others
            check_nested_slot(obj, a_con);
            obj.a_LocalController = a_con;
        end
    end
end
