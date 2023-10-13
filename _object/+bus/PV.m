classdef PV < bus
% モデル  ：PV母線
%親クラス：busクラス
%実行方法：obj = bus.PV(P, V, shunt)
%　引数　：・　P　：有効電力Pの潮流設定値
%　　　　　・　V　：電圧の絶対値|V|の潮流設定値
%　　　　　・　shunt　：母線とグラウンドの間のアドミタンスの値
%　出力　：busクラスのインスタンス
    
    properties(SetAccess = protected)
        Vabs
        P
    end
    
    methods
        function obj = PV(P, V, shunt)
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
        end
        
        function set_Vabs(obj,Vabs)
            obj.Vabs = Vabs;
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

