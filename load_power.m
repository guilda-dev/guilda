classdef load_power < component
% モデル ：定電力負荷モデル
%       ・状態：なし
%       ・入力：２ポート「有効電力の倍率,無効電力の倍率」
%               *入力αのとき電力の値は設定値の(1+α)倍となる．
%親クラス：componentクラス
%実行方法：obj = load_power()
%　引数　：なし
%　出力　：componentクラスのインスタンス
    
    properties(Access = private)
        P_st
        Q_st
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
        function obj = load_power(varargin)
            obj.x_equilibrium = zeros(0, 1);
            obj.S = [];
            obj.R = [];
        end
        
        function set_equilibrium(obj, Veq, Ieq)
            obj.V_equilibrium = Veq;
            obj.I_equilibrium = Ieq;
            obj.set_power(Veq,Ieq);
            obj.V_st = tools.complex2vec(Veq);
            obj.I_st = tools.complex2vec(Ieq);
        end
        
        function [dx, constraint] = get_dx_constraint(obj, t, x, V, I, u)
            dx = zeros(0, 1);
            PQ = obj.P_st*(1+u(1)) + 1j*obj.Q_st*(1+u(2));
            V = V(1)+1j*V(2);
            I_ = PQ/V;
            constraint = I-[real(I_); -imag(I_)];
            %V = V(1)+1j*V(2);
            %I = I(1)-1j*I(2);
            %PQ = V*I;
            %constraint = [obj.P_st*(1+u(1))-real(PQ);obj.Q_st*(1+u(1))-imag(PQ)];
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
        
        function set_power(obj, Veq, Ieq)
            PQ = Veq * Ieq';
            obj.P_st = real(PQ);
            obj.Q_st = imag(PQ);
        end
        
        function [A, B, C, D, BV, DV, BI, DI, R, S] = get_linear_matrix_(obj, x, V)
            if nargin < 2
                [A, B, C, D, BV, DV, BI, DI, R, S] = obj.get_linear_matrix_([], obj.V_st);
            else
                den = (V'*V)^2;
                Vr = V(1);
                Vi = V(2);
                P = obj.P_st;
                Q = obj.Q_st;

                A = [];
                B = zeros(0, 2);
                C = zeros(2, 0);
                D = [P*Vr Q*Vi; P*Vi -Q*Vr]/(V'*V);
                BV = zeros(0, 2);
                DV = [P, Q; -Q, P]*[(Vi^2-Vr^2)/den, -2*Vr*Vi/den; -2*Vr*Vi/den, (Vr^2-Vi^2)/den];
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
