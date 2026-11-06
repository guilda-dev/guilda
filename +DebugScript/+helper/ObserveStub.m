classdef ObserveStub < LocalController
% 観測 (入力名による機器の出力・状態の読み取り) を確かめるための制御器
%
%   con = DebugScript.helper.ObserveStub(["Xall"])
%   gen.add_local_controller(con)
%
% 状態も出力も持たず、入力 sv_u を与えた名前にする (予約語 "Xall" / "Yall" は付けるときに展開)。
    properties (SetAccess=protected, Hidden)
        key = "local"           % 制御器の種類 ("local": AVR の位置に付ける)
        sv_x = strings(0,1)     % 状態の名前
        sv_u = strings(0,1)     % 入力の名前 (コンストラクタで与える。"Xall" / "Yall" は付けるときに展開)
        sv_y = strings(0,1)     % 出力の名前
        sv_para = strings(0,1)  % 動的パラメータの名前
    end
    methods
        function obj = ObserveStub(sv_u)
            arguments (Input)
                sv_u  % 入力名 (予約語 "Xall" / "Yall" も可)
            end
            arguments (Output)
                obj  % 作成したオブジェクト
            end
            obj@LocalController("CSstub")
            obj.sv_u = reshape(string(sv_u), [], 1);
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
        function dx = fcn_dx(t, x, V, I, u, param, omega0)
            arguments (Input)
                t       % [s] 時刻
                x       % 状態
                V       % [pu] 母線電圧 [real; imag]
                I       % [pu] 母線電流 [real; imag]
                u       % 入力
                param   % 動的パラメータ (sv_para の順)
                omega0  % [Hz] 系統周波数
            end
            arguments (Output)
                dx  % 状態方程式の右辺
            end
            dx = zeros(0,1);
        end
        function y = fcn_y(t, x, V, I, u, param, omega0)
            arguments (Input)
                t       % [s] 時刻
                x       % 状態
                V       % [pu] 母線電圧 [real; imag]
                I       % [pu] 母線電流 [real; imag]
                u       % 入力
                param   % 動的パラメータ (sv_para の順)
                omega0  % [Hz] 系統周波数
            end
            arguments (Output)
                y  % 出力
            end
            y = zeros(0,1);
        end
        function M = fcn_Mass(t, x, V, I, u, param, omega0)
            arguments (Input)
                t       % [s] 時刻
                x       % 状態
                V       % [pu] 母線電圧 [real; imag]
                I       % [pu] 母線電流 [real; imag]
                u       % 入力
                param   % 動的パラメータ (sv_para の順)
                omega0  % [Hz] 系統周波数
            end
            arguments (Output)
                M  % 質量行列
            end
            M = zeros(0,0);
        end
        function [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t, x, V, I, u, param, omega0)
            arguments (Input)
                t       % [s] 時刻
                x       % 状態
                V       % [pu] 母線電圧 [real; imag]
                I       % [pu] 母線電流 [real; imag]
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
            Axx = zeros(0,0);  Bxv = zeros(0,2);  Bxi = zeros(0,2);  Bxu = zeros(0,numel(u));
        end
        function [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t, x, V, I, u, param, omega0)
            arguments (Input)
                t       % [s] 時刻
                x       % 状態
                V       % [pu] 母線電圧 [real; imag]
                I       % [pu] 母線電流 [real; imag]
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
            Cyx = zeros(0,0);  Dyv = zeros(0,2);  Dyi = zeros(0,2);  Dyu = zeros(0,numel(u));
        end
    end
end
