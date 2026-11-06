classdef classical < component.generator.abstract
% Classical generator model: swing equation with a constant internal voltage.
%
% The rotor follows the swing equation. The internal voltage is the field input
% `Vfield` behind the reactances `Xd` and `Xq`; the model has no flux dynamics.
%
% **Dynamic model**
% The model is a dynamical system with state $x$, input $u$ and output $y$, connected
% to its bus through the bus voltage $V$ and the current $I$ it injects.
%
% **State variables** $x$ (`sv_x`)
% - `delta` [rad]: Rotor angle in the network reference frame.
% - `omega` [pu]: Rotor speed deviation from the network frequency.
%
% **Input signals** $u$ (`sv_u`; the ports driven by local controllers)
% - `Pmech` [pu]: Mechanical power (governor output).
% - `Vfield` [pu]: Field voltage (AVR output).
%
% **Output signals** $y$ (`sv_y`; read by local controllers)
% - `omega` [pu]: Rotor speed deviation from the network frequency.
%
% **Parameters** (`sv_para`, the columns of `tab_parameter.dynamics`)
% - `M` [s]: Inertia constant (`M = 2H`).
% - `D` [pu]: Damping coefficient.
% - `Xd` [pu]: d-axis synchronous reactance.
% - `Xq` [pu]: q-axis synchronous reactance.
%
% **Equations** ($\omega_0$ is the network frequency `get_Hz()`; $V_d$, $V_q$, $I_d$, $I_q$
% are the bus voltage and current in the rotor dq frame)
% ```math
% \left\{
% \begin{aligned}
% \dot{\delta} &= 2\pi\omega_0\,\omega \\
% M\dot{\omega} &= -D\,\omega - P + P_\mathrm{mech}
% \end{aligned}
% \right.
% ```
% with
% ```math
% I_d = \frac{V_\mathrm{field} - V_q}{X_d}, \quad I_q = \frac{V_d}{X_q}, \quad P = V_d I_d + V_q I_q
% ```
%
% <@Examples>
% ```matlab
% net = PowerNetwork();
% bus = net.add_bus();
% gen = bus.add_component("gen-classical", "P", 0.5);
% gen.sv_x                          % delta, omega
% gen.tab_parameter.dynamics        % M, D, Xd, Xq
% gen.add_local_controller("avr-ST1")
% ```
%
% See also component.generator.abstract, Bus.add_component

    properties (Constant) % Model definition
        key = "gen-classical";         % Model key that selects this class in `Bus.add_component`.
        sv_x = ["delta";"omega"];      % State names.
        sv_u = ["Pmech";"Vfield"];     % Input port names.
        sv_y = "omega";                % Output names read by local controllers.
        sv_para = ["M","D","Xd","Xq"]  % Dynamic parameter names.
    end

    methods                
        [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, c_V, c_I, r_P, r_Q)
    end        

    methods
        dx = fcn_dx(obj, t, x, V, I, u, param, omega0)
        I  = fcn_I(obj, t, x, V, I, u, param, omega0)        
        y  = fcn_Y(obj, t, x, V, I, u, param, omega0)
        M  = fcn_Mass(obj, t, x, V, I, u, param, omega0)        
    end

    methods (Static)        
        [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0);
        [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0);
        [Cix,Div,Dii,Diu] = Jacobi_I(t,x,V,I,u,param,omega0);
    end
end
