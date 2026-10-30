classdef two_axis < component.generator.abstract
% Two-axis generator model: swing equation with d- and q-axis transient dynamics.
%
% The rotor follows the swing equation, and the internal voltages `Eq` and `Ed`
% follow the field circuit and the q-axis damper circuit.
%
% **States** (`sv_x`)
% - `delta` [rad]: Rotor angle in the network reference frame.
% - `omega` [pu]: Rotor speed deviation from the network frequency.
% - `Eq` [pu]: q-axis internal voltage behind the transient reactance.
% - `Ed` [pu]: d-axis internal voltage behind the transient reactance.
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
% - `Xq` [pu]: q-axis synchronous reactance.
% - `Xq_p` [pu]: q-axis transient reactance.
% - `Td_p` [s]: d-axis open-circuit transient time constant.
% - `Tq_p` [s]: q-axis open-circuit transient time constant.
%
% **Equations** (`omega0` is the network frequency `r_Hz`; `Vd`, `Vq`, `Id`, `Iq`
% are the bus voltage and current in the rotor dq frame)
% ```
% d(delta)/dt   = 2*pi*omega0*omega
% M*d(omega)/dt = -D*omega - P + Pmech
% Td_p*d(Eq)/dt = -Eq - (Xd - Xd_p)*Id + Vfield
% Tq_p*d(Ed)/dt = -Ed + (Xq - Xq_p)*Iq
% Id = (Eq - Vq)/Xd_p,  Iq = (Vd - Ed)/Xq_p,  P = Vd*Id + Vq*Iq
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
        key      = "gen-2axis";                                    % Model key that selects this class in `Bus.add_component`.
        sv_x    = ["delta";"omega";"Eq";"Ed"];                     % State names.
        sv_u    = ["Pmech";"Vfield"];                              % Input port names.
        sv_y    = ["omega"];                                       % Output names read by local controllers.
        sv_para = ["M","D","Xd","Xd_p","Xq","Xq_p","Td_p","Tq_p"]  % Dynamic parameter names.
    end        
       
    methods        
        [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, c_V, c_I, r_P, r_Q)        

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
            % This implementation reads `V` as `[real; imag]`, unlike the other generator models.
            %
            % See also fcn_I
            arguments (Output)
                PQ % [pu] Active and reactive power `[P; Q]` injected into the bus.
            end

            c_V = [1,1j]*V;
       
            Xdp  = para(4);
            Xqp  = para(6);
           
            delta = x(1);
            Eq    = x(3);
            Ed    = x(4);
            
            Vdq = exp(1j*delta) * conj(c_V);
            Vd  = imag(Vdq);
            Vq  = real(Vdq);
            
            Id  = 1/Xdp * (Eq-Vq); 
            Iq  = 1/Xqp  *(Vd-Ed);          
                    
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