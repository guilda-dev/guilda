classdef IEEE_DC1 < component.generator.avr.base
% モデル　 : IEEE_DC1モデル
% 　　　　   (電力系統のシステム制御工学 p.221~224)
% 　　　　   (Robust Control in Power Systems p.43)
% 親クラス : avrクラス
% 実行方法 : avr_IEEE_DC1(avr_tab)
% 引数　　 : ・avr_tab：テーブル型の変数。「'Ttr', 'Kap', 'Tap', 'Vap_max', 'Vap_min', 'Kst', 'Tst', 'Aex', 'Tex', 'a_ex', 'b_ex'」を列名として定義
% 出力　　 : avrクラスの変数

    properties
        Vref
        Ttr
        Kap
        Tap
        Vap_max
        Vap_min
        Kst
        Tst
        Aex
        Tex
        a_ex
        b_ex
    end

    methods
        function obj = IEEE_DC1(avr_tab)
            obj.Ttr = avr_tab{:, 'Ttr'};
            obj.Kap = avr_tab{:, 'Kap'};
            obj.Tap = avr_tab{:, 'Tap'};
            obj.Vap_max = avr_tab{:, 'Vap_max'};
            obj.Vap_min = avr_tab{:, 'Vap_min'};
            obj.Kst = avr_tab{:, 'Kst'};
            obj.Tst = avr_tab{:, 'Tst'};
            obj.Aex = avr_tab{:, 'Aex'};
            obj.Tex = avr_tab{:, 'Tex'};
            obj.a_ex = avr_tab{:, 'a_ex'};
            obj.b_ex = avr_tab{:, 'b_ex'};
        end

        function name_tag = naming_state(obj)
            name_tag = {'Vtr','Vap','Vfd','Vst'};
        end

        function nx = get_nx(obj)
            nx = 4;
        end

        function [dx, Vfd] = get_Vfd(obj, x_avr, Vabs, ~, Vpss)
            Vtr = x_avr(1);
            Vap = x_avr(2);
            Vfd = x_avr(3);
            Vst = x_avr(4);

            dVtr = (-V_tr+Vabs)/obj.Ttr;
            Vcom = obj.Vref + Vpss - Vtr - Vst;
            if ((Vap>obj.Vap_min)&&(Vap<obj.Vap_max))||(Vap*Vcom<=0)
                dVap = (-Vap + obj.Kap*Vcom)/obj.Tap;
            else
                dVap = 0;
            end
            dVfd = (-(obj.Aex+obj.a_ex*exp(obj.b_ex*Vfd))*Vfd + Vap)/obj.Tex;
            dVst = (-Vst + obj.Kst*dVfd)/obj.Tst;
            dx = [dVtr; dVap; dVfd; dVst];
        end

        function [dx, Vfd] = get_Vfd_linear(obj, x_avr, Vabs, Efd, u)
            [dx, Vfd] = get_Vfd(obj, x_avr, Vabs, Efd, u);
        end

    end
end