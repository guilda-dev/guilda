classdef two_axis < component.generator.abstract
% Two-axis generator model: swing equation with d- and q-axis transient dynamics.
%
% The rotor follows the swing equation, and the internal voltages `Eq` and `Ed`
% follow the field circuit and the q-axis damper circuit.
%
% **Dynamic model**
% The model is a dynamical system with state $x$, input $u$ and output $y$, connected
% to its bus through the bus voltage $V$ and the current $I$ it injects.
%
% **State variables** $x$ (`sv_x`)
% - `delta` [rad]: Rotor angle in the network reference frame.
% - `omega` [pu]: Rotor speed deviation from the network frequency.
% - `Eq` [pu]: q-axis internal voltage behind the transient reactance.
% - `Ed` [pu]: d-axis internal voltage behind the transient reactance.
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
% - `Xd_p` [pu]: d-axis transient reactance.
% - `Xq` [pu]: q-axis synchronous reactance.
% - `Xq_p` [pu]: q-axis transient reactance.
% - `Td_p` [s]: d-axis open-circuit transient time constant.
% - `Tq_p` [s]: q-axis open-circuit transient time constant.
%
% **Equations** ($\omega_0$ is the network frequency `get_Hz()`; $V_d$, $V_q$, $I_d$, $I_q$
% are the bus voltage and current in the rotor dq frame; a prime marks a transient
% quantity, e.g. $X_d'$ is `Xd_p`)
% ```math
% \left\{
% \begin{aligned}
% \dot{\delta} &= 2\pi\omega_0\,\omega \\
% M\dot{\omega} &= -D\,\omega - P + P_\mathrm{mech} \\
% T_{d}'\dot{E}_q &= -E_q - (X_d - X_d')\,I_d + V_\mathrm{field} \\
% T_{q}'\dot{E}_d &= -E_d + (X_q - X_q')\,I_q
% \end{aligned}
% \right.
% ```
% with
% ```math
% I_d = \frac{E_q - V_q}{X_d'}, \quad I_q = \frac{V_d - E_d}{X_q'}, \quad P = V_d I_d + V_q I_q
% ```
%
% <@Examples>
% ```matlab
% net = PowerNetwork();
% bus = net.add_bus();
% gen = bus.add_component("gen-2axis", "P", 0.5);
% gen.sv_x                          % delta, omega, Eq, Ed
% gen.tab_parameter.dynamics        % M, D, Xd, Xd_p, ...
% gen.add_local_controller(controller.avr.AVR_ST1("avr1"))
% ```
%
% See also component.generator.abstract, Bus.add_component

    properties (Constant) % Model definition
        key = "gen-2axis";  % Model key that selects this class in `Bus.add_component`.
        sv_x = ["delta";"omega";"Eq";"Ed"];  % State names.
        sv_u = ["Pmech";"Vfield"];  % Input port names.
        sv_y = ["omega"];  % Output names read by local controllers.
        sv_para = ["M","D","Xd","Xd_p","Xq","Xq_p","Td_p","Tq_p"]  % Dynamic parameter names.
    end        
       
    methods        
        [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, c_V, c_I, r_P, r_Q)        

    end        

    methods
        dx = fcn_dx(obj, t, x, V, I, u, para, omega0)
        I  = fcn_I(obj, t, x, V, I, u, para, omega0)
        y  = fcn_Y(obj, t, x, V, I, u, para, omega0)
        M  = fcn_Mass(obj, t, x, V, I, u, para, omega0)        
    end

    methods (Static)        
        [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0);
        [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0);
        [Cix,Div,Dii,Diu] = Jacobi_I(t,x,V,I,u,param,omega0);
    end

end
