classdef RoutingGCStub < GlobalController
% グローバル制御器の観測と出力の振り分けを確かめるための制御器 (テスト専用)
%
%   c  = DebugScript.helper.register_stub("RoutingGCStub", "controller.test_routing_gc", ...
%            Replace=["sv_y = ""Pmech""", "sv_y = ""Pref"""]);
%   gc = net.add_global_controller("test-routing-gc", {gen}, parameter=struct(gV=0.5, V0=1.0));
%
% 状態 z が 1 つ。入力 u は制御対象ごとに sv_u、V は全母線の電圧 [Vre1; Vim1; ...]:
%   dz/dt = -z + sum(beta_i * u_i) + gV * (|V_1| - V0),   y = -alpha_i * z (制御対象ごとに sv_y の数)
% 平衡点は z = 0、u = 0 (omega のように平衡点で 0 になる出力を観測する。V0 は平衡点の |V_1|)。
% sv_u と sv_y は register_stub の Replace で写しごとに変える。
    properties (Constant, Hidden)
        key = "test-routing-gc"                % モデルのキー (register_stub が写しのクラス名に置き換える)
        s_role = "agc"                         % 役割
        sv_x = "z"                             % 状態の名前
        sv_u = "omega"                         % 入力の名前 (制御対象ごと)
        sv_y = "Pmech"                         % 出力の名前 (制御対象ごと)
        sv_para = ["alpha","beta","gV","V0"]   % 動的パラメータの名前
    end
    methods
        function obj = RoutingGCStub(net, tag, varargin, opt)
            arguments (Input)
                net      % 電力系統
                tag      % タグの接尾辞 (タグは "RG" + tag)
            end
            arguments (Input, Repeating)
                varargin  % 制御対象の機器
            end
            arguments (Input)
                opt.alpha (1,1) double = 1    % 出力の利得
                opt.beta  (1,1) double = 1    % 入力の利得
                opt.gV    (1,1) double = 0    % 母線 1 の電圧の大きさの利得
                opt.V0    (1,1) double = 1    % [pu] 平衡点の母線 1 の電圧の大きさ
            end
            arguments (Output)
                obj  % 作成したオブジェクト
            end
            obj@GlobalController(net, "RG"+tag, varargin{:});
            n = numel(obj.controlledUnits);
            obj.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", obj.a_Parameter)} = Parameter(obj, "dynamics", struct( ...
                "alpha", repmat(opt.alpha, [n,1]), "beta", repmat(opt.beta, [n,1]), ...
                "gV", repmat(opt.gV, [n,1]), "V0", repmat(opt.V0, [n,1])));
        end
        function [x, u] = get_equilibrium(obj)
            arguments (Input)
                obj
            end
            arguments (Output)
                x  % 平衡点の状態
                u  % 平衡点の入力
            end
            x = 0;
            u = zeros(numel(obj.controlledUnits)*numel(obj.sv_u), 1);
        end
    end
    methods (Static)
        function dx = fcn_dx(~, x, V, u, param, ~)
            arguments (Input)
                ~
                x      % 状態
                V      % [pu] 全母線の電圧
                u      % 入力
                param  % 動的パラメータ (制御対象ごとの行)
                ~
            end
            arguments (Output)
                dx  % 状態方程式の右辺
            end
            n_u = numel(u) / size(param,1);
            dx = -x + sum(repelem(param(:,2), n_u, 1) .* u) + param(1,3) * (norm(V(1:2)) - param(1,4));
        end
        function y = fcn_y(~, x, ~, ~, param, ~)
            arguments (Input)
                ~
                x      % 状態
                ~
                ~
                param  % 動的パラメータ (制御対象ごとの行)
                ~
            end
            arguments (Output)
                y  % 出力 (制御対象ごとに sv_y)
            end
            n_y = numel(DebugScript.helper.RoutingGCStub.sv_y);
            y = -repelem(param(:,1), n_y, 1) * x;
        end
        function M = fcn_Mass(~, ~, ~, ~, ~, ~)
            arguments (Input)
                ~
                ~
                ~
                ~
                ~
                ~
            end
            arguments (Output)
                M  % 質量行列
            end
            M = 1;
        end
        function [Axx,Bxv,Bxu] = Jacobi_dx(~, ~, V, u, param, ~)
            arguments (Input)
                ~
                ~
                V      % [pu] 全母線の電圧
                u      % 入力
                param  % 動的パラメータ (制御対象ごとの行)
                ~
            end
            arguments (Output)
                Axx  % fcn_dx の x によるヤコビアン
                Bxv  % fcn_dx の V によるヤコビアン
                Bxu  % fcn_dx の u によるヤコビアン
            end
            n_u = numel(u) / size(param,1);
            Axx = -1;
            Bxv = zeros(1, numel(V));
            Bxv(1:2) = param(1,3) * V(1:2).' / norm(V(1:2));
            Bxu = repelem(param(:,2), n_u, 1).';
        end
        function [Cyx,Dyv,Dyu] = Jacobi_Y(~, ~, V, u, param, ~)
            arguments (Input)
                ~
                ~
                V      % [pu] 全母線の電圧
                u      % 入力
                param  % 動的パラメータ (制御対象ごとの行)
                ~
            end
            arguments (Output)
                Cyx  % fcn_y の x によるヤコビアン
                Dyv  % fcn_y の V によるヤコビアン
                Dyu  % fcn_y の u によるヤコビアン
            end
            n_y = numel(DebugScript.helper.RoutingGCStub.sv_y);
            Cyx = -repelem(param(:,1), n_y, 1);
            Dyv = zeros(numel(Cyx), numel(V));
            Dyu = zeros(numel(Cyx), numel(u));
        end
    end
end
