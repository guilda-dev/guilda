classdef slack < bus
% モデル  ：slack母線
%親クラス：busクラス
%実行方法：obj = bus.slack(Vabs, Vangle, shunt)
%　引数　：・　Vabs　：母線電圧の絶対値|V|の潮流設定値
%　　　　　・　Vangle：母線電圧の偏角∠Vの潮流設定値
%　　　　　・　shunt　：母線とグラウンドの間のアドミタンスの値
%　出力　：busクラスのインスタンス

    properties(SetAccess=private)
        Vabs
        Vangle
    end
    
    methods
        function obj = slack(Vabs, Vangle, shunt)
            obj@bus(shunt);
            obj.Vabs = Vabs;
            obj.Vangle = Vangle;
            obj.set_component(component.empty());
        end
        
        function out = get_constraint(obj, Vr, Vi, P, Q)
            Vabs = norm([Vr; Vi]); %#ok
            Vangle = atan2(Vi, Vr); %#ok
            out = [Vabs-obj.Vabs; Vangle-obj.Vangle]; %#ok
        end

        function set_Vabs(obj,Vabs)
            obj.Vabs = Vabs;
            obj.editted("Vabs")
        end
        
        function set_Vangle(obj,Vangle)
            obj.Vangle = Vangle;
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

