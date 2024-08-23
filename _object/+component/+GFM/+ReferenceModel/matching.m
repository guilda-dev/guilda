classdef matching < component.GFM.ReferenceModel.AbstractClass
    properties(SetAccess=protected)
        P_st
        Vabs_st
    end

    methods
        function obj = matching(params)
            if nargin==0
                params = readtable([mfilename("fullpath"),'.csv']);
            end
            obj.parameter = params(:,{'Ktheta','Kdc','Kp','Ki'});
        end

        function nx = get_nx(~)
            nx = 2;
        end

        function nu = get_nu(~)
            nu = 0;
        end

        function tag = naming_state(~)
            tag = {'delta','zeta'};
            %tag = {'delta','omega','zeta'};
        end

        % State variables: theta and zeta (PI controller)
        function [dx,con] = get_dx_constraint(obj, t, x, V, I, u,vdc, v_st)%#ok
            p = obj.parameter;
            %
            vdc_st = obj.params_dc_source.vdc_st / obj.converter.Vbase;
            %}

            Ktheta = 1/vdc_st;
            d_delta = Ktheta * vdc * obj.omega0 - obj.omega0;
            %
            %変更start
            delta = x(1);
            omega = Ktheta * vdc;
            L_g = obj.converter.parameter.L_g/obj.converter.Lbase;
            tensor = [ sin(delta),  cos(delta); ... 
                      -cos(delta),  sin(delta)] ;
            V_dq = tensor.' * V;
            I_dq =  tensor.' *    I;
            grid_tensor = [0  L_g*omega;
                           -L_g*omega 0]; 
            vdq = grid_tensor.' * I_dq  + V_dq;
            % d_zeta = p.Ki * ( obj.Vabs_st - norm(vdq));
            d_zeta = obj.Vabs_st - norm(vdq);
            %変更end
            %}

            dx = [d_delta; d_zeta];
            con = [];


        end

        function [delta,domega,Vdq] = get_Vterminal(obj,x,V,I,u,vdc,v_st)%#ok
            p = obj.parameter;
            vdc_st = obj.params_dc_source.vdc_st / obj.converter.Vbase;
            Ktheta = 1 / vdc_st;

            delta = x(1);
            domega = Ktheta * vdc - 1;
            zeta  = x(2);

            %
            %変更start
            omega = domega + 1;
            L_g = obj.converter.parameter.L_g/obj.converter.Lbase;
            tensor = [ sin(delta),  cos(delta); 
                      -cos(delta),  sin(delta)] ;
            V_dq = tensor.' * V;
            I_dq =  tensor.' *    I;
            grid_tensor = [0  L_g*omega;
                           -L_g*omega 0]; 
            vdq = grid_tensor.' * I_dq  + V_dq;
            %変更end
            %}

            mu = p.Kp * (obj.Vabs_st - norm(vdq)) + p.Ki * zeta;
            Vdq = [0; mu];

        end

        function [x_ref, u_ref] = get_equilibrium(obj,V,I)
            p = obj.parameter;
            Vabs = abs(V);
            Varg = angle(V);

            Power = V * conj(I);
            P = real(Power);
            Q = imag(Power);

            L_g = obj.converter.parameter.L_g / obj.converter.Lbase;

            % Calculation of steady state values of angle difference and converter terminal voltage
                

                delta_st = Varg + atan((P * L_g) / (Vabs^2 + Q * L_g));
                v_st = P * L_g / (Vabs * sin(delta_st - Varg));
                zeta_st = v_st / p.Ki;


            % Stack the calculated equilibrium points and steady-state inputs
                x_ref = [delta_st; zeta_st];
                u_ref = [];

            % if strcmp(flag,'init')    
                % obj.Vabs_st = norm(v_st);
                %{
                omega_st = 0;
                tensor = [sin(delta_st) -cos(delta_st);
                          cos(delta_st), sin(delta_st)];
                Vdq = tensor*V;
                Idq = tensor*I;
                vdq_st = [0, -(omega_st+1)*L_g;(omega_st+1)*L_g, 0]*Idq + Vdq;
                %}
                obj.Vabs_st = norm(v_st);

                obj.P_st = P;
            % end
        end

    end
end