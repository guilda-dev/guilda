classdef impedance < component.load.abstract
    properties
        Z
    end

    properties(Constant)
        key      = "load-impedance";
        sv_x    = [];
        sv_u    = ["R";"X"];
        sv_y    = [];
        sv_para = [];
    end

    methods(Access={?Bus})
        function obj = impedance(index, ~, varargin)
            obj@component.load.abstract("RX"+index, varargin{:})
        end
    end

    methods        
        [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj,c_V,c_I,r_P,r_Q)        
    end

    methods
        dx = fcn_dx(obj,t,x,V,I,u,param);
        I  = fcn_I(obj,t,x,V,I,u,param);
        y  = fcn_Y(obj,t,x,V,I,u,param);
        M  = fcn_Mass(obj,t,x,V,I,u,param);
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