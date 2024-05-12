classdef IEEE_type1 < component.generator.abstract.SubClass
% モデル　 : IEEE_type1モデル
% 　　　　   (Power System Dynamics and Stability: With Synchrophasor Measurement and Power System Toolbox
% 　　　　     p.142~144,184~185)
% 親クラス : avrクラス
% 実行方法 : avr_IEEE_type1(avr_tab)
% 引数　　 : ・avr_tab：テーブル型の変数。「'Ka', 'Ta', 'Ke', 'Te', 'Se1', 'Se2', 'Kf', 'Tf'」を列名として定義
% 　　　　    (ただし、S_E(E_{fd})={Se1}*exp({Se2}*E_{fd})と設定した)
% 出力　　 : avrクラスの変数

    methods
        function obj = IEEE_type1(parameter)
            obj@component.generator.abstract.SubClass("AVR");
            obj.parameter = parameter;%(:,{'Ka', 'Ta', 'Ke', 'Te', 'Se1', 'Se2', 'Kf', 'Tf'});
            obj.Tag = "IEEE_type1";
        end

        function name_tag = naming_state(~)
            name_tag = {'Vfd','Vr','Rf'};
        end

        function nx = get_nx(~)
            nx =3;
        end

        function [x_st,u_st] = get_equilibrium(obj, Vabs_st, Efd_st)
            para = obj.parameter{:,{'Ka', 'Ke', 'Kf', 'Tf', 'Se1', 'Se2'}};
            Ka  = para(1); Ke  = para(2);
            Kf  = para(3); Tf  = para(4);
            Se1 = para(5); Se2 = para(6);

            Se = Se1 * exp(Se2*Efd_st);

            Vfd_st = Efd_st;
            Rf_st  =  Kf/Tf * Vfd_st;
            Vr_st  = (Ke+Se)* Vfd_st;

            x_st = [ Vfd_st; Vr_st; Rf_st];
            u_st = Vabs_st + Vr_st/Ka;
        end

        function [dx, Vfd] = get_dx_u(obj, x_avr, u_avr, Vabs, Efd)%#ok
            % x_avr = [Vfd,Vr,Rf]
            % u_avr = Vref + Vpss

            para = obj.parameter{:,{'Ka', 'Ta', 'Ke', 'Te', 'Kf', 'Tf', 'Se1', 'Se2'}};
            Ka  = para(1); Ta  = para(2);
            Ke  = para(3); Te  = para(4);
            Kf  = para(5); Tf  = para(6);
            Se1 = para(7); Se2 = para(8);

            Vfd = x_avr(1);
            Vr  = x_avr(2);
            Rf  = x_avr(3);
            Se  = Se1*exp(Se2*Vfd);

            dVfd = -(Ke+Se)*Vfd + Vr;
            dVr  = -Vr + Ka*Rf - Ka*Kf*Vfd/Tf + Ka*(u_avr-Vabs);
            dRf  = -Rf + Kf*Vfd/Tf;

            E  = diag(1./[Te,Ta,Tf]);
            dx = E * [dVfd; dVr; dRf];
            
            % dVfd = -(Ke+Se)*Vfd/Te + Vr/Te;
            % dVr  = -Vr/Ta + Ka*Rf/Ta - Ka*Kf*Vfd/(Ta*Tf) + Ka*(u_avr-Vabs)/Ta;
            % dRf  = -Rf/Tf + Kf*Vfd/(Tf*Tf);
            % dx   = [dVfd; dVr; dRf];
        end
    end
end