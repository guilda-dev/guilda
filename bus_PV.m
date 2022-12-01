classdef bus_PV < bus
% モデル  ：PV母線
%親クラス：busクラス
%実行方法：obj = bus_PV(P, V, shunt)
%　引数　：・　P　：有効電力Pの潮流設定値
%　　　　　・　V　：電圧の絶対値|V|の潮流設定値
%　　　　　・　shunt　：母線とグラウンドの間のアドミタンスの値
%　出力　：busクラスのインスタンス
    
    properties(SetAccess = private)
        Vabs
        P
    end
    
    methods
        function obj = bus_PV(P, V, shunt)
            obj@bus(shunt);
            obj.Vabs = V;
            obj.P = P;
        end
        
        function out = get_constraint(obj, Vr, Vi, P, Q)
            Vabs = norm([Vr; Vi]); %#ok
            out = [Vabs-obj.Vabs; P-obj.P]; %#ok
        end

        function set_P(obj,P)
            obj.P = P;
            obj.edit_parameter;
        end
        
        function set_Vabs(obj,Vabs)
            obj.Vabs = Vabs;
            obj.edit_parameter;
        end
    end
end

