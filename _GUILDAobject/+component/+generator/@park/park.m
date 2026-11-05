classdef park < component.generator.abstract
% Park generator model: swing equation with transient and subtransient dynamics.
%
% The rotor follows the swing equation. The transient voltages `Eq`, `Ed` and the
% subtransient flux linkages `psiq`, `psid` follow the field and damper circuits
% (sixth-order model).
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
% - `psiq` [pu]: q-axis subtransient flux linkage.
% - `psid` [pu]: d-axis subtransient flux linkage.
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
% - `Xd_pp` [pu]: d-axis subtransient reactance.
% - `Xq` [pu]: q-axis synchronous reactance.
% - `Xq_p` [pu]: q-axis transient reactance.
% - `Xq_pp` [pu]: q-axis subtransient reactance.
% - `Td_p` [s]: d-axis open-circuit transient time constant.
% - `Td_pp` [s]: d-axis open-circuit subtransient time constant.
% - `Tq_p` [s]: q-axis open-circuit transient time constant.
% - `Tq_pp` [s]: q-axis open-circuit subtransient time constant.
% - `X_ls` [pu]: Armature leakage reactance.
%
% **Equations** ($\omega_0$ is the network frequency `get_Hz()`; $V_d$, $V_q$, $I_d$, $I_q$
% are the bus voltage and current in the rotor dq frame; one and two primes mark transient
% and subtransient quantities, e.g. $X_d'$ is `Xd_p` and $X_d''$ is `Xd_pp`)
% ```math
% \left\{
% \begin{aligned}
% \dot{\delta} &= 2\pi\omega_0\,\omega \\
% M\dot{\omega} &= -D\,\omega - P + P_\mathrm{mech} \\
% T_{d}'\dot{E}_q &= -E_q - (X_d - X_d')\left(I_d + \frac{X_d' - X_d''}{(X_d' - X_{ls})^2}\,T_{d}''\dot{\psi}_d\right) + V_\mathrm{field} \\
% T_{q}'\dot{E}_d &= -E_d + (X_q - X_q')\left(I_q + \frac{X_q' - X_q''}{(X_q' - X_{ls})^2}\,T_{q}''\dot{\psi}_q\right) \\
% T_{q}''\dot{\psi}_q &= -\psi_q - E_d - (X_q' - X_{ls})\,I_q \\
% T_{d}''\dot{\psi}_d &= -\psi_d + E_q - (X_d' - X_{ls})\,I_d
% \end{aligned}
% \right.
% ```
% with
% ```math
% \begin{aligned}
% I_d &= \frac{1}{X_d''}\left(\frac{(X_d'' - X_{ls})E_q + (X_d' - X_d'')\psi_d}{X_d' - X_{ls}} - V_q\right) \\
% I_q &= \frac{1}{X_q''}\left(V_d - \frac{(X_q'' - X_{ls})E_d - (X_q' - X_q'')\psi_q}{X_q' - X_{ls}}\right) \\
% P &= V_d I_d + V_q I_q
% \end{aligned}
% ```
%
% <@Examples>
% ```matlab
% net = PowerNetwork();
% bus = net.add_bus();
% gen = bus.add_component("gen-park", "P", 0.5);
% gen.sv_x                          % delta, omega, Eq, Ed, psiq, psid
% gen.tab_parameter.dynamics        % M, D, Xd, Xd_p, ...
% gen.add_local_controller(controller.avr.AVR_ST1("avr1"))
% ```
%
% See also component.generator.abstract, Bus.add_component

    properties (Constant) % Model definition
        key = "gen-park";  % Model key that selects this class in `Bus.add_component`.
        sv_x = ["delta";"omega";"Eq";"Ed";"psiq";"psid"];  % State names.
        sv_u = ["Pmech";"Vfield"];  % Input port names.
        sv_y = ["omega"];  % Output names read by local controllers.
        sv_para = ["M","D","Xd","Xd_p","Xd_pp","Xq","Xq_p","Xq_pp","Td_p","Td_pp","Tq_p","Tq_pp","X_ls"]  % Dynamic parameter names.
    end        
        
    methods        
        [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, c_V, c_I, r_P, r_Q)        

        function PQ = getCompPQ(obj,x,V,u,para) %#ok
            % Calculate the power that the generator injects into the bus.
            %
            % Used by the continuation power flow (`f_PQ2Bus`).
            %
            % See also fcn_I
            arguments (Input)
                obj
                x    double  % State vector in the order of `sv_x`.
                V    double  % Bus voltage as `[abs; angle]` in [pu] and [rad].
                u    double  % Input vector in the order of `sv_u`.
                para double  % Dynamic parameters in the order of `sv_para`.
            end
            arguments (Output)
                PQ % [pu] Active and reactive power `[P; Q]` injected into the bus.
            end
            
            V = V(1) * exp(1j*V(2));
                 
            Xdp  = para(4);
            Xdpp = para(5);     
            Xqp  = para(7);    
            Xqpp = para(8);
            Xls  = para(13);    
            
            % State
            delta = x(1);            
            Eq    = x(3);
            Ed    = x(4);
            psiq  = x(5);
            psid  = x(6);                        
            
            % dq-trans
            Vdq = exp(1j*delta) * conj(V);
            Vd  = imag(Vdq);
            Vq  = real(Vdq);
            
            % Current    
            Id = 1/Xdpp * (( (Xdpp-Xls)*Eq + (Xdp-Xdpp)*psid )/(Xdp-Xls) - Vq); 
            Iq = 1/Xqpp * (Vd - ( (Xqpp-Xls)*Ed - (Xqp-Xqpp)*psiq )/(Xqp-Xls));
            PQ = [Vd*Id + Vq*Iq;
                  Vq*Id - Vd*Iq];
                       
        end
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