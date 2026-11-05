classdef BadControllerStub < LocalController
% validate が制御器の契約違反を検出することを確かめるための制御器 (テスト専用)
%
%   con = DebugScript.helper.BadControllerStub("jacobian")
%   gen.add_local_controller(con)
%
% 入力 omega は発電機の出力、Vppss は綴りの誤りで未接続。出力 Vfield を発電機へ返す。
% 正常な形は dx = u1, y = x, 平衡点 x = Vfield。引数で次の1つの誤りを入れる。
%   jacobian   : Axx の値が誤り
%   jacsize    : Axx の大きさが誤り
%   xsize      : 平衡点の x が 2 要素
%   massx      : fcn_Mass が x を使う
%   currentdep : fcn_dx が I に依存する
%   residual   : fcn_dx が平衡点で 0 にならない
%   output     : 出力が発電機の入力と合わない
%   input      : 入力の平衡点が発電機の出力と合わない
    properties (SetAccess=protected, Hidden)
        key     = "local"
        sv_x    = "x1"
        sv_u    = ["omega";"Vppss"]
        sv_y    = "Vfield"
        sv_para = "bad"
    end
    properties
        l_xsizeLater (1,1) logical = false   % 次の get_equilibrium から xsize にする (initialize の後で validate を試す)
    end
    properties (Constant, Hidden)
        sv_bad = ["none","jacobian","jacsize","xsize","massx","currentdep","residual","output","input"]
    end
    methods
        function obj = BadControllerStub(str_bad)
            arguments (Input)
                str_bad  % 入れる誤りの種類 (sv_bad のいずれか)
            end
            arguments (Output)
                obj  % 作成したオブジェクト
            end
            obj@LocalController("CLbad")
            obj.para_dynamics.add_entry("bad", find(obj.sv_bad == str_bad), "double");
        end
        function get_equilibrium(obj, ~, u)
            arguments (Input)
                obj
                ~
                u    % 機器の平衡点の入力
            end
            obj.rv_Xequilibrium = u(2);
            if obj.sv_bad(obj.para_dynamics.bad) == "xsize" || obj.l_xsizeLater
                obj.rv_Xequilibrium = [u(2); 0];
            end
            obj.rv_Uequilibrium = [0; 0];
            if obj.sv_bad(obj.para_dynamics.bad) == "input"
                obj.rv_Uequilibrium = [0.2; 0];
            end
        end
    end
    methods (Static)
        function dx = fcn_dx(~, ~, ~, I, u, param, ~)
            arguments (Input)
                ~
                ~
                ~
                I      % [pu] 母線電流 [real; imag]
                u      % 入力
                param  % 動的パラメータ (sv_para の順)
                ~
            end
            arguments (Output)
                dx  % 状態方程式の右辺
            end
            dx = u(1);
            if DebugScript.helper.BadControllerStub.sv_bad(param) == "currentdep"
                dx = dx + 1e-3*I(1);
            elseif DebugScript.helper.BadControllerStub.sv_bad(param) == "residual"
                dx = dx + 0.1;
            end
        end
        function y = fcn_y(~, x, ~, ~, ~, param, ~)
            arguments (Input)
                ~
                x      % 状態
                ~
                ~
                ~
                param  % 動的パラメータ (sv_para の順)
                ~
            end
            arguments (Output)
                y  % 出力
            end
            y = x(1);
            if DebugScript.helper.BadControllerStub.sv_bad(param) == "output"
                y = y + 0.1;
            end
        end
        function M = fcn_Mass(~, x, ~, ~, ~, param, ~)
            arguments (Input)
                ~
                x      % 状態
                ~
                ~
                ~
                param  % 動的パラメータ (sv_para の順)
                ~
            end
            arguments (Output)
                M  % 質量行列
            end
            M = 1;
            if DebugScript.helper.BadControllerStub.sv_bad(param) == "massx"
                M = 1 + x(1)^2;
            end
        end
        function [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(~, ~, ~, ~, ~, param, ~)
            arguments (Input)
                ~
                ~
                ~
                ~
                ~
                param  % 動的パラメータ (sv_para の順)
                ~
            end
            arguments (Output)
                Axx  % fcn_dx の x によるヤコビアン
                Bxv  % fcn_dx の V によるヤコビアン
                Bxi  % fcn_dx の I によるヤコビアン
                Bxu  % fcn_dx の u によるヤコビアン
            end
            Axx = 0;  Bxv = zeros(1,2);  Bxi = zeros(1,2);  Bxu = [1, 0];
            if DebugScript.helper.BadControllerStub.sv_bad(param) == "jacobian"
                Axx = 5;
            elseif DebugScript.helper.BadControllerStub.sv_bad(param) == "jacsize"
                Axx = zeros(2);
            end
        end
        function [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(~, ~, ~, ~, ~, ~, ~)
            arguments (Input)
                ~
                ~
                ~
                ~
                ~
                ~
                ~
            end
            arguments (Output)
                Cyx  % fcn_y の x によるヤコビアン
                Dyv  % fcn_y の V によるヤコビアン
                Dyi  % fcn_y の I によるヤコビアン
                Dyu  % fcn_y の u によるヤコビアン
            end
            Cyx = 1;  Dyv = zeros(1,2);  Dyi = zeros(1,2);  Dyu = zeros(1,2);
        end
    end
end
