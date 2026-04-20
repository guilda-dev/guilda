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
        cv_Y = function_out(obj,num,cv_X,c_V,c_I,r_P,r_Q,para)
        [cv_Xequilibrium, cv_Uequilibrium]        = get_equilibrium(obj, c_V, c_I, r_P, r_Q)
        [rm_Mass, fv_odeDiff, fv_odeOut, fv_odeI] = get_odeFunction(obj,sv_x,s_V,sv_u,sr_para)
    end
end