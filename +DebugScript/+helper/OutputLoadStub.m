classdef OutputLoadStub < component.load.abstract
% 出力を持つ定電流負荷 (テスト専用。Feedback が消去する母線の機器の出力を GC が読むことを確かめるため)
%
%   c  = DebugScript.helper.register_stub("OutputLoadStub", "component.load.test_output_load");
%   ld = net.a_Bus{4}.add_component("test-output-load");
%
% 状態はない。入力 u = [Ire; Iim] は母線への注入電流、出力 Vabs は母線電圧の大きさ:
%   I = Ire + j*Iim,   y = |V|
% 電流は V によらない (Div = 0) ので I-to-V の形がなく、Feedback はこの母線をネットワークと一緒に消去する。
    properties (Constant)
        key = "test-output-load"   % 機器の種類のキー (register_stub が写しのクラス名に置き換える)
        sv_x = strings(0,1)        % 状態の名前
        sv_u = ["Ire";"Iim"]       % 入力の名前
        sv_y = "Vabs"              % 出力の名前
        sv_para = strings(0,1)     % 動的パラメータの名前
    end
    methods
        function [x, u] = get_equilibrium(~, ~, c_I, ~, ~)
            arguments (Input)
                ~
                ~
                c_I  % [pu] 平衡点の注入電流 (複素数)
                ~
                ~
            end
            arguments (Output)
                x  % 平衡点の状態
                u  % 平衡点の入力
            end
            x = zeros(0,1);
            u = [real(c_I); imag(c_I)];
        end
    end
    methods (Static)
        function dx = fcn_dx(varargin)
            arguments (Input, Repeating)
                varargin  % 使わない入力
            end
            arguments (Output)
                dx  % 状態方程式の右辺
            end
            dx = zeros(0,1);
        end
        function I = fcn_I(~, ~, ~, u, ~, ~)
            arguments (Input)
                ~
                ~
                ~
                u  % 入力 [Ire; Iim]
                ~
                ~
            end
            arguments (Output)
                I  % [pu] 母線への注入電流 (複素数)
            end
            I = [1, 1j] * u;
        end
        function y = fcn_Y(~, ~, V, ~, ~)
            arguments (Input)
                ~
                ~
                V  % [pu] 母線電圧 [Vre; Vim]
                ~
                ~
            end
            arguments (Output)
                y  % 出力 (母線電圧の大きさ)
            end
            y = norm(V);
        end
        function M = fcn_Mass(varargin)
            arguments (Input, Repeating)
                varargin  % 使わない入力
            end
            arguments (Output)
                M  % 質量行列
            end
            M = zeros(0);
        end
        function [Cix,Div,Diu] = Jacobi_I(varargin)
            arguments (Input, Repeating)
                varargin  % 使わない入力
            end
            arguments (Output)
                Cix  % fcn_I の x によるヤコビアン
                Div  % fcn_I の V によるヤコビアン
                Diu  % fcn_I の u によるヤコビアン
            end
            Cix = zeros(2,0);
            Div = zeros(2);
            Diu = eye(2);
        end
        function [Cyx,Dyv] = Jacobi_Y(~, ~, V, ~, ~)
            arguments (Input)
                ~
                ~
                V  % [pu] 母線電圧 [Vre; Vim]
                ~
                ~
            end
            arguments (Output)
                Cyx  % fcn_Y の x によるヤコビアン
                Dyv  % fcn_Y の V によるヤコビアン
            end
            Cyx = zeros(1,0);
            Dyv = V.' / norm(V);
        end
    end
end
