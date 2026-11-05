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
        key = "gen-droop";  % Model key that selects this class in `Bus.add_component`.
        sv_x = "delta";  % State names.
        sv_u = ["Pmech";"Vfield"];  % Input port names.
        sv_y = string.empty(0,1)  % Output names read by local controllers.
        sv_para = ["D","Xd","Xq"]  % Dynamic parameter names.
    end
    methods        
        dx = fcn_dx(obj, t, x, V, I, u, param, omega0)
        I  = fcn_I(obj, t, x, V, I, u, param, omega0)        
        y  = fcn_Y(obj, t, x, V, I, u, param, omega0)
        M  = fcn_Mass(obj, t, x, V, I, u, param, omega0)                
    end

    methods        
        [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, c_V, c_I, r_P, r_Q)
    end

    methods (Static)        
        [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0);
        [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0);
        [Cix,Div,Dii,Diu] = Jacobi_I(t,x,V,I,u,param,omega0);
    end
end