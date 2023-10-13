classdef PVarg < bus
% モデル  ：PVarg母線
%親クラス：busクラス
%実行方法：obj = bus.PV(P, V, shunt)
%　引数　：・　P　：有効電力Pの潮流設定値
%　　　　　・　V　：電圧の絶対値|V|の潮流設定値
%　　　　　・　shunt　：母線とグラウンドの間のアドミタンスの値
%　出力　：busクラスのインスタンス
    
    properties(SetAccess = protected)
        Varg
        P
    end
    
    methods
        function obj = PVarg(P, Varg, shunt)
            obj@bus(shunt);
            obj.Varg = Varg;
            obj.P = P;
        end
        
        function out = get_constraint(obj, Vr, Vi, P, Q)
            Varg = angle(Vr+1j*Vi); %#ok
            out = [Varg-obj.Varg; P-obj.P]; %#ok
        end

        function set_P(obj,P)
            obj.P = P;
            obj.edit_parameter;
        end
        
        function set_Varg(obj,Varg)
            obj.Varg = Varg;
            obj.edit_parameter;
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

