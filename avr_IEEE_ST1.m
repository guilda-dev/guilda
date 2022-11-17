classdef avr_IEEE_ST1 < avr
% モデル  ：IEEE_ST1モデル 
%親クラス：avrクラス
%実行方法：avr_IEEE_ST1(avr_tab)
%　引数　：・avr_tab：テーブル型の変数。「't_tr', 'k_ap','k0','gamma_max','gamma_min'」を列名として定義
%　出力　：avrクラスの変数

    properties
        Vref
        k_ap
        t_tr
        k0
        gamma_max
        gamma_min
    end
    
    methods
        function obj = avr_IEEE_ST1(avr_tab)
            obj.t_tr = avr_tab{:, 't_tr'};
            obj.k_ap = avr_tab{:, 'k_ap'};
            obj.k0 = avr_tab{:, 'k0'};
            obj.gamma_max = avr_tab{:, 'gamma_max'};
            obj.gamma_min = avr_tab{:, 'gamma_min'};
            
            [A, B, C, D] = obj.get_linear_matrix();
            sys = ss(A, B, C, D);
            sys.InputGroup.Vabs = 1;
            sys.InputGroup.Efd = 2;
            sys.InputGroup.u_avr = 3;
            sys.OutputGroup.Vfd = 1;
            obj.sys = sys;
        end
        
        function name_tag = get_state_name(obj)
            name_tag = {'Vfd'};
        end
        
        function nx = get_nx(obj)
            nx = 1;
        end
        
        function x = initialize(obj, Vfd, V)
            obj.Vref = Vfd/obj.k_ap + V;
            x = V;
        end
        
        function [dV_tr, Vfd] = get_Vfd(obj, V_tr, Vabs, Efd, Vpss)
            dV_tr = (Vabs-V_tr)/obj.t_tr;
            V_ap = obj.k_ap*(obj.Vref+Vpss-V_tr);
            
            V_ap_min = Vabs*obj.gamma_min;
            V_ap_max = Vabs*obj.gamma_max-obj.k0*Efd;
            
            Vfd = sat(V_ap, V_ap_min, V_ap_max);
        end
        
        function [dV_tr, Vfd] = get_Vfd_linear(obj, V_tr, Vabs, Efd, u)
            [dV_tr, Vfd] = get_Vfd(obj, V_tr, Vabs, Efd, u);
        end
        
        function [A, B, C, D] = get_linear_matrix(obj)
            A = -1/obj.t_tr;
            B = [1 0 0]/obj.t_tr;
            C = -obj.k_ap;
            D = [0 0 1]*obj.k_ap;
        end
        
        function sys = get_sys(obj)
            sys = obj.sys;
        end
        
    end
end

function out = sat(x, x_min, x_max)
out = max(x, x_min);
out = min(out, x_max);
end
