classdef park < component.generator.abstract
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
% M     d/dt omega = - D omega - P + Pmech
% Td_p  d/dt Eq    = - Eq - (Xd-Xdp){ Id + (Xdp-Xdpp)/(Xdp-Xls)^2 d/dt psid} + Vfield
% Tq_p  d/dt Ed    = - Ed + (Xq-Xqp){ Iq + (Xqp-Xqpp)/(Xqp-Xls)^2 d/dt psiq}
% Td_pp d/dt psiq  = -psiq - Ed -(Xqp-Xls)Iq
% Tq_pp d/dt psid  = -psid + Eq -(Xdp-Xls)Id
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
% Id  =  1/Xd_pp[ {(Xdpp-Xls)Eq+(Xdp-Xdpp)psid}/(Xdp-Xls) - Vq]
% Iq  = -1/Xq_pp[ {(Xqpp-Xls)Ed-(Xqp-Xqpp)psiq}/(Xqp-Xls) - Vd]
%

    properties(Constant)
        % State Variables
        sv_x = ["delta", "omega", "Eq", "Ed", "psid", "psiq"];
        % Input Variables
        sv_u = ["Pmech", "Vfield"];
        % Output Variables
        sv_y = ["omega", "Efd", "Vabs"];
        % Parameter Variables
        sv_p = ["Xd","Xq","Xd_p","Xq_p","Xd_pp","Xq_pp","Td_p","Tq_p","Td_pp","Tq_pp","X_ls","M","D"]
    end

    methods(Static)
        [dx,I,y] = dynamics(x, V, u, parameter)
    end
    methods
        M   = Mass(obj)
        xst = get_xequilibrium( obj, c_V, c_I)
        dx  = fcn_dx(obj, r_time, rv_x, c_V, rv_u)
        I   = fcn_I( obj, r_time, rv_x, c_V, rv_u)
        y   = fcn_y( obj, r_time, rv_x, c_V)
    end
    methods
        function [theta,rho] = get_Vterminal( obj, rv_x, c_V, rv_u) 
            arguments
                obj                                          
                rv_x   (:,1)  double = obj.x_equilibrium;  
                c_V    (1,1)  double = obj.V_equilibrium;  %#ok
                rv_u   (1,1)  double = obj.u_equilibrium;  %#ok
            end
            para = obj.tab_parameter.model;
            Xdp  = para.Xd_p;
            Xqp  = para.Xq_p;
            Xdpp = para.Xd_pp;
            Xqpp = para.Xq_pp;
            Xls  = para.X_ls;

            Eq    = rv_x(3);
            Ed    = rv_x(4);
            psiq  = rv_x(5);
            psid  = rv_x(6);

            terminal_q = ( (Xdpp-Xls)*Eq + (Xdp-Xdpp)*psid )/(Xdp-Xls);
            terminal_d = ( (Xqpp-Xls)*Ed - (Xqp-Xqpp)*psiq )/(Xqp-Xls);

            theta = rv_x(1);
            rho   = [terminal_q, -terminal_d];
        end
    end
    
end
