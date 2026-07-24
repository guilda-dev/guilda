classdef classical < component.generator.abstract

    properties (Constant)      
        key      = "gen-classical";
        sv_x    = ["delta";"omega"];        
        sv_u    = ["Pmech";"Vfield"];        
        sv_y    = "omega";        
        sv_para = ["M","D","Xd","Xq"]        
    end
    

    methods                
        [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, c_V, c_I)
    end        

    methods
        dx = fcn_dx(obj, t, x, V, I, u, param, omega0)
        I  = fcn_I(obj, t, x, V, I, u, param, omega0)        
        y  = fcn_Y(obj, t, x, V, I, u, param, omega0)
        M  = fcn_Mass(obj, t, x, V, I, u, param, omega0)        
    end

    methods
        function PQ = getCompPQ(obj,x,V,u,param) %#ok
            delta = x(1);
            E     = u(2);
            Vabs  = V(1);            

            Xd = param(3);
            Xq = param(4);    

            phi = delta - V(2);

            PQ = [(E * Vabs / Xd) * sin(phi) + 0.5 * Vabs^2 * (1/Xq - 1/Xd) * sin(2*phi);            
                  (E * Vabs / Xd) * cos(phi) - Vabs^2 * (cos(phi)^2 / Xd + sin(phi)^2 / Xq)];            
        end        
    end
    
    methods (Static)        
        [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0);
        [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0);
        [Cix,Div,Dii,Diu] = Jacobi_I(t,x,V,I,u,param,omega0);
    end
end