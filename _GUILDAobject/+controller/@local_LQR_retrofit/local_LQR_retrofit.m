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
        type = 'local';        % Controller type ('local').
        port_input = 'all';    % Input ports of the generator that the controller drives.
        port_observe = 'all';  % Observed ports of the generator ('all'; the controller uses delta, omega, Ed and Vfield).
    end

    properties % Design results
        A                      % State matrix of the internal model.
        Bu                     % Input matrix of the internal model for the LQR input.
        Bw                     % Input matrix of the internal model for the deviation of `[delta; E]`.
        Bv                     % Input matrix of the internal model for the deviation of `[angleV; absV]`.
        K                      % LQR gain.
        nx                     % Number of controller states.
        X0                     % Equilibrium state of the generator.
        V0                     % [pu] Equilibrium terminal voltage as `[real; imag]`.
        I0                     % [pu] Equilibrium terminal current as `[real; imag]`.
        u0                     % Equilibrium input of the generator.
        delta0                 % [rad] Equilibrium rotor angle.
        E0                     % [pu] Equilibrium internal voltage.
        sys_design             % Generator and environment model used for the design (ss).
        sys_fb                 % State-feedback model of the controller (ss).
    end

    methods
        function obj = local_LQR_retrofit(net, idx, Q, R, model)
            % Create a retrofit controller for the generator at one bus.
            arguments (Input)
                net    % Network in the GUILDA v2 format.
                idx    % Index of the bus whose generator is controlled.
                Q      % State weight matrix of the LQR (padded with zeros to the model size).
                R      % Input weight of the LQR; `Inf` gives a zero gain.
                model = []  % Environment model `(delta, E) -> (angleV, absV)` (ss); empty: zero model.
            end
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
    end
end
