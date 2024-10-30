classdef local_LQR_retrofit <  controller
% モデル  ：内部制御器がLQRのレトロフィットコントローラ
% 親クラス：controllerクラス
% 実行方法：obj = local_LQR_retrofit(net, idx, Q, R, model, model_agc)
% 　引数　：・net  ：networkクラスのインスタンス
% 　　　　　・　idx  ： double配列。制御対象の母線番号
% 　　　　　・　Q  ： double配列。状態量の重み行列
% 　　　　　・　R  ： double配列。入力量の重み行列
% 　　　　　・　model  ：ss型。環境モデルの一部 （(delta, E)->(angleV, absV)）。入出力は極座標表示。+controller/+modeling/get_environmentで取得
% 　出力　：controllerクラスのインスタンス

    properties(SetAccess=protected)
        type = 'local';
        port_input = 'all';
        port_observe = 'all';
    end

    properties
        A
        Bu
        Bw
        Bv
        K
        nx
        X0
        V0
        I0
        u0
        delta0
        E0
        sys_design
        sys_fb
    end

    methods
        function obj = local_LQR_retrofit(net, idx, Q, R, model)
            obj@controller(net, idx, idx);
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
            obj.sys_fb = ss((A-Bu*obj.K), Bu, [eye(size(A)); -obj.K], 0);
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
            nx = obj.nx;
        end

        function nu = get_nu(obj)
            nu = 2;
        end

        function initialize(obj)
            % レトロフィット制御器導入時は解列シミュレーション不可
        end

        function [dx, u] = get_dx_u(obj, t, x, X, Vcell, Icell, U, is_linear)
            if nargin < 8
                is_linear = false;
            end
            x1 = x(1:numel(obj.X0));
            x2 = x(numel(obj.X0)+1:end);
            u = zeros(2, 1);
            u(1) = -obj.K*[(X{1}-obj.X0-x1); x2];

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
            [dx, u] = get_dx_u(obj, t, x, X, Vcell, Icell, U, true);
        end

        % シミュレーションを実行できるようにするための一時的な実装なので要修正
        function [A, BX, BV, BI, Bu, C, DX, DV, DI, Du] = get_linear_matrix(obj)
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
