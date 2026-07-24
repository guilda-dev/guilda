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
        Axx = getJacobiAxx(t, x, V, I, u, param, omega0)
        Bxv = getJacobiBxv(t, x, V, I, u, param, omega0)
        Bxi = getJacobiBxi(t, x, V, I, u, param, omega0)
        Bxu = getJacobiBxu(t, x, V, I, u, param, omega0)
        Cyx = getJacobiCyx(t, x, V, I, u, param, omega0)
        Dyv = getJacobiDyv(t, x, V, I, u, param, omega0)
        Dyi = getJacobiDyi(t, x, V, I, u, param, omega0)
        Dyu = getJacobiDyu(t, x, V, I, u, param, omega0)
        Cix = getJacobiCix(t, x, V, I, u, param, omega0)
        Div = getJacobiDiv(t, x, V, I, u, param, omega0)
        Dii = getJacobiDii(t, x, V, I, u, param, omega0)
        Diu = getJacobiDiu(t, x, V, I, u, param, omega0)
    end
end