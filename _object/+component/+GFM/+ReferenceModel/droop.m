classdef droop < component.GFM.ReferenceModel.AbstractClass
    properties
        P_st
        Vabs_st
    end

    methods
        function obj = droop(para)
            if nargin==0
                para = readtable([mfilename("fullpath"),'.csv']);
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
        function [dx,con] = get_dx_constraint(obj, t, x, V, I, u)%#ok
            p = obj.parameter;
            P = V.' * I;
            
            d_delta = obj.omega0 * p.Dw * (obj.P_st - P);
            d_zeta = p.Ki * (obj.Vabs_st - norm(V)); 

            dx = [d_delta;d_zeta];
            con = [];
        end

        function [delta,omega,Vdq] = get_Vterminal(obj,x,V,I,u) %#ok
            delta = x(1);
            omega = obj.parameter.Dw * (obj.P_st - V.'*I);
            zeta  = x(2);

            p = obj.parameter;
            Vdq = [ 0; 2*(p.Kp*(obj.Vabs_st-norm(V))+zeta)];
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
                v_st = P * L_g / (Vabs * sin(delta_st - Varg));
                zeta_st = v_st / 2;

            % Stack the calculated equilibrium points and steady-state inputs
                x_ref = [delta_st; zeta_st];
                u_ref = [];

            % if strcmp(flag,'init')
                obj.Vabs_st = norm(v_st);
                obj.P_st = V.'*I;
            % end
        end

    end

end


        
        
        
        