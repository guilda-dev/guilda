classdef avr_sadamoto2019 < avr
% モデル  ：定本先生が2019年の論文で紹介されたモデル 
%親クラス：avrクラス
%実行方法：avr_sadamoto2019(avr_tab)
%　引数　：・avr_tab：テーブル型の変数。「'Te','Ka'」を列名として定義
%　出力　：avrクラスの変数
    
    properties
        Ka
        Te
    end
    
    methods
        function obj = avr_sadamoto2019(avr_tab)
            obj.Te = avr_tab{:, 'Te'};
            obj.Ka = avr_tab{:, 'Ka'};
            [A, B, C, D] = obj.get_linear_matrix();
            sys = ss(A, B, C, D);
            sys.InputGroup.Vabs = 1;
            sys.InputGroup.u_avr = 3;
            sys.InputGroup.Efd = 2;
            sys.OutputGroup.Vfd = 1;
            obj.sys = sys;
        end
        
        function name_tag = get_state_name(obj)
            name_tag = {'Vfield'};
        end
        
        function nx = get_nx(obj)
            nx = 1;
        end
        
        function x = initialize(obj, Vfd, V)
            obj.Vfd_st = Vfd;
            obj.Vabs_st = V;
            x = Vfd;
        end
        
        function [dVfd, Vfd] = get_Vfd(obj, Vfd, Vabs, Efd, u)
            Vef = obj.Ka*(Vabs-obj.Vabs_st+u(1));
            dVfd = (-Vfd+obj.Vfd_st-Vef)/obj.Te;
        end
        
        function [dVfd, Vfd] = get_Vfd_linear(obj, Vfd, Vabs, Efd, u)
            [dVfd, Vfd] = get_Vfd(obj, Vrfd, Vabs, u);
        end
        
        function [A, B, C, D] = get_linear_matrix(obj)
            A = -1/obj.Te;
            B = -obj.Ka/obj.Te*[1 0 1];
            C = 1;
            D = 0;
        end
        
        function sys = get_sys(obj)
            sys = obj.sys;
        end
        
    end
end

