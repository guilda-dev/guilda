classdef power < component.load.abstract
% Constant-power load model.
%
% The load injects the power `Pload + jQload` into the bus whatever the voltage.
% The steady inputs come from the power-flow solution (`get_equilibrium`).
%
% **Dynamic model**
% The model is a dynamical system with state $x$, input $u$ and output $y$, connected
% to its bus through the bus voltage $V$ and the current $I$ it injects.
%
% **State variables** $x$ (`sv_x`)
% - none
%
% **Input signals** $u$ (`sv_u`; the ports driven by local controllers and events)
% - `Pload` [pu]: active power injected into the bus (negative for consumption).
% - `Qload` [pu]: reactive power injected into the bus (negative for consumption).
%
% **Output signals** $y$ (`sv_y`; read by local controllers)
% - none
%
% **Parameters** (`sv_para`)
% - none
%
% **Equation**
% ```math
% I = \overline{\left(\frac{P_\mathrm{load} + jQ_\mathrm{load}}{V}\right)}
% ```
%
% <@Examples>
% ```matlab
% net = PowerNetwork();
% bus = net.add_bus();
% ld  = bus.add_component("load-power", "P", -0.8, "Q", -0.3);
% ld.s_tag                          % "LPQ1B001"
% ld.sv_u                           % Pload, Qload
% ```
%
% See also component.load.abstract, component.load.impedance, Bus.add_component
    
    properties(Constant) % Model definition
        key = "load-power";        % Model key that selects this class in `Bus.add_component`.
        sv_x = [];                 % State names (none).
        sv_u = ["Pload","Qload"];  % Input port names.
        sv_y = [];                 % Output names (none).
        sv_para = [];              % Dynamic parameter names (none).
        Prefix = "LP";             % Short name of the model (the tag starts with "LPQ").
    end

    methods(Access={?Bus})
        function obj = power(index, ~, varargin)
            % Create the load; called through `Bus.add_component`.
            %
            % `index` is the tag suffix (the tag is `"LPQ"+index`). The
            % `parameter` argument is ignored, and `varargin` holds the
            % name-value options of `add_component`.
            arguments (Input)
                index  % Tag suffix.
                ~      % Parameter input of Bus.add_component (ignored).
            end
            arguments (Input, Repeating)
                varargin  % Options of Bus.add_component, passed on to Component.
            end
            arguments (Output)
                obj  % Constant-power load object.
            end
            obj@component.load.abstract("PQ"+index, varargin{:})
        end
    end
    
    methods
        [rv_Xequilibrium, rv_Uequilibrium]  = get_equilibrium(obj, c_V, c_I, r_P, r_Q);    
    end

    methods
        dx = fcn_dx(obj, t, x, V, I, u, param, omega0);
        I  = fcn_I(obj, t, x, V, I, u, param, omega0);
        y  = fcn_Y(obj, t, x, V, I, u, param, omega0);
        M  = fcn_Mass(obj, t, x, V, I, u, param, omega0);
    end

    methods (Static)        
        [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0);
        [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0);
        [Cix,Div,Dii,Diu] = Jacobi_I(t,x,V,I,u,param,omega0);
    end
end
