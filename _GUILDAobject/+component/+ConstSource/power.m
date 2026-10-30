 classdef power < component.load.abstract
% Legacy constant-power load model with the v1 component interface.
%
% The model has no states and two input ports, `RealPower` and `ReactivePower`
% (`naming_port`). It uses the old interface (`get_dx_constraint`,
% `get_linear_matrix`) and does not define the model constants of `Component`
% (`key`, `sv_x`, `sv_u`, `sv_y`, `sv_para`), so it cannot be created or added to a
% bus.
%
% <@Deprecated> Use `component.load.power` (key `"load-power"`).
%
% See also component.load.power
    
    properties % Steady state
        % [pu] Steady power `[P; Q]`, set by `get_equilibrium`.
        PQ_st
    end

    methods

        function [x_st,u_st] = get_equilibrium(obj,Veq,Ieq)
            % Calculate the steady power from the bus voltage and current.
            %
            % `Veq` and `Ieq` are the complex bus voltage and current [pu]. The
            % state equilibrium `x_st` is empty and the steady input `u_st` is
            % the power `[P; Q]` [pu], also stored in `PQ_st`.
            PQ = Veq * conj(Ieq);
            obj.PQ_st = [real(PQ); imag(PQ)];
            x_st = zeros(0, 1);
            u_st = obj.PQ_st;
        end

        function [dx, constraint] = get_dx_constraint(obj, t, x, V, I, u)%#ok
            % Calculate the state derivative and the current constraint (v1 interface).
            %
            % `V` and `I` are the bus voltage and current as `[real; imag]` [pu]
            % and `u` is the power `[P; Q]` [pu]. `dx` is empty; `constraint` is
            % the difference between `I` and the current of the power `u`.
            dx = zeros(0, 1);
            PQ = u(1) + 1j*u(2);
            V = V(1)+1j*V(2);
            I_ = PQ/V;
            constraint = I-[real(I_); -imag(I_)];
        end

        function u_name = naming_port(obj)
            % Return the input port names (v1 interface).
            u_name = {'RealPower','ReactivePower'};
        end
        
        function [A, B, C, D, BV, DV, BI, DI, R, S] = get_linear_matrix(obj, ~, V)
            % Return the matrices of the linearized model (v1 interface).
            %
            % `V` is the bus voltage `[real; imag]` [pu] of the operating point;
            % empty or omitted uses `V_st`.
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
