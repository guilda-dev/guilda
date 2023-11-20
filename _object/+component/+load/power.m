 classdef power < component.load.abstract
% モデル ：定電力負荷モデル
%       ・状態：なし
%       ・入力：２ポート「有効電力の倍率,無効電力の倍率」
%               *入力αのとき電力の値は設定値の(1+α)倍となる．
%親クラス：componentクラス
%実行方法：obj = component.load.power()
%　引数　：なし
%　出力　：componentクラスのインスタンス
    
    properties
        PQ_st
    end

    methods

        function set_equilibrium(obj)
            obj.x_equilibrium = zeros(0, 1);
            PQ = obj.V_equilibrium * conj(obj.I_equilibrium);
            obj.PQ_st = [real(PQ); imag(PQ)];
            switch obj.porttype
                case 'rate'
                    obj.u_equilibrium = [1;1];
                case 'value'
                    obj.u_equilibrium = obj.PQ_st;
            end
        end
        
        function [dx, constraint] = get_dx_constraint(obj, t, x, V, I, u)
            dx = zeros(0, 1);
            switch obj.porttype
                case 'rate'
                    PQ = obj.PQ_st .* u(:);
                    PQ = PQ(1)+1j*PQ(2);
                case 'value'
                    PQ = u(1) + 1j*u(2);
            end
            V = V(1)+1j*V(2);
            I_ = PQ/V;
            constraint = I-[real(I_); -imag(I_)];
        end
        
        function nu = get_nu(~)
            nu = 2;
        end

        function u_name = naming_port(obj)
            switch obj.porttype
                case 'value'
                    u_name = {'RealPower','ReactivePower'};
                case 'rate'
                    u_name = {'RealPowerRate','ReactivePowerRate'};
            end
        end
        
        function [A, B, C, D, BV, DV, BI, DI, R, S] = get_linear_matrix(obj, x, V)
            if nargin < 2
                [A, B, C, D, BV, DV, BI, DI, R, S] = obj.get_linear_matrix_([], obj.V_st);
            else
                den = (V'*V)^2;
                Vr = V(1);
                Vi = V(2);
                P = obj.PQ_st(1);
                Q = obj.PQ_st(2);

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
        
    end
end
