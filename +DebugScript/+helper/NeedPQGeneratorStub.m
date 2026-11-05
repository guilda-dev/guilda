classdef NeedPQGeneratorStub < component.generator.abstract
% get_equilibrium の r_P, r_Q が必須の発電機 (Issue 105 のトリップの確認用)
%
% dx = u - x, I = x1 + j x2。 test_I105 が component.generator にコピーして登録する。
    properties (Constant)
        key     = "gen-needpq-stub"
        sv_x    = ["x1";"x2"]
        sv_u    = ["u1";"u2"]
        sv_y    = strings(0,1)
        sv_para = ["M","D"]
    end
    methods
        function [x, u] = get_equilibrium(~, ~, c_I, r_P, r_Q)
            arguments (Input)
                ~
                ~
                c_I  % [pu] 注入電流 (複素数)
                r_P  % [pu] 有効電力
                r_Q  % [pu] 無効電力
            end
            arguments (Output)
                x  % 平衡点の状態
                u  % 平衡点の入力
            end
            assert(isnumeric(r_P) && isnumeric(r_Q))
            u = [real(c_I); imag(c_I)];
            x = u;
        end
    end
    methods (Static)
        function dx = fcn_dx(~, x, ~, ~, u, ~, ~)
            arguments (Input)
                ~
                x  % 状態
                ~
                ~
                u  % 入力
                ~
                ~
            end
            arguments (Output)
                dx  % 状態方程式の右辺
            end
            dx = u - x;
        end
        function I = fcn_I(~, x, ~, ~, ~, ~, ~)
            arguments (Input)
                ~
                x  % 状態
                ~
                ~
                ~
                ~
                ~
            end
            arguments (Output)
                I  % [pu] 母線への注入電流 (複素数)
            end
            I  = x(1) + 1j*x(2);
        end
        function y = fcn_Y(varargin)
            arguments (Input, Repeating)
                varargin  % 使わない入力
            end
            arguments (Output)
                y  % 出力
            end
            y  = zeros(0,1);
        end
        function M = fcn_Mass(varargin)
            arguments (Input, Repeating)
                varargin  % 使わない入力
            end
            arguments (Output)
                M  % 質量行列
            end
            M  = eye(2);
        end
    end
end
