classdef impedance < component.load.abstract
% Constant-impedance load model.
%
% The load draws the current of a fixed impedance `Z = R + jX` from the bus. The
% impedance is set from the power-flow solution (`get_equilibrium`), so the load
% consumes the specified `P` and `Q` at the power-flow voltage and less or more
% power when the voltage changes.
%
% **Dynamic model**
% The model is a dynamical system with state $x$, input $u$ and output $y$, connected
% to its bus through the bus voltage $V$ and the current $I$ it injects.
%
% **State variables** $x$ (`sv_x`)
% - none
%
% **Input signals** $u$ (`sv_u`; the ports driven by local controllers and events)
% - `R` [pu]: resistance of the load.
% - `X` [pu]: reactance of the load.
%
% **Output signals** $y$ (`sv_y`; read by local controllers)
% - none
%
% **Parameters** (`sv_para`)
% - none
%
% **Equation**
% ```math
% I = -\frac{V}{R + jX}
% ```
%
% <@Examples>
% ```matlab
% net = PowerNetwork();
% bus = net.add_bus();
% ld  = bus.add_component("load-impedance", "P", -0.8, "Q", -0.3);
% ld.s_tag                          % "LRX1B001"
% ld.sv_u                           % R, X
% ```
%
% See also component.load.abstract, component.load.power, Bus.add_component
    properties % Steady state
        Z                        % [pu] Complex impedance R + jX, set by get_equilibrium.
    end

    properties(Constant) % Model definition
        key = "load-impedance";  % Model key that selects this class in `Bus.add_component`.
        sv_x = [];               % State names (none).
        sv_u = ["R";"X"];        % Input port names.
        sv_y = [];               % Output names (none).
        sv_para = [];            % Dynamic parameter names (none).
    end

    methods(Access={?Bus})
        function obj = impedance(index, ~, varargin)
            % Create the load; called through `Bus.add_component`.
            %
            % `index` is the tag suffix (the tag is `"LRX"+index`). The
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
                obj  % Constant-impedance load object.
            end
            obj@component.load.abstract("RX"+index, varargin{:})
        end
    end

    methods        
        [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj,c_V,c_I,r_P,r_Q)        
    end

    methods
        dx = fcn_dx(obj,t,x,V,I,u,param,omega0);
        I  = fcn_I(obj,t,x,V,I,u,param,omega0);
        y  = fcn_Y(obj,t,x,V,I,u,param,omega0);
        M  = fcn_Mass(obj,t,x,V,I,u,param,omega0);
    end

    methods (Static)
        [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0);
        [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0);
        [Cix,Div,Dii,Diu] = Jacobi_I(t,x,V,I,u,param,omega0);
    end
end