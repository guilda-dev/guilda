classdef BadAGCStub < GlobalController
% initialize が大域制御器の誤りを検出することを確かめるための AGC (テスト専用)
%
%   c   = DebugScript.helper.register_stub("BadAGCStub", "controller.test_bad_agc");
%   agc = net.add_global_controller("test-bad-agc", {comp}, parameter=struct(bad="output"));
%
% モデルは controller.agc.broadcast_PI_AGC (既定のパラメータ) と同じで、平衡点だけ誤る。
%   output : 積分器の平衡点が 0 でなく、出力が機器の入力を動かす
%   xsize  : 平衡点の x が 2 要素
    properties (Constant, Hidden)
        key = "test-bad-agc"                  % モデルのキー (register_stub が写しのクラス名に置き換える)
        s_role = "agc"                        % 役割
        sv_x = "xi"                           % 状態の名前
        sv_u = "omega"                        % 入力の名前 (制御対象ごと)
        sv_y = "Pmech"                        % 出力の名前 (制御対象ごと)
        sv_para = ["alpha","beta","kP","kI"]  % 動的パラメータの名前
    end
    properties (SetAccess=immutable)
        s_bad  % 入れる誤りの種類 ("output" / "xsize")
    end
    methods
        function obj = BadAGCStub(net, tag, varargin, opt)
            arguments (Input)
                net      % 電力系統
                tag      % タグの接尾辞 (タグは "AGC" + tag)
            end
            arguments (Input, Repeating)
                varargin  % 制御対象の機器
            end
            arguments (Input)
                opt.bad  = "output"  % 入れる誤りの種類 ("output" / "xsize")
            end
            arguments (Output)
                obj  % 作成したオブジェクト
            end
            obj@GlobalController(net, "AGC"+tag, varargin{:});
            n = numel(obj.controlledUnits);
            obj.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", obj.a_Parameter)} = Parameter(obj, "dynamics", struct( ...
                "alpha", ones(n,1), "beta", ones(n,1), "kP", repmat(100, [n,1]), "kI", repmat(500, [n,1])));
            obj.s_bad = opt.bad;
        end
        function [x, u] = get_equilibrium(obj)
            arguments (Input)
                obj
            end
            arguments (Output)
                x  % 平衡点の状態
                u  % 平衡点の入力
            end
            u = zeros(numel(obj.controlledUnits),1);
            if obj.s_bad == "output"
                x = 0.5;
            else
                x = [0; 0];
            end
        end
    end
    methods (Static)
        function dx = fcn_dx(t, x, V, I, u, param, omega0)
            arguments (Input)
                t       % [s] 時刻
                x       % 状態
                V       % ポート (使わない)
                I       % ポート (使わない)
                u       % 入力
                param   % 動的パラメータ (sv_para の順)
                omega0  % [Hz] 系統周波数
            end
            arguments (Output)
                dx  % 状態方程式の右辺
            end
            dx = controller.agc.broadcast_PI_AGC.fcn_dx(t, x, V, I, u, param, omega0);
        end
        function y = fcn_y(t, x, V, I, u, param, omega0)
            arguments (Input)
                t       % [s] 時刻
                x       % 状態
                V       % ポート (使わない)
                I       % ポート (使わない)
                u       % 入力
                param   % 動的パラメータ (sv_para の順)
                omega0  % [Hz] 系統周波数
            end
            arguments (Output)
                y  % 出力
            end
            y = controller.agc.broadcast_PI_AGC.fcn_y(t, x, V, I, u, param, omega0);
        end
        function M = fcn_Mass(t, x, V, I, u, param, omega0)
            arguments (Input)
                t       % [s] 時刻
                x       % 状態
                V       % ポート (使わない)
                I       % ポート (使わない)
                u       % 入力
                param   % 動的パラメータ (sv_para の順)
                omega0  % [Hz] 系統周波数
            end
            arguments (Output)
                M  % 質量行列
            end
            M = controller.agc.broadcast_PI_AGC.fcn_Mass(t, x, V, I, u, param, omega0);
        end
        function [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t, x, V, I, u, param, omega0)
            arguments (Input)
                t       % [s] 時刻
                x       % 状態
                V       % ポート (使わない)
                I       % ポート (使わない)
                u       % 入力
                param   % 動的パラメータ (sv_para の順)
                omega0  % [Hz] 系統周波数
            end
            arguments (Output)
                Axx  % fcn_dx の x によるヤコビアン
                Bxv  % fcn_dx の V によるヤコビアン
                Bxi  % fcn_dx の I によるヤコビアン
                Bxu  % fcn_dx の u によるヤコビアン
            end
            [Axx,Bxv,Bxi,Bxu] = controller.agc.broadcast_PI_AGC.Jacobi_dx(t, x, V, I, u, param, omega0);
        end
        function [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t, x, V, I, u, param, omega0)
            arguments (Input)
                t       % [s] 時刻
                x       % 状態
                V       % ポート (使わない)
                I       % ポート (使わない)
                u       % 入力
                param   % 動的パラメータ (sv_para の順)
                omega0  % [Hz] 系統周波数
            end
            arguments (Output)
                Cyx  % fcn_y の x によるヤコビアン
                Dyv  % fcn_y の V によるヤコビアン
                Dyi  % fcn_y の I によるヤコビアン
                Dyu  % fcn_y の u によるヤコビアン
            end
            [Cyx,Dyv,Dyi,Dyu] = controller.agc.broadcast_PI_AGC.Jacobi_Y(t, x, V, I, u, param, omega0);
        end
    end
end
