classdef pss < handle
    
    properties
        nx
        A
        B
        C
        D
        sys
    end
    
    methods
        function obj = pss(pss_in)
            if nargin < 1 || isempty(pss_in)
                pss_in = ss(0);
            end
            obj.set_pss(pss_in);
            sys = ss(obj.A, obj.B, obj.C, obj.D);
            sys.InputGroup.omega = 1;
            sys.OutputGroup.v_pss = 1;
            obj.sys = sys;
        end
        
        function nx = get_nx(obj)
           nx = obj.nx; 
        end
        
        function [dx, u] = get_u(obj, x_pss, omega)
            dx = obj.A*x_pss + obj.B*omega;
            u = obj.C*x_pss + obj.D*omega;
        end
        
        function x = initialize(obj)
           x = zeros(obj.get_nx, 1); 
        end
        
        function sys = get_sys(obj)
            sys = obj.sys;
        end
        
        function set_pss(obj, pss)
            if istable(pss)
                Kpss = pss{:, 'Kpss'};
                Tpss = pss{:, 'Tpss'};
                TL1p = pss{:, 'TL1p'};
                TL1 = pss{:, 'TL1'};
                TL2p = pss{:, 'TL2p'};
                TL2 = pss{:, 'TL2'};
                obj.A = [
                    -1/Tpss, 0, 0;
                    -Kpss*(1-TL1p/TL1)/(Tpss*TL1), -1/TL1, 0;
                    -(Kpss*TL1p)*(1-TL2p/TL2)/(Tpss*TL1*TL2), (1-TL2p/TL2)/TL2, -1/TL2
                    ];
                obj.B = [
                    1/Tpss;
                    Kpss*(1-TL1p/TL1)/(Tpss*TL1);
                    (Kpss*TL1p)*(1-TL2p/TL2)/(Tpss*TL1*TL2)
                    ];
                obj.C = [-(Kpss*TL1p*TL2p)/(Tpss*TL1*TL2), TL2p/TL2, 1];
                obj.D = (Kpss*TL1p*TL2p)/(Tpss*TL1*TL2);
            else
                [obj.A, obj.B, obj.C, obj.D] = ssdata(pss);
            end
            obj.nx = size(obj.A, 1);
        end
    end
end

