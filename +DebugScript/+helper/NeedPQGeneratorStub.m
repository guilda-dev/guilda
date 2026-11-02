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
            assert(isnumeric(r_P) && isnumeric(r_Q))
            u = [real(c_I); imag(c_I)];
            x = u;
        end
    end
    methods (Static)
        function dx = fcn_dx(~, x, ~, ~, u, ~, ~); dx = u - x;         end
        function I  = fcn_I(~, x, ~, ~, ~, ~, ~);  I  = x(1) + 1j*x(2); end
        function y  = fcn_Y(varargin);             y  = zeros(0,1);     end
        function M  = fcn_Mass(varargin);          M  = eye(2);         end
    end
end
