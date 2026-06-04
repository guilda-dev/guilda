classdef impedance < component.load.abstract
    properties
        Z
    end

    properties(Constant)
        key      = "load-impedance";
        str_x    = [];
        str_u    = ["R";"X"];
        str_y    = [];
        str_para = [];
    end

    methods(Access={?Bus})
        function obj = impedance(index, ~, varargin)
            obj@component.load.abstract("RX"+index, varargin{:})
        end
    end

    methods        
        set_odefcn(obj,omega0)
    end
    
    methods        
        [cv_Xequilibrium, cv_Uequilibrium] = get_equilibrium(obj,c_V,c_I,r_P,r_Q)        
    end

    methods
        dx = fcn_dx(obj,t,x,V,I,u,param);
        I  = fcn_I(obj,t,x,V,I,u,param);
        y  = fcn_Y(obj,t,x,V,I,u,param);
        M  = fcn_Mass(obj,t,x,V,I,u,param);
    end
end