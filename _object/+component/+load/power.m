 classdef power < component.load.abstract
% モデル  ：定電力負荷モデル
% 状態　　：なし
% 入力　　：２ポート「有効電力・無効電力」
%実行方法 ：obj = component.load.power()
    
    properties
        PQ_st
    end

    methods
        
        function [x_st,u_st] = get_equilibrium(obj,Veq,Ieq)
            PQ = Veq * conj(Ieq);
            obj.PQ_st = [real(PQ); imag(PQ)];
            x_st = zeros(0, 1);
            u_st = obj.PQ_st;
        end

        function [dx, constraint] = get_dx_constraint(obj, t, x, V, I, u)
            dx = zeros(0, 1);
            PQ = u(1) + 1j*u(2);
            V = V(1)+1j*V(2);
            I_ = PQ/V;
            constraint = I-[real(I_); -imag(I_)];
        end

        function u_name = naming_port(obj)
            u_name = {'RealPower','ReactivePower'};
        end
        
        function [A, B, C, D, BV, DV, BI, DI, R, S] = get_linear_matrix(obj, ~, V)
            if nargin < 3
                [A, B, C, D, BV, DV, BI, DI, R, S] = obj.get_linear_matrix([], obj.V_st);
            else
                if isempty(V)
                    V = obj.V_st;
                end

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
                R = [];%obj.R;
                S = [];%obj.S;
                BI = zeros(0, 2);
                DI = -eye(2);
            end
        end
        
    end
end
