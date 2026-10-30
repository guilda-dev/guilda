classdef one_axis < component.generator.abstract
% One-axis generator model: swing equation with q-axis transient dynamics.
%
% The rotor follows the swing equation and the q-axis internal voltage `Eq`
% follows the field circuit (flux decay model).
%
% **States** (`sv_x`)
% - `delta` [rad]: Rotor angle in the network reference frame.
% - `omega` [pu]: Rotor speed deviation from the network frequency.
% - `Eq` [pu]: q-axis internal voltage behind the transient reactance.
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
% - `Xq` [pu]: q-axis synchronous reactance.
% - `Xd_p` [pu]: d-axis transient reactance.
% - `Td_p` [s]: d-axis open-circuit transient time constant.
%
% **Equations** (`omega0` is the network frequency `r_Hz`; `Vd`, `Vq`, `Id`, `Iq`
% are the bus voltage and current in the rotor dq frame)
% ```
% d(delta)/dt   = 2*pi*omega0*omega
% M*d(omega)/dt = -D*omega - P + Pmech
% Td_p*d(Eq)/dt = -Eq - (Xd - Xd_p)*Id + Vfield
% Id = (Eq - Vq)/Xd_p,  Iq = Vd/Xq,  P = Vd*Id + Vq*Iq
% ```
%
% <@Examples>
% ```matlab
% net = PowerNetwork();
% bus = net.add_bus();
% gen = bus.add_component("gen-1axis", "P", 0.5);
% gen.sv_x                          % delta, omega, Eq
% gen.tab_parameter.dynamics        % M, D, Xd, Xq, ...
% gen.add_local_controller(controller.avr.AVR_ST1("avr1"))
% ```
%
% See also component.generator.abstract, Bus.add_component

    properties (Constant) % Model definition
        key      = "gen-1axis";                      % Model key that selects this class in `Bus.add_component`.
        sv_x    = ["delta";"omega";"Eq"];            % State names.
        sv_u    = ["Pmech";"Vfield"];                % Input port names.
        sv_y    = ["omega"];                         % Output names read by local controllers.
        sv_para = ["M";"D";"Xd";"Xq";"Xd_p";"Td_p"]  % Dynamic parameter names.
    end        

    methods        
        [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, c_V, c_I, r_P, r_Q)       
    end        
    methods
        dx = fcn_dx(obj,t,x,V,I,u,para,omega0)
        I  = fcn_I(obj,t,x,V,I,u,para,omega0)
        y  = fcn_Y(obj,t,x,V,I,u,para,omega0)
        M  = fcn_Mass(obj,t,x,V,I,u,para,omega0)
    end
    methods (Static)        
        [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0);
        [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0);
        [Cix,Div,Dii,Diu] = Jacobi_I(t,x,V,I,u,param,omega0);
    end

    methods
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
            
            Xq = para(4);
            Xdp  = para(5);     

            % State
            delta = x(1);            
            Eq    = x(3);                            

            % dq-trans
            Vdq = exp(1j*delta) * conj(V);
            Vd  = imag(Vdq);
            Vq  = real(Vdq);

            % Current    
            Id = Vd/Xq;
            Iq = (Eq - Vq)/Xdp;
            PQ = [Vd*Id + Vq*Iq;
                  Vq*Id - Vd*Iq];

        end
    end
end