classdef sadamoto2019 < component.generator.abstract.SubClass
% クラス名： sadamoto2019
% 親クラス： component.generator.abstract.SubClass
% 実行方法： component.generator.pss.sadamoto2019()
%
%<<モデル概要>>
% 定本先生が2019年の論文で紹介されたモデル 
%
    
    
    methods
        function obj = sadamoto2019(parameter)
            arguments
                parameter = "sadamoto"
            end
            obj@component.generator.abstract.SubClass("PSS")
            obj.parameter = parameter(:,{'Kpss','Tpss','TL1p','TL1','TL2p','TL2'});
        end
        
        function [dx, v_pss] = get_dx_u(obj, x_pss, u_pss, omega)%#ok
            sys  = obj.system_matrix;

             dx   = sys.A*x_pss + sys.B*omega;
            v_pss = sys.C*x_pss + sys.D*omega;
        end
        
        function [x_st, u_st] = get_equilibrium(obj, omega_st)%#ok
            x_st = zeros(3,1);
            u_st = [];
        end

        
        function [A,B,C,D] = get_linear_matrix(obj, x_st, u_st, omega_st)%#ok
                para = obj.parameter{:,{'Kpss','Tpss','TL1p','TL1','TL2p','TL2'}};
                Kpss = para(1);     Tpss = para(2);
                TL1p = para(3);     TL1  = para(4);
                TL2p = para(5);     TL2  = para(6);
                
                E = 1./diag(Tpss,TL1,TL2);
                A = E*[  -1, 0, 0;
                         -(Kpss/Tpss)*(1-TL1p/TL1), -1, 0;
                         -(Kpss*TL1p/Tpss*TL1)*(1-TL2p/TL2), (1-TL2p/TL2), -1 ];
                B = -A(:,1);
                C = [-(Kpss/Tpss)*(TL1p/TL1)*(TL2p/TL2), TL2p/TL2, 1];
                D = -C(:,1);
        end
    end

    methods(Access=protected)
        function PropEditor_Set(obj,prop,val)
            obj.(prop) = val;
        end
        function val = PropEditor_Get(obj,prop)
            val = obj.(prop);
        end
    end
end

