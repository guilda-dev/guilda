classdef LocalController < PowerSystemModel
% <@Desc>
% Abstract base class for local controller models attached to a Component.
% It defines the interface for controller dynamics and output functions.
% Inherit from this class to implement a new local controller model.
% <@Role>
% Power System Model
% <@Constructor>
% LocalController(tag)
%  i.e.
%  >> obj = LocalController(tag)
%      - tag: tag string to identify this controller

    properties(Dependent)

        % <@Desc> Parameter table for the controller dynamics.
        % <@Role> Parameter
        % <@Type> table
        % <@Size> 1x1
        tab_parameter
    end
    properties(Dependent, Access=protected)

        % <@Desc> Parent Component object in the layer hierarchy.
        % <@Role> Layer Structure
        % <@Type> Component
        % <@Size> 1x1
        parent 

        % <@Desc> Child objects in the layer hierarchy (none for LocalController).
        % <@Role> Layer Structure
        % <@Type> cell array
        % <@Size> 0x1
        children
    end
    properties(SetAccess=protected)

        % <@Desc> Component object to which this controller is connected.
        % <@Role> Layer Structure
        % <@Type> Component
        % <@Size> 1x1
        a_Component 

        % <@Desc> Parameter container for controller dynamics settings.
        % <@Role> Parameter
        % <@Type> Parameter
        % <@Size> 1x1
        para_dynamics
    end

    properties(SetAccess=protected)           

        % <@Desc> Cell array of nested local controllers (if any).
        % <@Role> Layer Structure
        % <@Type> LocalController cell array
        % <@Size> Nx1
        a_LocalController = cell(0,1)          

        % <@Desc> Mass matrix function handle for the ODE integration.
        % <@Role> Dynamics
        % <@Type> function_handle
        % <@Size> 1x1
        rm_odeMass        = @(t,x,V,u)[]                  

        % <@Desc> Differential equation function handle for the ODE integration.
        % <@Role> Dynamics
        % <@Type> function_handle
        % <@Size> 1x1
        fv_odeDiff        = @(t,x,V,u)[]                                   

        % <@Desc> Output equation function handle.
        % <@Role> Dynamics
        % <@Type> function_handle
        % <@Size> 1x1
        fv_odeY           = @(t,x,V,u)[]                                   

        % <@Desc> Jacobian matrix A (state-to-state) for linearized model.
        % <@Role> Linearize
        % <@Type> function_handle
        % <@Size> 1x1
        JacobiA           = @(t,x,V,u)[]                   

        % <@Desc> Jacobian matrix B (input-to-state) for linearized model.
        % <@Role> Linearize
        % <@Type> function_handle
        % <@Size> 1x1
        JacobiB           = @(t,x,V,u)[]                   

        % <@Desc> Jacobian matrix C (state-to-output) for linearized model.
        % <@Role> Linearize
        % <@Type> function_handle
        % <@Size> 1x1
        JacobiC           = @(t,x,V,u)[]                   

        % <@Desc> Jacobian matrix D (input-to-output) for linearized model.
        % <@Role> Linearize
        % <@Type> function_handle
        % <@Size> 1x1
        JacobiD           = @(t,x,V,u)[]                           
    end
    properties (SetAccess={?odeSimulator, ?Component}, Hidden)

        % <@Desc> ODE index mapping for controller state variables.
        % <@Role> Simulation
        % <@Type> double
        % <@Size> Nx1
        iv_odeX  = zeros(0,1);

        % <@Desc> ODE index mapping for controller input variables.
        % <@Role> Simulation
        % <@Type> double
        % <@Size> Nx1
        iv_odeU  = zeros(0,1);

        % <@Desc> Initial ODE state vector for the controller.
        % <@Role> Simulation
        % <@Type> double
        % <@Size> Nx1
        rv_odeX0 = zeros(0,1);
    end    
    properties(SetAccess=protected)

        % <@Desc> Equilibrium (steady-state) state vector of the controller.
        % <@Role> Steady State
        % <@Type> double
        % <@Size> Nx1
        cv_Xequilibrium (:,1) double = zeros(0,1)   

        % <@Desc> Equilibrium (steady-state) input vector of the controller.
        % <@Role> Steady State
        % <@Type> double
        % <@Size> Nx1
        cv_Uequilibrium (:,1) double = zeros(0,1)   
    end
    
    methods
        function obj = LocalController(tag)
        % <@Desc>
        % Creates a LocalController instance with the given tag.
        % <@Role>
        % Constructor
        % <@Abst>
        % Initialize the controller tag and parameter container.
        % <@Signatures>
        % [
        %   "obj = LocalController(tag)"
        % ]
        % <@varargin>
        % [
        %   {
        %     "Name": "tag",
        %     "Type": "string scalar",
        %     "Description": "Tag string to identify this controller.",
        %     "Required": true,
        %     "Default": "-"
        %   }
        % ]
        % <@varargout>
        % [
        %   {
        %     "Name": "obj",
        %     "Type": "LocalController",
        %     "Description": "Created LocalController instance."
        %   }
        % ]
            obj.str_tag = tag;
            obj.para_dynamics = Parameter(obj,"dynamics");
        end

    end
    methods (Abstract)
        dx = fcn_dx(obj, t, x, V, u, param, omega0)
        y  = fcn_y(obj, t, x, V, u, param, omega0)
        M  = fcn_Mass(obj, t, x, V, u, param, omega0)
    end
    methods
        function p = get.parent(obj)
            p = obj.a_Component;
        end
        function p = get.children(obj) %#ok
        end
        function tab = get.tab_parameter(obj)
            tab_tab  = obj.para_dynamics.tab_parameter;
            tab_name = obj.para_dynamics.str_tag;
            tab = table(tab_tab, 'VariableNames', tab_name);
        end
    end
end
