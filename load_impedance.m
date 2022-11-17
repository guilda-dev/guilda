classdef load_impedance < component
% モデル ：定インピーダンス付加モデル
%       ・状態：なし
%       ・入力：２ポート「インピーダンス値の実部の倍率,インピーダンス値の虚部の倍率」
%               *入力αのときインピーダンスの値は設定値の(1+α)倍となる．
%親クラス：componentクラス
%実行方法：obj = load_impedance()
%　引数　：なし
%　出力　：componentクラスのインスタンス
    
    properties(Access = private)
        YL_mat
        YL
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
        function obj = load_impedance(varargin)
            obj.x_equilibrium = zeros(0, 1);
            obj.S = [];
            obj.R = [];
        end
        
        function set_equilibrium(obj, Veq, Ieq)
            obj.V_equilibrium = Veq;
            obj.I_equilibrium = Ieq;
            obj.set_admittance(Ieq/Veq);
            obj.V_st = tools.complex2vec(Veq);
            obj.I_st = tools.complex2vec(Ieq);
            obj.YL = obj.Y;
            
        end
        
        function [dx, constraint] = get_dx_constraint(obj, t, x, V, I, u)
            dx = zeros(0, 1);
            Y = real(obj.Y)*(1+u(1)) + 1j*imag(obj.Y)*(1+u(2));
            V = V(1)+1j*V(2);
            I_ = Y*V;
            constraint = I-[real(I_); imag(I_)];
        end
        
        function varargout = get_dx_constraint_linear(varargin)
            varargout = cell(nargout, 1);
            [varargout{:}] = get_dx_constraint(varargin{:});
        end
        
%         function [dx, constraint] = get_dx_constraint_linear(obj, t, x, V, I, u)
%             [A, B, C, D, BV, DV, BI, DI, ~, ~] = obj.get_linear_matrix_(x, V);
%             dx = A*x + B*u + BI*(I-obj.I_st) + BV*(V-obj.V_st);
%             constraint = C*x + D*u + DI*(I-obj.I_st) + DV*(V-obj.V_st);
%         end
        
        function nu = get_nu(obj)
            nu = 2;
        end
        
        function set_admittance(obj, y)
            obj.Y = y;
            obj.YL_mat = tools.complex2matrix(obj.Y);
        end
        
        function [A, B, C, D, BV, DV, BI, DI, R, S] = get_linear_matrix_(obj, x, V)
            if nargin < 2
                [A, B, C, D, BV, DV, BI, DI, R, S] = obj.get_linear_matrix_([], obj.V_st);
            else
                A = [];
                B = zeros(0, 2);
                C = zeros(2, 0);
                D = [tools.complex2matrix(real(obj.YL))*V, tools.complex2matrix(1j*imag(obj.YL))*V];
                BV = zeros(0, 2);
                DV = obj.YL_mat;
                R = obj.R;
                S = obj.S;
                BI = zeros(0, 2);
                DI = -eye(2);
            end
        end
        
        function varargout = get_linear_matrix(obj, varargin)
            varargout = cell(nargout, 1);
            [varargout{:}] = obj.get_linear_matrix_(varargin{:});
        end
        
    end
end
