classdef bus_PQ < bus
% モデル  ：PQ母線
%親クラス：busクラス
%実行方法：obj = bus_PQ(P, Q, shunt)
%　引数　：・　P　：有効電力Pの潮流設定値
%　　　　　・　Q　：無効電力Qの潮流設定値
%　　　　　・　shunt　：母線とグラウンドの間のアドミタンスの値
%　出力　：busクラスのインスタンス
    
    properties(SetAccess=private)
        P
        Q
    end
    
    methods
        function obj = bus_PQ(P, Q, shunt)
            obj@bus(shunt);
            obj.P = P;
            obj.Q = Q;
        end
        
        function out = get_constraint(obj, Vr, Vi, P, Q)
            out = [P-obj.P; Q-obj.Q];
        end

        function set_P(obj,P)
            obj.P = P;
            obj.edit_parameter;
        end
        
        function set_Q(obj,Q)
            obj.Q = Q;
            obj.edit_parameter;
        end
    end
end

