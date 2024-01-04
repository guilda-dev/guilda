classdef voltage < component.load.abstract
% モデル ：定電圧負荷モデル
%       ・状態：なし
%       ・入力：２ポート「電圧フェーザの実部の倍率,電圧フェーザの虚部の倍率」
%               *入力αのとき値は設定値の(1+α)倍となる．
%親クラス：componentクラス
%実行方法：obj = component.load.voltage()
%　引数　：なし
%　出力　：componentクラスのインスタンス
    

    methods
        
        function [x_st,u_st] = get_equilibrium(obj,Veq,~)
            x_st = zeros(0,1);
            u_st = tools.complex2vec(Veq);
        end

        function [dx, constraint] = get_dx_constraint(obj, t, x, V, I, u)
            dx = zeros(0, 1);
            constraint = V - u(:);
        end

        function u_name = naming_port(obj)
            u_name = {'Vreal','Vimag'};
        end
        
    end
end
