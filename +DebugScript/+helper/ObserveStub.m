classdef ObserveStub < LocalController
% 観測 (入力名による機器の出力・状態の読み取り) と Component.add_local_controller の検査を確かめるための制御器
%
%   c   = DebugScript.helper.register_stub("ObserveStub", "controller.test_observe");
%   con = gen.add_local_controller("test-observe", parameter=struct(Input="Xall"));
%
% 状態を持たず、入力 sv_u と出力 sv_y を与えた名前にする (予約語 "Xall" / "Yall" は付けるときに展開)。
% 役割 s_role は register_stub の Replace で写しごとに変える ("avr", "pss", "governor" など)。
    properties (Constant, Hidden)
        key = "test-observe"    % モデルのキー (register_stub が写しのクラス名に置き換える)
        s_role = "local"        % 役割 ("local": AVR の位置に付ける)
    end
    properties (SetAccess=protected, Hidden)
        sv_x = strings(0,1)     % 状態の名前
        sv_u = strings(0,1)     % 入力の名前 (コンストラクタで与える。"Xall" / "Yall" は付けるときに展開)
        sv_y = strings(0,1)     % 出力の名前
        sv_para = strings(0,1)  % 動的パラメータの名前
    end
    methods
        function obj = ObserveStub(tag, opt)
            arguments (Input)
                tag         % タグの接尾辞 (タグは "CS" + tag)
                opt.Input   = strings(0,1)  % 入力名 (予約語 "Xall" / "Yall" も可)
                opt.Output  = strings(0,1)  % 出力名
            end
            arguments (Output)
                obj  % 作成したオブジェクト
            end
            obj@LocalController("CS"+tag)
            obj.sv_u = reshape(string(opt.Input), [], 1);
            obj.sv_y = reshape(string(opt.Output), [], 1);
        end
        function get_equilibrium(obj, V, u)
            arguments (Input)
                obj
                V    % [pu] 機器の平衡点の端子電圧 (複素数)
                u    % 機器の平衡点の入力
            end
            obj.rv_Xequilibrium = zeros(0,1);
            obj.rv_Uequilibrium = zeros(numel(obj.sv_u),1);
        end
    end
    methods (Access=protected)
        function set_inputs(obj, sv_name)
            arguments (Input)
                obj
                sv_name  % 展開後の入力名
            end
            obj.sv_u = sv_name;
        end
    end
    methods (Static)
        function dx = fcn_dx(t, x, V, u, param, omega0)
            arguments (Input)
                t       % [s] 時刻
                x       % 状態
                V       % [pu] 母線電圧 [real; imag]
                u       % 入力
                param   % 動的パラメータ (sv_para の順)
                omega0  % [Hz] 系統周波数
            end
            arguments (Output)
                dx  % 状態方程式の右辺
            end
            dx = zeros(0,1);
        end
        function y = fcn_y(t, x, V, u, param, omega0)
            arguments (Input)
                t       % [s] 時刻
                x       % 状態
                V       % [pu] 母線電圧 [real; imag]
                u       % 入力
                param   % 動的パラメータ (sv_para の順)
                omega0  % [Hz] 系統周波数
            end
            arguments (Output)
                y  % 出力
            end
            y = zeros(0,1);
        end
        function M = fcn_Mass(t, x, V, u, param, omega0)
            arguments (Input)
                t       % [s] 時刻
                x       % 状態
                V       % [pu] 母線電圧 [real; imag]
                u       % 入力
                param   % 動的パラメータ (sv_para の順)
                omega0  % [Hz] 系統周波数
            end
            arguments (Output)
                M  % 質量行列
            end
            M = zeros(0,0);
        end
        function [Axx,Bxv,Bxu] = Jacobi_dx(t, x, V, u, param, omega0)
            arguments (Input)
                t       % [s] 時刻
                x       % 状態
                V       % [pu] 母線電圧 [real; imag]
                u       % 入力
                param   % 動的パラメータ (sv_para の順)
                omega0  % [Hz] 系統周波数
            end
            arguments (Output)
                Axx  % fcn_dx の x によるヤコビアン
                Bxv  % fcn_dx の V によるヤコビアン
                Bxu  % fcn_dx の u によるヤコビアン
            end
            Axx = zeros(0,0);  Bxv = zeros(0,2);  Bxu = zeros(0,numel(u));
        end
        function [Cyx,Dyv,Dyu] = Jacobi_Y(t, x, V, u, param, omega0)
            arguments (Input)
                t       % [s] 時刻
                x       % 状態
                V       % [pu] 母線電圧 [real; imag]
                u       % 入力
                param   % 動的パラメータ (sv_para の順)
                omega0  % [Hz] 系統周波数
            end
            arguments (Output)
                Cyx  % fcn_y の x によるヤコビアン
                Dyv  % fcn_y の V によるヤコビアン
                Dyu  % fcn_y の u によるヤコビアン
            end
            Cyx = zeros(0,0);  Dyv = zeros(0,2);  Dyu = zeros(0,numel(u));
        end
    end
end
