classdef vsm_component < base_class.component
    properties
        P_st
        V_st
        Jr
        Dp
        Kp
        Ki
    end
    
    methods
        function obj = vsm_component(vsm_params)
            %obj.omega_st = vsm_params{:, 'omega_st'};
            obj.Jr = vsm_params{:, 'Jr'};
            obj.Dp = vsm_params{:, 'Dp'};
            obj.Kp = vsm_params{:, 'Kp'};
            obj.Ki = vsm_params{:, 'Ki'};
        end
        
        function nx = get_nx(obj)
            nx = 3;
        end
        
        function nu = get_nu(obj)
            nu = 0;
        end

        function tag = naming_state(obj)
            tag = {'delta','zeta','omega'};
        end
        
        % State variables: theta and zeta (PI controller)
        function [dx,con] = get_dx_constraint(obj,t,x,V,I,u)
            delta = x(1);
            zeta = x(2);
            omega = x(3);

            P = V'*I;

            d_delta = obj.omega0 * (omega-1);
            d_zeta = obj.Ki * (obj.V_st - norm(V));
            d_omega = (obj.P_st - P + obj.Dp * (1-omega) ) / obj.Jr;

            i_f = obj.Kp * (obj.V_st - norm(V)) + zeta;
            vdq_hat = 2 * i_f * omega;
            vdq_hat = vdq_hat * exp(1j*delta);

            dx = [d_delta; d_zeta; d_omega];
            con = V - [real(vdq_hat); imag(vdq_hat)];
        end
        
        
        function xst = set_equilibrium(obj, V, I)
            Pst = real( V*conj(I) );
            obj.V_st = norm(V);
            obj.P_st = Pst;
            
            delta_st = angle(V) + atan((P * L_g) / (Vabs^2 + Q * L_g));
            omega_st = 1;
            zeta_st  = norm(V)/2;

            xst = [delta_st;zeta_st;omega_st];
            obj.x_equilibrium = xst;
            obj.V_equilibrium = V;
            obj.I_equilibrium = I;
        end
        
    end
    
end