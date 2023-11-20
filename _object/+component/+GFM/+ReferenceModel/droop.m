classdef droop < component.GFM.ReferenceModel.base
    properties
        P_st
        Vabs_st
    end

    methods
        function obj = droop(para)
            if nargin==0
                c = class(obj);
                idx = find(c=='.',1,"last");
                para = eval([c(1:idx),'params.',c(idx+1:end),'();']);
            end
            obj.parameter = para(:,{'Dw','Kp','Ki'});
        end

        function nx = get_nx(~)
            nx = 2;
        end

        function nu = get_nu(~)
            nu = 0;
        end

        function tag = naming_state(~)
            tag = {'delta','zeta'};
        end

        % State variables: theta and zeta (PI controller)
        function dx = get_dx(obj, t, x, u, v_dq, i_dq, vdc)%#ok
            p = obj.parameter;
            P = v_dq.' * i_dq;
            
            d_delta = obj.omega0 * p.Dw * (obj.P_st - P);
            d_zeta = p.Ki * (obj.Vabs_st - norm(v_dq)); 

            dx = [d_delta;d_zeta];
        end

        function vdq_hat = calculate_vdq_hat(obj, t, x, u, v_dq, i_dq)%#ok
            p = obj.parameter;
            zeta = x(2);
            vdq_hat = [2 * (p.Kp * (obj.Vabs_st - norm(v_dq)) + zeta); 0];
        end

        function [delta,omega] = get_angle(obj,x,V,I)
            delta = x(1);
            omega = 1 + obj.parameter.Dw * (obj.P_st - V.'*I);
        end

        function [x_ref, u_ref, Vbus_dq, Ibus_dq] = set_equilibrium(obj,V,I,flag)
            Vabs = norm(V);
            Varg = atan2(V(2),V(1));
            
            P = V.' * I;
            Q = det([I,V]);
            p = obj.converter.parameter;

                
            % Calculation of steady state values of angle difference and converter terminal voltage

            delta_st = Varg + atan((P * p.L_g) / (Vabs^2 + Q * p.L_g)); %delta_st = angle(V(1)+1j*V(2));
            v_st = P * p.L_g / (Vabs * sin(delta_st - Varg)); %v_st = norm(V);
            zeta_st = v_st / 2;

            x_ref = [delta_st; zeta_st];
            u_ref = [];

            if strcmp(flag,'init')
                obj.Vabs_st = norm(v_st);
                obj.P_st = V.'*I;
            end

            % Calculate equilibrium of "vdq,idq"
            tensor = [ cos(delta_st), sin(delta_st);...
                      -sin(delta_st), cos(delta_st)]; 
            Vbus_dq = [v_st;0]; % equal >> Vbus_dq = tensor * V 
            Ibus_dq = tensor * I;
        end

    end

end


        
        
        
        