classdef one_axis < component.generator.abstract
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Synchronous Generator Model (oen-Axis) %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% State  = [delta; omega; Eq]
% Input  = [Pmech; Vfield]
% Output = [omega; Efd; Vabs]
%
%
% Diff Fcn
% ==================================
% d/dt delta = omega0 omega
% d/dt omega = - D omega - P + Pmech
% d/dt Eq    = - Eq - (Xd-Xd_p)Id + Vfield
%
%
% Output Fcn
% ==================================
% omega = state(2)
% Efd   = Eq + (Xd-Xd_p)Iq
% Vabs  = abs(Vbus)
%
%
% Current to Grid
% ==================================
% Id  = 1/Xd_p(Eq-Vq)
% Iq  = 1/Xq   Vd
%

    properties(Constant)
        % State Variables
        xvars = ["delta", "omega", "Eq"];
        % Input Variables
        uvars = ["Pmech", "Vfield"];
        % Output Variables
        yvars = ["omega", "Efd","Vabs"];
        % Parameter Variables
        pvars = ["Xd","Xq","Xd_p","Td_p","M","D"];
    end

    methods(Static)
        [dx,I,y] = dynamics(obj, x, V, u, parameter,opt)
    end
    methods
        M   = Mass(obj)
        xst = get_xequilibrium(obj,c_V,c_I)
        dx  = fcn_dx(obj, r_time, rv_x, c_V, rv_u)
        I   = fcn_I( obj, r_time, rv_x, c_V, rv_u)
        y   = fcn_y( obj, r_time, rv_x, c_V)
    end
    methods
        function [theta,rho] = get_Vterminal( obj, rv_x, c_V, rv_u) 
            arguments
                obj                                          %#ok
                rv_x   (:,1)  double = obj.x_equilibrium;  
                c_V      (1,1)  double = obj.V_equilibrium;  %#ok
                rv_u   (1,1)  double = obj.u_equilibrium;  %#ok
            end
            theta = rv_x(1);
            rho   = rv_x(3);
        end
    end
end

