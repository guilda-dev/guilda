classdef abstract < LocalController
    properties (SetAccess=protected, Hidden)
        key      
        sv_x    
        sv_u = ["Vref";"Vpss"]   
        sv_y = ["Vfield"]    
        sv_para 
    end    
    methods
        function obj = abstract(tag) 
            arguments
                tag = "base"
            end
            obj@LocalController("CA"+tag)                                                                                           
        end                

        function get_equilibrium(obj, V, u) %#ok                              
            obj.rv_Xequilibrium = u(2);
            obj.rv_Uequilibrium = [];
        end
        
        function set_PSS(obj, cls) %#ok
            obj.a_LocalController{1} = controller.pss.base;
            obj.l_hasController = true;
        end
        
    end
    
end