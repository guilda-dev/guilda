classdef base < LocalController
    properties (SetAccess=protected, Hidden)
        key      
        str_x    
        str_u    
        str_y    
        str_para 
    end    
    methods
        function obj = base(tag)
            arguments                            
                tag = "base"
            end            
            obj@LocalController("CP"+tag)                                                            

        end        
        function set_odefcn(obj, omega0) %#ok            
            obj.fv_odeDiff = @(t, x, V, u) [];
            obj.rm_odeMass = @(t, x, V, u) [];
            obj.fv_odeY    = @(t, x, V, u) 0;

            obj.JacobiAxx = @(t, x, V, u) [];
            obj.JacobiBxv = @(t, x, V, u) [];
            obj.JacobiBxu = @(t, x, V, u) [];

            obj.JacobiCyx = @(t, x, V, u) [];
            obj.JacobiDyv = @(t, x, V, u) [];
            obj.JacobiDyu = @(t, x, V, u) [];

        end
        function get_equilibrium(obj, V, u) %#ok
            obj.cv_Xequilibrium = [];
            obj.cv_Uequilibrium = [];
        end
    end

    methods
        dx = fcn_dx(obj, t, x, V, u, para, omega0)
        y  = fcn_y(obj, t, x, V, u, para, omega0)
        M  = fcn_Mass(obj, t, x, V, u, para, omega0)
    end
end