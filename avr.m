classdef avr < handle
    
    properties
        Vfd_st
        Vabs_st
        sys
    end
    
    methods
        function obj = avr()
            sys = ss([0 0 1]);
            sys.InputGroup.Vabs = 1;
            sys.InputGroup.u_avr = 3;
            sys.InputGroup.Efd = 2;
            sys.OutputGroup.Vfd = 1;
            obj.sys = sys;
        end
        
        function nx = get_nx(obj)
            nx = 0;
        end
        
        function x = initialize(obj, Vfd, V)
            obj.Vfd_st = Vfd;
            obj.Vabs_st = V;
            x = [];
        end
        
        function [dx, Vfd] = get_Vfd(obj, x_avr, Vabs, Efd,  u)
            Vfd = obj.Vfd_st - u;
            dx = [];
        end
        
        function sys = get_sys(obj)
            sys = obj.sys;
        end
    end
end

