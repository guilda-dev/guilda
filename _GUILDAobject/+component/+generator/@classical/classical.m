classdef classical < component.generator.abstract

    properties (Constant)      
        key      = "gen-classical";
        str_x    = ["delta";"omega"];        
        str_u    = ["Pmech";"Vfield"];        
        str_y    = "omega";        
        str_para = ["M","D","Xd","Xq"]        
    end
    

    methods        
        function set_odefcn(obj, omega0)                                
            tab_para = obj.tab_parameter;      
            array    = tab_para.dynamics{:,obj.str_para};
            
            obj.JacobiAxx = @(t,x,V,I,u) getJacobiAxx(t, x, V, I, u, array, omega0);
            obj.JacobiBxv = @(t,x,V,I,u) getJacobiBxv(t, x, V, I, u, array, omega0);
            obj.JacobiBxi = @(t,x,V,I,u) getJacobiBxi(t, x, V, I, u, array, omega0);
            obj.JacobiBxu = @(t,x,V,I,u) getJacobiBxu(t, x, V, I, u, array, omega0);

            obj.JacobiCyx = @(t,x,V,I,u) getJacobiCyx(t, x, V, I, u, array, omega0);
            obj.JacobiDyv = @(t,x,V,I,u) getJacobiDyv(t, x, V, I, u, array, omega0);
            obj.JacobiDyi = @(t,x,V,I,u) getJacobiDyi(t, x, V, I, u, array, omega0);
            obj.JacobiDyu = @(t,x,V,I,u) getJacobiDyu(t, x, V, I, u, array, omega0);         
            
            obj.JacobiCix = @(t,x,V,I,u) getJacobiCix(t, x, V, I, u, array, omega0);
            obj.JacobiDiv = @(t,x,V,I,u) getJacobiDiv(t, x, V, I, u, array, omega0);
            obj.JacobiDii = @(t,x,V,I,u) getJacobiDii(t, x, V, I, u, array, omega0);
            obj.JacobiDiu = @(t,x,V,I,u) getJacobiDiu(t, x, V, I, u, array, omega0);         

            obj.rm_odeMass = @(t,x,V,I,u) obj.fcn_Mass(t, x, V, I, u, array, omega0);
            obj.fv_odeDiff = @(t,x,V,I,u) obj.fcn_dx(t, x, V, I, u, array, omega0);
            obj.fv_odeI    = @(t,x,V,I,u) obj.fcn_I(t, x, V, I, u, array, omega0);
            obj.fv_odeY    = @(t,x,V,I,u) obj.fcn_Y(t, x, V, I, u, array, omega0);
        end
        
        [cv_Xequilibrium, cv_Uequilibrium] = get_equilibrium(obj, c_V, c_I)
    end        

    methods
        dx = fcn_dx(obj, t, x, V, I, u, param, omega0)
        I  = fcn_I(obj, t, x, V, I, u, param, omega0)        
        y  = fcn_Y(obj, t, x, V, I, u, param, omega0)
        M  = fcn_Mass(obj, t, x, V, I, u, param, omega0)        
    end

    methods
        function PQG = getCompPQG(obj,x,V,u,param) %#ok
            delta = x(1);
            E     = u(2);
            Vabs  = abs(V);            

            Xd = param(3);
            Xq = param(4);    

            phi = delta - angle(V);

            PQG = [(E * Vabs / Xd) * sin(phi) + 0.5 * Vabs^2 * (1/Xq - 1/Xd) * sin(2*phi);            
                   (E * Vabs / Xd) * cos(phi) - Vabs^2 * (cos(phi)^2 / Xd + sin(phi)^2 / Xq)];            
        end

        function PQL = getCompPQL(obj,x,V,u,param) %#ok
            PQL = zeros(2,1);
        end        
    end
end