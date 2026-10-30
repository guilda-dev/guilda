classdef power < component.load.abstract
% Constant-power load model.
%
% The load injects the power `Pload + jQload` into the bus whatever the voltage.
% The steady inputs come from the power-flow solution (`get_equilibrium`).
%
% **States** (`sv_x`)
% - none
%
% **Inputs** (`sv_u`, the ports for local controllers and events)
% - `Pload` [pu]: active power injected into the bus (negative for consumption).
% - `Qload` [pu]: reactive power injected into the bus (negative for consumption).
%
% **Outputs** (`sv_y`)
% - none
%
% **Parameters** (`sv_para`)
% - none
%
% **Equation**
% ```
% I = conj((Pload + jQload)/V)
% ```
%
% <@Examples>
% ```matlab
% net = PowerNetwork();
% bus = net.add_bus();
% ld  = bus.add_component("load-power", "P", -0.8, "Q", -0.3);
% ld.str_tag                        % "LPQ1B001"
% ld.sv_u                           % Pload, Qload
% ```
%
% See also component.load.abstract, component.load.impedance, Bus.add_component
    
    properties % Steady state
        % [pu] Steady power `[P; Q]` injected into the bus, set by `get_equilibrium`.
        PQ_st
    end

    properties(Constant) % Model definition
        key      = "load-power";       % Model key that selects this class in `Bus.add_component`.
        sv_x    = [];                 % State names (none).
        sv_u    = ["Pload","Qload"];  % Input port names.
        sv_y    = [];                 % Output names (none).
        sv_para = [];                 % Dynamic parameter names (none).
        Prefix = "LP";                % Short name of the model (the tag starts with "LPQ").
    end

    methods(Access={?Bus})
        function obj = power(index, ~, varargin)
            % Create the load; called through `Bus.add_component`.
            %
            % `index` is the tag suffix (the tag is `"LPQ"+index`). The
            % `parameter` argument is ignored, and `varargin` holds the
            % name-value options of `add_component`.
            obj@component.load.abstract("PQ"+index, varargin{:})
        end
    end
    
    methods
        [rv_Xequilibrium, rv_Uequilibrium]  = get_equilibrium(obj, c_V, c_I);    
    end

    methods
        dx = fcn_dx(obj, t, x, V, I, u, param, omega0);
        I  = fcn_I(obj, t, x, V, I, u, param, omega0);
        y  = fcn_Y(obj, t, x, V, I, u, param, omega0);
        M  = fcn_Mass(obj, t, x, V, I, u, param, omega0);
    end

    methods       
        function PQ = getCompPQ(obj,x,V,u,param) %#ok
            % Return the power that the load injects into the bus.
            %
            % Used by the continuation power flow (`f_PQ2Bus`). The power is
            % the input `u = [Pload; Qload]`; `x`, `V` and `param` are not used.
            %
            % See also fcn_I
            arguments (Output)
                PQ % [pu] Active and reactive power `[P; Q]` injected into the bus.
            end
            PQ = u;
        end        
    end
    
    methods (Static)        
        [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0);
        [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0);
        [Cix,Div,Dii,Diu] = Jacobi_I(t,x,V,I,u,param,omega0);
    end
end
