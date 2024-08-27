classdef PVarg < bus
% モデル  ：PVarg母線
%親クラス：busクラス
%実行方法：obj = bus.PV(P, Vangle, shunt)
%　引数　：・　P　：有効電力Pの潮流設定値
%　　　　　・　Vangle　：電圧の偏角∠Vの潮流設定値
%　　　　　・　shunt　：母線とグラウンドの間のアドミタンスの値
%　出力　：busクラスのインスタンス
    
    properties(SetAccess = protected)
        Vangle
        P
    end
    
    methods
        function obj = PVarg(P, Vangle, shunt)
            obj@bus(shunt);
            obj.Vangle = Vangle;
            obj.P = P;
            obj.set_component(component.empty());
        end
        
        function out = get_constraint(obj, Vr, Vi, P, ~)
            Vangle = angle(Vr+1j*Vi);%#ok
            out = [Vangle-obj.Vangle; P-obj.P];%#ok
        end

        function set_P(obj,P)
            obj.P = P;
            obj.editted("P")
        end
        
        function set_Varg(obj,Varg)
            obj.Varg = Varg;
            obj.editted("Vangle")
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

