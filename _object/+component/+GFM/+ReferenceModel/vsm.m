classdef vsm < component.GFM.ReferenceModel.base
    properties(SetAccess=protected)
        P_st
        Vabs_st
    end
    
    methods
        function obj = vsm(params)
            if nargin==0
                params = readtable([mfilename("fullpath"),'.csv']);
            end
            obj.parameter = params(:,{'Jr','Dp','Kp','Ki','Mf'});
        end
        
        function nx = get_nx(~)
            nx = 3;
        end
        
        function nu = get_nu(~)
            nu = 0;
        end

        function tag = naming_state(~)
            tag = {'delta','omega','zeta'};
        end
        
        % State variables: theta and zeta (PI controller)
        function dx = get_dx(obj, t, x, u, v_dq, i_dq, vdc)%#ok
            p = obj.parameter;
            
            %delta = x(1);
            omega = x(2);
            %zeta = x(3);

            P = v_dq.' * i_dq;
            d_delta = obj.omega0 * omega;
            d_zeta = p.Ki/p.Mf*(obj.Vabs_st - norm(v_dq));
            d_omega = (obj.P_st - P - p.Dp * omega) / p.Jr;

            dx = [d_delta; d_omega; d_zeta];
        end
        
        function vdq_hat = calculate_vdq_hat(obj, t, x, u, v_dq, i_dq)%#ok
            p = obj.parameter;
            omega = x(2)+1;
            zeta = x(3);
            i_f = p.Kp/p.Mf * (obj.Vabs_st - norm(v_dq)) + zeta;
            vdq_hat = [0; 2 * i_f * omega];
        end

        function [delta,omega,Edq] = get_Vterminal(obj,x,V,I)
            delta = x(1);
            omega = x(2);
            %Convert "frequency deviation" to "frequency"
            omega = omega+1;%*obj.omega0;

            if nargout==3
                p = obj.converter.parameter;
                v_st = V'*I * p.L_g / (norm(V) * sin(delta - atan2(V(2),V(1)) )) ;
                Edq  = [0;v_st];
            else
                Edq=[];
            end
        end

        function [x_ref, u_ref] = set_equilibrium(obj,V,I,flag)
            Vabs = norm(V);
            Varg = atan2(V(2),V(1));

            
            P = V.' * I;
            Q = det([I,V]);
            p = obj.converter.parameter;

                
            % Calculation of steady state values of angle difference and converter terminal voltage

            delta_st = Varg + atan((P * p.L_g) / (Vabs^2 + Q * p.L_g)); %delta_st = angle(V(1)+1j*V(2));
            omega_st = 0;
            v_st = P * p.L_g / (Vabs * sin(delta_st - Varg));
            zeta_st = v_st / 2;

            x_ref = [delta_st; omega_st; zeta_st];
            u_ref = [];

            if strcmp(flag,'init')    
                obj.Vabs_st = norm(v_st);
                obj.P_st = P;
            end

        end
        
    end
    
end
