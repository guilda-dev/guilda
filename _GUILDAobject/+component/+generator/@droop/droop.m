classdef droop < component.generator.abstract
    properties (Constant)      
        key      = "gen-droop";
        sv_x    = "delta";        
        sv_u    = ["Pmech";"Vfield"];        
        sv_y    = string.empty(0,1)        
        sv_para = ["D","Xd","Xq"]        
    end
    methods        
        dx = fcn_dx(obj, t, x, V, I, u, param, omega0)
        I  = fcn_I(obj, t, x, V, I, u, param, omega0)        
        y  = fcn_Y(obj, t, x, V, I, u, param, omega0)
        M  = fcn_Mass(obj, t, x, V, I, u, param, omega0)                
    end

    methods        
        [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, c_V, c_I)
    end

    methods (Static)        
        [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0);
        [Cyx,Dyv,Dyi,Dyu] = Jacobi_y(t,x,V,I,u,param,omega0);
        [Cix,Div,Dii,Diu] = Jacobi_I(t,x,V,I,u,param,omega0);
    end
end