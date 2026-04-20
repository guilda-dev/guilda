classdef two_axis < component.generator.abstract
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Synchronous Generator Model (two-Axis) %
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
% d/dt Ed    = - Ed + (Xq-Xq_p)Id
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
% Iq  = 1/Xq_p(Vd-Ed)
%

    properties(Constant)
        % State Variables
        xvars = ["delta", "omega", "Eq", "Ed", "psid", "psiq"];
        % Input Variables
        uvars = ["Pmech", "Vfield"];
        % Output Variables
        yvars = ["omega", "Efd", "Vabs"];
        % Parameter Variables
        pvars = ["Xd","Xq","Xd_p","Xq_p","Td_p","Tq_p","M","D"];
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
            rho   = [rv_x(3), -rv_x(4)];
        end
    end
end