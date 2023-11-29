classdef vsm < component.GFM.ReferenceModel.AbstractClass
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
        function [dx,con] = get_dx_constraint(obj, t, x, V, I, u)%#ok
            omega = x(2);
            p = obj.parameter;
            
            P = V.' * I;
            d_delta = obj.omega0 * omega;
            d_zeta = p.Ki/p.Mf*(obj.Vabs_st - norm(V));
            d_omega = (obj.P_st - P - p.Dp * omega) / p.Jr;

            dx = [d_delta; d_omega; d_zeta];
            con = [];
        end

        function [delta,omega,Vdq] = get_Vterminal(obj,x,V,I,u) %#ok
            delta = x(1);
            omega = x(2);
            zeta  = x(3);

            p = obj.parameter;
            i_f = p.Kp/p.Mf * (obj.Vabs_st - norm(V)) + zeta;
            Vdq = [0; 2 * (omega+1) * p.Mf * i_f];
        end

        function [x_ref, u_ref] = get_equilibrium(obj,V,I)
            Vabs = abs(V);
            Varg = angle(V);
            
            Power = V * conj(I);
            P = real(Power);
            Q = imag(Power);

            L_g  = obj.converter.parameter.L_g / obj.converter.Lbase;
                
            % Calculation of steady state values of angle difference and converter terminal voltage
                delta_st = Varg + atan((P * L_g) / (Vabs^2 + Q * L_g));
                omega_st = 0;
                v_st = P * L_g / (Vabs * sin(delta_st - Varg));
                zeta_st = v_st / 2;

            % Stack the calculated equilibrium points and steady-state inputs
                x_ref = [delta_st; omega_st; zeta_st];
                u_ref = [];

            % if strcmp(flag,'init')    
                obj.Vabs_st = norm(v_st);
                obj.P_st = P;
            % end

        end
        
    end
    
end
