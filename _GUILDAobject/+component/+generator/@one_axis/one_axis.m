classdef one_axis < component.generator.abstract
    properties (Constant)        
        key      = "gen-1axis";
        sv_x    = ["delta";"omega";"Eq"];        
        sv_u    = ["Pmech";"Vfield"];        
        sv_y    = ["omega"];        
        sv_para = ["M";"D";"Xd";"Xq";"Xd_p";"Td_p"]
    end        

    methods        
        [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, c_V, c_I, r_P, r_Q)       
    end        
    methods
        dx = fcn_dx(obj,t,x,V,I,u,para,omega0)
        I  = fcn_I(obj,t,x,V,I,u,para,omega0)
        y  = fcn_Y(obj,t,x,V,I,u,para,omega0)
        M  = fcn_Mass(obj,t,x,V,I,u,para,omega0)
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