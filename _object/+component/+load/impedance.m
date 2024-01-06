classdef impedance < component.load.abstract
% モデル ：定インピーダンス付加モデル
%       ・状態：なし
%       ・入力：２ポート「インピーダンス値の実部の倍率,インピーダンス値の虚部の倍率」
%               *入力αのときインピーダンスの値は設定値の(1+α)倍となる．
%親クラス：componentクラス
%実行方法：obj = component.load.impedance()
%　引数　：なし
%　出力　：componentクラスのインスタンス
    

    properties(SetAccess = private)
        Y
    end
    
    methods
        
        function [x_st,u_st] = get_equilibrium(obj,Veq,Ieq)
            obj.Y = Ieq/Veq;
            u_st = [real(obj.Y);imag(obj.Y)];
            x_st = zeros(0,1);
        end
        
        function [dx, constraint] = get_dx_constraint(obj, ~, ~, V, I, u)
            dx = zeros(0, 1);
            I_ = [u(1),-u(2);u(2),u(1)]*V;
            constraint = I-I_;
        end

        function u_name = naming_port(obj)
            u_name = {'Conductance','Susceptance'};
        end

        function [A, B, C, D, BV, DV, BI, DI, R, S] = get_linear_matrix(obj, ~, V)
            if nargin < 3
                [A, B, C, D, BV, DV, BI, DI, R, S] = obj.get_linear_matrix([], obj.V_st);
            else
                if isempty(V)
                    V = obj.V_st;
                end

                A = [];
                B = zeros(0, 2);
                C = zeros(2, 0);
                D = [tools.complex2matrix(real(obj.Y))*V, tools.complex2matrix(1j*imag(obj.Y))*V];
                BV = zeros(0, 2);
                DV = tools.complex2matrix(obj.Y);
                R = [];
                S = [];
                BI = zeros(0, 2);
                DI = -eye(2);
            end
        end
        
    end
end
