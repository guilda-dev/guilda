classdef BadPortStub < Component
% 入力名にポート名 (Vre) を使った機器。validate の検査を確かめる (テスト専用。DebugScript.helper.stub_component で母線に付ける)
    properties (Constant)
        key = "test-bad-port-stub"  % 機器の種類のキー
        sv_x = strings(0,1)         % 状態の名前
        sv_u = "Vre"                % 入力の名前 (ポート名 Vre を使った誤り)
        sv_y = strings(0,1)         % 出力の名前
        sv_para = strings(0,1)      % 動的パラメータの名前
    end
    methods
        function obj = BadPortStub(s_tag, ~, opt)
            % add_component から (タグの番号, parameter, 設定) で呼ばれる
            arguments (Input)
                s_tag  % タグの接尾辞
                ~      % add_component の parameter (使わない)
                opt    % add_component の設定
            end
            arguments (Output)
                obj  % 作成したオブジェクト
            end
            obj@Component("BP" + s_tag, opt);
        end
        function [x, u] = get_equilibrium(~, ~, ~, ~, ~)
            arguments (Input)
                ~
                ~
                ~
                ~
                ~
            end
            arguments (Output)
                x  % 平衡点の状態
                u  % 平衡点の入力
            end
            x = zeros(0,1);
            u = 0;
        end
    end
    methods (Static)
        function dx = fcn_dx(~, ~, ~, ~, ~, ~)
            arguments (Input)
                ~
                ~
                ~
                ~
                ~
                ~
            end
            arguments (Output)
                dx  % 状態方程式の右辺
            end
            dx = zeros(0,1);
        end
        function I = fcn_I(~, ~, ~, ~, ~, ~)
            arguments (Input)
                ~
                ~
                ~
                ~
                ~
                ~
            end
            arguments (Output)
                I  % [pu] 母線への注入電流 (複素数)
            end
            I = 0j;
        end
        function y = fcn_Y(~, ~, ~, ~, ~)
            arguments (Input)
                ~
                ~
                ~
                ~
                ~
            end
            arguments (Output)
                y  % 出力
            end
            y = zeros(0,1);
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
            M = zeros(0,0);
        end
    end
end
