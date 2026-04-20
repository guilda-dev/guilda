classdef classical < component.generator.abstract
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Synchronous Generator Model (Classical) %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% State  = [delta; omega]
% Input  = [Pmech; Vfield]
% Output = [omega; Vabs]
%
%
% Diff Fcn
% ==================================
% d/dt delta = omega0 omega
% d/dt omega = - D omega - P + Pmech
%
%
% Output Fcn
% ==================================
% omega = state(2)
% Vabs  = abs(Vbus)
%
%
% Current to Grid
% ==================================
% Id  = 1/Xd(Vfd-Vq)
% Iq  = 1/Xq Vd
%

    properties(Constant)
        % State Variables
        xvars = ["delta", "omega"];
        % Input Variables
        uvars = ["Pmech", "Vfield"];
        % Output Variables
        yvars = ["omega", "Vabs"];
        % Parameter Variables
        pvars = ["Xd","Xq","M","D"];
    end

    methods(Static)
        [dx,I,y] = dynamics(obj, x, V, u, parameter,opt)
    end
    methods
        M   = Mass(obj)
        xst = get_xequilibrium(obj,c_V,c_I,parameter)
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
                rv_u   (1,1)  double = obj.u_equilibrium;  
            end
            theta = rv_x(1);
            rho   = rv_u(2);
        end
    end
end
        


