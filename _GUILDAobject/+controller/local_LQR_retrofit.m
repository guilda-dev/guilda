classdef local_LQR_retrofit <  LocalController
% Retrofit controller whose internal controller is an LQR.
% The controller observes the state of the generator it is attached to (rotor
% angle `delta` [rad] and internal voltage `E` [pu]) and its terminal voltage
% (angle and magnitude [pu]), and drives the AVR input `u_avr` of the generator.
% The LQR gain is designed for the generator connected to an environment model
% (`(delta, E) -> (angleV, absV)`, in polar coordinates) that
% controller.modeling.get_environment computes.
%
% This class uses the GUILDA v2 controller interface (`connected_index_*`,
% `get_dx_u`, `get_linear_matrix`); it does not implement the abstract methods
% of LocalController (`fcn_dx`, `fcn_y`, `fcn_Mass`, `Jacobi_dx`, `Jacobi_Y`).
%
% See also controller.modeling.get_environment, controller.local_LQR

    properties(SetAccess=protected) % Configuration
        type = 'local'; % Controller type ('local').
        port_input   = 'all'; % Input ports of the generator that the controller drives.
        port_observe = 'all'; % Observed ports of the generator ('all'; the controller uses delta, omega, Ed and Vfield).
    end

    properties % Design results
        A          % State matrix of the internal model.
        Bu         % Input matrix of the internal model for the LQR input.
        Bw         % Input matrix of the internal model for the deviation of `[delta; E]`.
        Bv         % Input matrix of the internal model for the deviation of `[angleV; absV]`.
        K          % LQR gain.
        nx         % Number of controller states.
        X0         % Equilibrium state of the generator.
        V0         % [pu] Equilibrium terminal voltage as `[real; imag]`.
        I0         % [pu] Equilibrium terminal current as `[real; imag]`.
        u0         % Equilibrium input of the generator.
        delta0     % [rad] Equilibrium rotor angle.
        E0         % [pu] Equilibrium internal voltage.
        sys_design % Generator and environment model used for the design (ss).
        sys_fb     % State-feedback model of the controller (ss).
    end

    methods
        function obj = local_LQR_retrofit(net, idx, Q, R, model)
            % Create a retrofit controller for the generator at one bus.
            %
            % Inputs:
            % - `net` Network in the GUILDA v2 format.
            % - `idx` Index of the bus whose generator is controlled.
            % - `Q` State weight matrix of the LQR (padded with zeros to the model size).
            % - `R` Input weight of the LQR; `Inf` gives a zero gain.
            % - `model` Environment model `(delta, E) -> (angleV, absV)` (ss); default: zero model.
            arguments (Output)
                obj % local_LQR_retrofit object.
            end
            obj@LocalController(net, idx, idx);
            if nargin<5
                model = [];
            end
            if isempty(model)
                model = ss(zeros(2,2));
                model.InputGroup.delta_m = 1;
                model.InputGroup.E_m = 2;
                model.OutputGroup.V_polar_m = 1:2;
                model.OutputGroup.angleV_m = 1;
                model.OutputGroup.absV_m = 2;
            end

            sys_local = net.a_bus{idx}.component.get_sys4retrofit();
            sys_ = blkdiag(sys_local, model);
            ig = sys_.InputGroup; og = sys_.OutputGroup;
            feedin = [ig.delta_m, ig.E_m, ig.angleV, ig.absV];
            feedout = [og.delta, og.E, og.angleV_m, og.absV_m];
            sys = feedback(sys_, eye(numel(feedin)), feedin, feedout, 1);
            obj.sys_design = sys;

            [A, Bu, ~, ~] = ssdata(sys(:, {'u_avr'}));
            % Bv = sys(:, {'angleV', 'absV'}).B;
            % Bw = sys(:, {'delta_m', 'E_m'}).B;

            [Al, Bl, Cl, ~] = ssdata(sys_local({'delta', 'E'}, {'angleV', 'absV'}));
            [Am, Bm, Cm, Dm] = ssdata(model);
            A_ = [Al+Bl*Dm*Cl, -Bl*Cm; -Bm*Cl, Am];
            Bv = [Bl; zeros(size(Bm))];
            Bw = [Bl*Dm; -Bm];
            % isequal(A, [Al+Bl*Dm*Cl, Bl*Cm; Bm*Cl, Am])
            % isequal(Bv, [Bl; zeros(size(Bm))])
            % isequal(Bw, [Bl*Dm; Bm])

            Q_ = zeros(size(A));
            Q_(1:size(Q, 1), 1:size(Q, 2)) = Q;
            if isinf(R)
                obj.K = zeros(1, size(A, 1));
            else
                obj.K = lqr(A, Bu, Q_, R);
            end
            obj.sys_fb = ss((A-Bu*obj.K), -Bu, [eye(size(A)); obj.K], 0);
            obj.sys_fb.InputGroup.u_retrofit = 1;
            obj.sys_fb.OutputGroup.x_retrofit = 1:size(A, 1);
            obj.sys_fb.OutputGroup.u_retrofit = size(A, 1)+1;

            obj.A = A_;
            obj.Bu = Bu;
            obj.Bw = Bw;
            obj.Bv = Bv;

            obj.nx = size(A, 1);
            obj.X0 = net.a_bus{idx}.component.x_equilibrium;
            obj.V0 = tools.complex2vec(net.a_bus{idx}.component.V_equilibrium);
            obj.I0 = tools.complex2vec(net.a_bus{idx}.component.I_equilibrium);
            obj.u0 = net.a_bus{idx}.component.u_equilibrium;
            obj.delta0 = obj.X0(1);
            obj.E0 = obj.X0(3);
        end

        function nx = get_nx(obj)
            % Return the number of controller states.
            arguments (Output)
                nx % Number of states.
            end
            nx = obj.nx;
        end

        function nu = get_nu(obj)
            % Return the number of controller outputs (2).
            arguments (Output)
                nu % Number of outputs.
            end
            nu = 2;
        end

        function initialize(obj)
            % Do nothing; the controller is set up by the constructor.
            % レトロフィット制御器導入時は解列シミュレーション不可
        end

        function [dx, u] = get_dx_u(obj, t, x, X, Vcell, Icell, U, is_linear)
            % Return the state derivative and the input to the generator.
            %
            % Inputs:
            % - `t` [s] Time (unused).
            % - `x` Controller state.
            % - `X` Cell array with the generator state.
            % - `Vcell` [pu] Cell array with the terminal voltage `[real; imag]`.
            % - `Icell` [pu] Cell array with the terminal current (unused).
            % - `U` Global input (unused).
            % - `is_linear` true to use the linearized polar transform (default false).
            %
            % Outputs:
            % - `dx` Controller state derivative.
            % - `u` Cell array with the input to the generator.
            if nargin < 8
                is_linear = false;
            end
            x1 = x(1:numel(obj.X0));
            x2 = x(numel(obj.X0)+1:end);
            u = zeros(2, 1);
            u(1) = obj.K*[(X{1}-obj.X0-x1); x2];

            delta = X{1}(1); delta0 = obj.delta0;
            E = X{1}(3); E0 = obj.E0;

            V = cell2mat(Vcell);

            if is_linear
                R_V = tools.matrix_polar_transform(obj.V0(1)+1j*obj.V0(2));
                V_linear = R_V*V; V0_linear = R_V*obj.V0;
                angleV = V_linear(1); absV = V_linear(2);
                angleV0 = V0_linear(1); absV0 = V0_linear(2);
            else
                angleV = atan2(V(2), V(1)); absV = norm(V);
                angleV0 = atan2(obj.V0(2), obj.V0(1)); absV0 = norm(obj.V0);
            end

            dx = obj.A*x + obj.Bv*[angleV-angleV0; absV-absV0] - obj.Bw*[delta-delta0; E-E0];
            u = num2cell(u(:), 1);

        end

        function [dx, u] = get_dx_u_linear(obj, t, x, X, Vcell, Icell, U)
            % Return the state derivative and the input with the linearized polar transform.
            % Same as get_dx_u with `is_linear = true`.
            %
            % Outputs:
            % - `dx` Controller state derivative.
            % - `u` Cell array with the input to the generator.
            [dx, u] = get_dx_u(obj, t, x, X, Vcell, Icell, U, true);
        end

        % シミュレーションを実行できるようにするための一時的な実装なので要修正
        function [A, BX, BV, BI, Bu, C, DX, DV, DI, Du] = get_linear_matrix(obj)
            % Return empty state-space matrices so that a simulation can run.
            arguments (Output)
                A  % Empty matrix.
                BX % Empty matrix.
                BV % Empty matrix.
                BI % Empty matrix.
                Bu % Empty matrix.
                C  % Empty matrix.
                DX % Empty matrix.
                DV % Empty matrix.
                DI % Empty matrix.
                Du % Empty matrix.
            end
            A = [];
            BX = [];
            BV = [];
            BI = [];
            Bu = [];
            C = [];
            DX = [];
            DV = [];
            DI = [];
            Du = [];
        end
    end
end
