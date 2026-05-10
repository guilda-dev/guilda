classdef base < LocalController
    properties (SetAccess=protected, Hidden)
        key      
        str_x    
        str_u = "omega"   
        str_y = "Vpss"   
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
            obj.JacobiDyv = @(t, x, V, u) zeros(1,2);
            obj.JacobiDyu = @(t, x, V, u) zeros(1,1);

        end
        function get_equilibrium(obj, V, u) %#ok
            obj.cv_Xequilibrium = 0;
            obj.cv_Uequilibrium = 0;
        end
    end

    methods
        function dx = fcn_dx(obj, t, x, V, u, para, omega0) %#ok
            dx = [];
        end
        function y  = fcn_y(obj, t, x, V, u, para, omega0) %#ok
            y = 0;
        end
        function M  = fcn_Mass(obj, t, x, V, u, para, omega0) %#ok
            M = [];
        end
    end
end