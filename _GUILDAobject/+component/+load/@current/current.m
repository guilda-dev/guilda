classdef current < component.load.abstract
% Constant-current load model.
%
% The load draws a current of fixed magnitude and power factor from the bus. The
% current keeps its phase relative to the bus voltage: the active part `Ip` is in
% phase with the voltage and the reactive part `Iq` is in quadrature with it. The
% load therefore injects `P = |V|*Ip` and `Q = |V|*Iq`, both proportional to the
% voltage magnitude. The steady inputs come from the power-flow solution
% (`get_equilibrium`).
%
% **Dynamic model**
% The model is a dynamical system with state $x$, input $u$ and output $y$, connected
% to its bus through the bus voltage $V$ and the current $I$ it injects.
%
% **State variables** $x$ (`sv_x`)
% - none
%
% **Input signals** $u$ (`sv_u`; the ports driven by local controllers and events)
% - `Ip` [pu]: current in phase with the bus voltage, injected into the bus (negative for consumption).
% - `Iq` [pu]: current in quadrature with the bus voltage, injected into the bus (negative for consumption).
%
% **Output signals** $y$ (`sv_y`; read by local controllers)
% - none
%
% **Parameters** (`sv_para`)
% - none
%
% **Equation**
% ```math
% I = (I_p - jI_q)\frac{V}{|V|}, \quad P + jQ = V\overline{I} = |V|(I_p + jI_q)
% ```
%
% **Energy function**
% The reactive part has the energy function $-I_q|V|$. The active power $P = |V| I_p$
% depends on the voltage and has no energy function: `get_hessian` returns the
% Jacobian of the port balance, which is not symmetric.
%
% <@Examples>
% ```matlab
% net = PowerNetwork();
% bus = net.add_bus();
% ld  = bus.add_component("load-current", "P", -0.8, "Q", -0.3);
% ld.s_tag                          % "B001LI1"
% ld.sv_u                           % Ip, Iq
% ```
%
% See also component.load.abstract, component.load.power, component.load.impedance, Bus.add_component
    properties(Constant) % Model definition
        key = "load-current";  % Model key that selects this class in `Bus.add_component`.
        sv_x = [];             % State names (none).
        sv_u = ["Ip";"Iq"];    % Input port names.
        sv_y = [];             % Output names (none).
        sv_para = [];          % Dynamic parameter names (none).
    end

    methods(Access={?Bus})
        function obj = current(index, ~, varargin)
            % Create the load; called through `Bus.add_component`.
            %
            % `index` is the tag suffix (the tag is the bus tag + `"LI"+index`). The
            % `parameter` argument is ignored, and `varargin` holds the
            % name-value options of `add_component`.
            arguments (Input)
                index  % Number of the tag.
                ~      % Parameter input of Bus.add_component (ignored).
            end
            arguments (Input, Repeating)
                varargin  % Options of Bus.add_component, passed on to Component.
            end
            arguments (Output)
                obj  % Constant-current load object.
            end
            obj@component.load.abstract("I"+index, varargin{:})
        end
    end

    methods
        [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj,c_V,c_I,r_P,r_Q)
        sct_hessian = get_hessian(obj, x, V, u)
        PQ = getCompPQ(obj,x,V,u,param)
    end

    methods
        dx = fcn_dx(obj,t,x,V,u,param,omega0);
        I  = fcn_I(obj,t,x,V,u,param,omega0);
        y  = fcn_Y(obj,t,x,V,param,omega0);
        M  = fcn_Mass(obj,t,x,V,u,param,omega0);
    end

    methods (Static)
        [Axx,Bxv,Bxu] = Jacobi_dx(t,x,V,u,param,omega0);
        [Cyx,Dyv] = Jacobi_Y(t,x,V,param,omega0);
        [Cix,Div,Diu] = Jacobi_I(t,x,V,u,param,omega0);
    end
end
