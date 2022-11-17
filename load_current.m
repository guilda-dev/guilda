classdef load_current < component
% モデル ：定電流負荷モデル
%       ・状態：なし
%       ・入力：２ポート「電流フェーザの実部の倍率,電流フェーザの虚部の倍率」
%               *入力αのとき値は設定値の(1+α)倍となる．
%親クラス：componentクラス
%実行方法：obj = load_current()
%　引数　：なし
%　出力　：componentクラスのインスタンス
    
    properties(Access = private)
        V_st
        I_st
        R
        S
    end
    
    properties(SetAccess = private)
        x_equilibrium
        V_equilibrium
        I_equilibrium
        Y
    end
    
    methods
        function obj = load_current(varargin)
            obj.x_equilibrium = zeros(0, 1);
            obj.S = [];
            obj.R = [];
        end
        
        function set_equilibrium(obj, Veq, Ieq)
            obj.V_equilibrium = Veq;
            obj.I_equilibrium = Ieq;
            obj.V_st = tools.complex2vec(Veq);
            obj.I_st = tools.complex2vec(Ieq);
        end
        
        function [dx, constraint] = get_dx_constraint(obj, t, x, V, I, u)
            dx = zeros(0, 1);
            constraint = I-[obj.I_st(1)*(1+u(1));obj.I_st(2)*(1+u(2))];
        end
        
%         function varargout = get_dx_constraint_linear(varargin)
%             varargout = cell(nargout, 1);
%             [varargout{:}] = get_dx_constraint(varargin{:});
%         end

        
        function [dx, constraint] = get_dx_constraint_linear(obj, t, x, V, I, u)
            [A, B, C, D, BV, DV, BI, DI, ~, ~] = obj.get_linear_matrix_(x, V);
            dx = A*x + B*u + BI*(I-obj.I_st) + BV*(V-obj.V_st);
            constraint = C*x + D*u + DI*(I-obj.I_st) + DV*(V-obj.V_st);
        end
        
        function nu = get_nu(obj)
            nu = 2;
        end
        
        
        function [A, B, C, D, BV, DV, BI, DI, R, S] = get_linear_matrix_(obj, x, V)
            if nargin < 2
                [A, B, C, D, BV, DV, BI, DI, R, S] = obj.get_linear_matrix_([], obj.V_st);
            else
                A = [];
                B = zeros(0, 2);
                C = zeros(2, 0);
                D = diag(obj.I_st);
                BV = zeros(0, 2);
                BI = zeros(0, 2);
                DV = zeros(2, 2);
                DI = -eye(2);
                R = obj.R;
                S = obj.S;
            end
        end
        
        function varargout = get_linear_matrix(obj, varargin)
            varargout = cell(nargout, 1);
            [varargout{:}] = obj.get_linear_matrix_(varargin{:});
        end
        
    end
end
