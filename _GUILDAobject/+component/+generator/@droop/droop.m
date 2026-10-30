classdef droop < component.generator.abstract
% Droop generator model: first-order angle dynamics without inertia.
%
% The rotor inertia is neglected and the angle changes in proportion to the power
% mismatch (droop characteristic). The internal voltage is the field input `Vfield`.
%
% **States** (`sv_x`)
% - `delta` [rad]: Rotor angle in the network reference frame.
%
% **Inputs** (`sv_u`, the ports for local controllers)
% - `Pmech` [pu]: Mechanical power (governor output).
% - `Vfield` [pu]: Field voltage (AVR output).
%
% **Outputs** (`sv_y`)
% - none
%
% **Parameters** (`sv_para`, the columns of `tab_parameter.dynamics`)
% - `D` [pu]: Damping coefficient.
% - `Xd` [pu]: d-axis synchronous reactance.
% - `Xq` [pu]: q-axis synchronous reactance.
%
% **Equations** (`omega0` is the network frequency `r_Hz`; `Vd`, `Vq`, `Id`, `Iq`
% are the bus voltage and current in the rotor dq frame)
% ```
% D/(2*pi*omega0)*d(delta)/dt = Pmech - P
% Id = (Vfield - Vq)/Xd,  Iq = Vd/Xq,  P = Vd*Id + Vq*Iq
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
        key      = "gen-droop";        % Model key that selects this class in `Bus.add_component`.
        sv_x    = "delta";             % State names.
        sv_u    = ["Pmech";"Vfield"];  % Input port names.
        sv_y    = string.empty(0,1)    % Output names read by local controllers.
        sv_para = ["D","Xd","Xq"]      % Dynamic parameter names.
    end
    methods        
        dx = fcn_dx(obj, t, x, V, I, u, param, omega0)
        I  = fcn_I(obj, t, x, V, I, u, param, omega0)        
        y  = fcn_Y(obj, t, x, V, I, u, param, omega0)
        M  = fcn_Mass(obj, t, x, V, I, u, param, omega0)                
    end

    methods        
        [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, c_V, c_I)
    end

    methods (Static)        
        [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0);
        [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0);
        [Cix,Div,Dii,Diu] = Jacobi_I(t,x,V,I,u,param,omega0);
    end
end