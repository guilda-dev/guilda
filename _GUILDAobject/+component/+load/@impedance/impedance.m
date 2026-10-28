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
        dx = fcn_dx(obj,t,x,V,I,u,param,omega0);
        I  = fcn_I(obj,t,x,V,I,u,param,omega0);
        y  = fcn_Y(obj,t,x,V,I,u,param,omega0);
        M  = fcn_Mass(obj,t,x,V,I,u,param,omega0);
    end

    methods (Static)
        [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0);
        [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0);
        [Cix,Div,Dii,Diu] = Jacobi_I(t,x,V,I,u,param,omega0);
    end
end