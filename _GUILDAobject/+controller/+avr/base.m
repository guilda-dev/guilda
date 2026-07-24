classdef base < LocalController
    properties (SetAccess=protected, Hidden)
        key      
        sv_x    
        sv_u = ["Vref";"Vpss"]   
        sv_y = ["Vfield"]    
        sv_para 
    end    
    methods
        function obj = base(tag) 
            arguments
                tag = "base"
            end
            obj@LocalController("CA"+tag)                                                                           
        end        

        function set_odefcn(obj, omega0) %#ok           

            obj.f_dx = @(t, x, V, u) [];
            obj.f_Mass = @(t, x, V, u) [];
            obj.f_Y    = @(t, x, V, u) obj.rv_Xequilibrium(3);

            obj.JacobiAxx = @(t, x, V, u) [];
            obj.JacobiBxv = @(t, x, V, u) [];
            obj.JacobiBxu = @(t, x, V, u) [];

            obj.JacobiCyx = @(t, x, V, u) [];
            obj.JacobiDyv = @(t, x, V, u) zeros(1,2);
            obj.JacobiDyu = @(t, x, V, u) zeros(1,2);

        end

        function get_equilibrium(obj, V, u) %#ok                              
            obj.rv_Xequilibrium = u(2);
            obj.rv_Uequilibrium = [];
        end
        
        function set_PSS(obj, cls) %#ok
            obj.a_LocalController{1} = controller.pss.base;
            obj.isController = true;
        end
        
    end

    methods       
        function M  = fcn_Mass(obj, t, x, V, u, param, omega0) %#ok
            M = [];
        end
        function dx = fcn_dx(obj, t, x, V, u, param, omega0) %#ok
            dx = [];
        end
        function y  = fcn_y(obj, t, x, V, u, param, omega0) %#ok               
            y = 0;
        end
    end
end