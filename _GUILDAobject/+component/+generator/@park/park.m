classdef park < component.generator.abstract
% Park generator model: swing equation with transient and subtransient dynamics.
%
% The rotor follows the swing equation. The transient voltages `Eq`, `Ed` and the
% subtransient flux linkages `psiq`, `psid` follow the field and damper circuits
% (sixth-order model).
%
% **States** (`sv_x`)
% - `delta` [rad]: Rotor angle in the network reference frame.
% - `omega` [pu]: Rotor speed deviation from the network frequency.
% - `Eq` [pu]: q-axis internal voltage behind the transient reactance.
% - `Ed` [pu]: d-axis internal voltage behind the transient reactance.
% - `psiq` [pu]: q-axis subtransient flux linkage.
% - `psid` [pu]: d-axis subtransient flux linkage.
%
% **Inputs** (`sv_u`, the ports for local controllers)
% - `Pmech` [pu]: Mechanical power (governor output).
% - `Vfield` [pu]: Field voltage (AVR output).
%
% **Outputs** (`sv_y`)
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
% **Equations** (`omega0` is the network frequency `r_Hz`; `Vd`, `Vq`, `Id`, `Iq`
% are the bus voltage and current in the rotor dq frame)
% ```
% d(delta)/dt      = 2*pi*omega0*omega
% M*d(omega)/dt    = -D*omega - P + Pmech
% Td_p*d(Eq)/dt    = -Eq - (Xd - Xd_p)*(Id + (Xd_p - Xd_pp)/(Xd_p - X_ls)^2*dpsid) + Vfield
% Tq_p*d(Ed)/dt    = -Ed + (Xq - Xq_p)*(Iq + (Xq_p - Xq_pp)/(Xq_p - X_ls)^2*dpsiq)
% Tq_pp*d(psiq)/dt = dpsiq = -psiq - Ed - (Xq_p - X_ls)*Iq
% Td_pp*d(psid)/dt = dpsid = -psid + Eq - (Xd_p - X_ls)*Id
% Id = (((Xd_pp - X_ls)*Eq + (Xd_p - Xd_pp)*psid)/(Xd_p - X_ls) - Vq)/Xd_pp
% Iq = (Vd - ((Xq_pp - X_ls)*Ed - (Xq_p - Xq_pp)*psiq)/(Xq_p - X_ls))/Xq_pp
% P  = Vd*Id + Vq*Iq
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
        key      = "gen-park";                                                                            % Model key that selects this class in `Bus.add_component`.
        sv_x    = ["delta";"omega";"Eq";"Ed";"psiq";"psid"];                                              % State names.
        sv_u    = ["Pmech";"Vfield"];                                                                     % Input port names.
        sv_y    = ["omega"];                                                                              % Output names read by local controllers.
        sv_para = ["M","D","Xd","Xd_p","Xd_pp","Xq","Xq_p","Xq_pp","Td_p","Td_pp","Tq_p","Tq_pp","X_ls"]  % Dynamic parameter names.
    end        
        
    methods        
        [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, c_V, c_I)        

        function PQ = getCompPQ(obj,x,V,u,para) %#ok
            % Calculate the power that the generator injects into the bus.
            %
            % Used by the continuation power flow (`f_PQ2Bus`).
            %
            % Inputs:
            % - `x`: state vector in the order of `sv_x`.
            % - `V`: bus voltage as `[abs; angle]` in [pu] and [rad].
            % - `u`: input vector in the order of `sv_u`.
            % - `para`: dynamic parameters in the order of `sv_para`.
            %
            % See also fcn_I
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