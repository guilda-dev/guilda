classdef base < LocalController
    properties (SetAccess=protected, Hidden)
        key      
        sv_x    
        sv_u = "omega"   
        sv_y = "Vpss"   
        sv_para 
    end    
    methods
        function obj = base(tag)
            arguments                            
                tag = "base"
            end            
            obj@LocalController("CP"+tag)                                                            

        end        
        
        function get_equilibrium(obj, V, u) %#ok
            obj.rv_Xequilibrium = 0;
            obj.rv_Uequilibrium = 0;
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