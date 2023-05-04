classdef empty < base_class.component
% モデル  ：空の機器モデル
%       ・状態：なし
%       ・入力：ポートなし
%親クラス：componentクラス
%実行方法：obj = component.empty()
%　引数　：なし
%　出力　：componentクラスのインスタンス
    
    
    methods
        function set_equilibrium(obj, Veq, Ieq)
            obj.V_equilibrium = Veq;
            obj.I_equilibrium = Ieq;
            obj. x_equilibrium = [];
        end
        
        function nu = get_nu(obj)
            nu = 0;
        end
        
        function [dx, con] = get_dx_constraint(obj,~,~,~,I,~)
            dx = [];
            con = I(:);
        end
        
        function [dx, con] = get_dx_constraint_linear(obj,~,~,~,I,~)
            dx = [];
            con = I(:);
        end
        
        function [A, B, C, D, BV, DV, BI, DI, R, S] = get_linear_matrix(obj, varargin)
            A = [];
            B = [];
            C = zeros(2, 0);
            D = zeros(2, 0);
            BV = zeros(0, 2);
            DV = zeros(2, 2);
            R = [];
            S = [];
            DI = -eye(2);
            BI = zeros(0, 2);
        end
    end
end

