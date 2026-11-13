classdef droop < component.generator.abstract
% Droop generator model: first-order angle dynamics without inertia.
%
% The rotor inertia is neglected and the angle changes in proportion to the power
% mismatch (droop characteristic). The internal voltage is the field input `Vfield`.
%
% **Dynamic model**
% The model is a dynamical system with state $x$, input $u$ and output $y$, connected
% to its bus through the bus voltage $V$ and the current $I$ it injects.
%
% **State variables** $x$ (`sv_x`)
% - `delta` [rad]: Rotor angle in the network reference frame.
%
% **Input signals** $u$ (`sv_u`; the ports driven by local controllers)
% - `Pmech` [pu]: Mechanical power (governor output).
% - `Vfield` [pu]: Field voltage (AVR output).
%
% **Output signals** $y$ (`sv_y`; read by local controllers)
% - none
%
% **Parameters** (`sv_para`, the columns of `tab_parameter.dynamics`)
% - `D` [pu]: Damping coefficient.
% - `Xd` [pu]: d-axis synchronous reactance.
% - `Xq` [pu]: q-axis synchronous reactance.
%
% **Equations** ($\omega_0$ is the network frequency `get_Hz()`; $V_d$, $V_q$, $I_d$, $I_q$
% are the bus voltage and current in the rotor dq frame)
% ```math
% \frac{D}{2\pi\omega_0}\,\dot{\delta} = P_\mathrm{mech} - P
% ```
% with
% ```math
% I_d = \frac{V_\mathrm{field} - V_q}{X_d}, \quad I_q = \frac{V_d}{X_q}, \quad P = V_d I_d + V_q I_q
% ```
%
% The model has no output (`sv_y` is empty) and no `omega` state.
%
% <@Examples>
% ```matlab
% net = PowerNetwork();
% bus = net.add_bus();
% gen = bus.add_component("gen-droop", "P", 0.5);
% gen.sv_x                          % delta
% gen.tab_parameter.dynamics        % D, Xd, Xq
% ```
%
% See also component.generator.abstract, Bus.add_component

    properties (Constant) % Model definition
        key = "gen-droop";          % Model key that selects this class in `Bus.add_component`.
        sv_x = "delta";             % State names.
        sv_u = ["Pmech";"Vfield"];  % Input port names.
        sv_y = string.empty(0,1)    % Output names read by local controllers.
        sv_para = ["D","Xd","Xq"]   % Dynamic parameter names.
    end

    methods (Access={?Bus})
        function obj = droop(index, parameter, varargin)
            % Create the generator; called through `Bus.add_component` and `Bus.replace_component`.
            arguments (Input)
                index      % Number of the tag: the tag is the bus tag + "SG" + index.
                parameter  % Dynamic parameters: a table, a name in parameter.csv ("NGT2", "NGT6", "NGT8"), or NaN for its first row.
            end
            arguments (Input, Repeating)
                varargin   % Options of Bus.add_component, passed on to Component.
            end
            arguments (Output)
                obj        % Generator object.
            end
            obj@component.generator.abstract(index, parameter, varargin{:})
        end
    end
    methods        
        dx = fcn_dx(obj, t, x, V, u, param, omega0)
        I  = fcn_I(obj, t, x, V, u, param, omega0)        
        y  = fcn_Y(obj, t, x, V, param, omega0)
        M  = fcn_Mass(obj, t, x, V, u, param, omega0)                
    end

    methods        
        [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, c_V, c_I, r_P, r_Q)
    end

    methods (Static)        
        [cv_E, rv_P, rv_Iq, cv_I] = get_spring_node(rm_x, rm_V, rm_I, rm_u, rr_param)
        [Axx,Bxv,Bxu] = Jacobi_dx(t,x,V,u,param,omega0);
        [Cyx,Dyv] = Jacobi_Y(t,x,V,param,omega0);
        [Cix,Div,Diu] = Jacobi_I(t,x,V,u,param,omega0);
    end
end