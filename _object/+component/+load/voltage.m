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

        function [A, B, C, D, BV, DV, BI, DI, R, S] = get_linear_matrix(obj, ~, ~)
            if nargin < 3
                [A, B, C, D, BV, DV, BI, DI, R, S] = obj.get_linear_matrix([], obj.V_st);
            else

                A  = [];
                B  = zeros(0, 2);
                C  = zeros(2, 0);
                D  = eye(2);
                BV = zeros(0, 2);
                DV = -eye(2);
                R  = [];
                S  = [];
                BI = zeros(0, 2);
                DI = zeros(2, 2);
            end
        end
        
    end
end
