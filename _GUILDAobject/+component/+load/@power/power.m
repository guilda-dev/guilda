classdef power < component.load.abstract
    
    properties
        PQ_st
    end

    properties(Constant)
        key      = "load-power";
        sv_x    = [];
        sv_u    = ["Pload","Qload"];
        sv_y    = [];
        sv_para = [];
        Prefix = "LP";
    end

    methods(Access={?Bus})
        function obj = power(index, ~, varargin)
            obj@component.load.abstract("PQ"+index, varargin{:})
        end
    end
    
    methods
        [rv_Xequilibrium, rv_Uequilibrium]  = get_equilibrium(obj, c_V, c_I);    
    end

    methods
        dx = fcn_dx(obj, t, x, V, I, u, param, omega0);
        I  = fcn_I(obj, t, x, V, I, u, param, omega0);
        y  = fcn_Y(obj, t, x, V, I, u, param, omega0);
        M  = fcn_Mass(obj, t, x, V, I, u, param, omega0);
    end

    methods       
        function PQ = getCompPQ(obj,x,V,u,param) %#ok
            PQ = u;
        end        
    end
    
    methods (Static)        
        [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0);
        [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0);
        [Cix,Div,Dii,Diu] = Jacobi_I(t,x,V,I,u,param,omega0);
    end
end
