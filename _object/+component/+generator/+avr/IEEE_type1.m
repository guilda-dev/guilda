classdef IEEE_type1 < component.generator.avr.base
% モデル　 : IEEE_type1モデル
% 　　　　   (Power System Dynamics and Stability: With Synchrophasor Measurement and Power System Toolbox
% 　　　　     p.142~144,184~185)
% 親クラス : avrクラス
% 実行方法 : avr_IEEE_type1(avr_tab)
% 引数　　 : ・avr_tab：テーブル型の変数。「'Ka', 'Ta', 'Ke', 'Te', 'Se1', 'Se2', 'Kf', 'Tf'」を列名として定義
% 　　　　    (ただし、S_E(E_{fd})={Se1}*exp({Se2}*E_{fd})と設定した)
% 出力　　 : avrクラスの変数

    properties
        Vref
        Ka
        Ta
        Ke
        Te
        Se1
        Se2
        Kf
        Tf
    end

    methods
        function obj = IEEE_type1(avr_tab)
            obj.Ka = avr_tab{:, 'Ka'};
            obj.Ta = avr_tab{:, 'Ta'};
            obj.Ke = avr_tab{:, 'Ke'};
            obj.Te = avr_tab{:, 'Te'};
            obj.Se1 = avr_tab{:, 'Se1'};
            obj.Se2 = avr_tab{:, 'Se2'};
            obj.Kf = avr_tab{:, 'Kf'};
            obj.Tf = avr_tab{:, 'Tf'};
        end

        function name_tag = naming_state(obj)
            name_tag = {'Vfd','Vr','Rf'};
        end

        function nx = get_nx(obj)
            nx = 3;
        end

        function [dx, Vfd] = get_Vfd(obj, x_avr, Vabs, ~, u) % u:Vpss
            Vfd = x_avr(1);
            Vr = x_avr(2);
            Rf = x_avr(3);
            Se = obj.Se1*exp(obj.Se2*V_fd);

            dV_fd = -(obj.Ke+Se)*Vfd/obj.Te + Vr/obj.Te;
            dVr = -Vr/obj.Ta + obj.Ka*Rf/obj.Ta - obj.Ka*obj.Kf*Vfd/(obj.Ta*obj.Tf) + obj.Ka*(obj.Vref+u-Vabs)/obj.Ta;
            dRf = -Rf/obj.Tf + obj.Kf*Vfd/(obj.Tf*obj.Tf);
            dx = [dV_fd; dVr; dRf];
        end

        function [dx, Vfd] = get_Vfd_linear(obj, x_avr, Vabs, ~, u)
            [dx, Vfd] = get_Vfd(obj, x_avr, Vabs, ~, u);
        end

    end
end