classdef HessianStub < Component
% get_hessian の契約を確かめるための機器 (テスト専用、系統には追加しない)
%
%   dx = [x1^2 * Vre; x1 * u]   (x = [x1; x2], u はスカラー)
%   I  = x2 * (Vre + j Vim)
%   y  = x1
% Hessian_dx だけを定義し、Hessian_I / Hessian_Y は定義しない。
    properties (Constant)
        key     = "test-hessian-stub"
        sv_x    = ["x1";"x2"]
        sv_u    = "w"
        sv_y    = "x1"
        sv_para = strings(0,1)
    end

    methods
        function obj = HessianStub()
            opt = struct("baseMVA",100, "Pmin",-inf, "Pmax",inf, "Qmin",-inf, "Qmax",inf, ...
                         "P",0, "Q",0, "OPFinit_P0",0, "OPFinit_Q0",0, "OPFcost_HP",1, ...
                         "OPFcost_HQ",0, "OPFcost_fP",1, "OPFcost_fQ",0, "OPFcost_startup",0, ...
                         "OPFcost_shutdown",0, "Xaxis",nan, "Yaxis",nan, "Marker","o", ...
                         "MidXaxis","", "MidYaxis","");
            obj@Component("HS1", opt);
            obj.set_odefcn(obj.r_Hz);
        end

        function [x, u] = get_equilibrium(~, ~, ~, ~, ~)
            x = zeros(2,1);
            u = 0;
        end
    end

    methods (Static)
        function dx = fcn_dx(~, x, V, ~, u, ~, ~)
            dx = [x(1)^2 * V(1); x(1) * u(1)];
        end
        function I = fcn_I(~, x, V, ~, ~, ~, ~)
            I = x(2) * (V(1) + 1j*V(2));
        end
        function y = fcn_Y(~, x, ~, ~, ~, ~, ~)
            y = x(1);
        end
        function M = fcn_Mass(~, ~, ~, ~, ~, ~, ~)
            M = eye(2);
        end

        function H = Hessian_dx(~, x, V, ~, ~, ~, ~)
            % z = [x1 x2 Vre Vim Ire Iim w]
            H = zeros(2, 7, 7);
            H(1,1,1) = 2*V(1);
            H(1,1,3) = 2*x(1);  H(1,3,1) = 2*x(1);
            H(2,1,7) = 1;       H(2,7,1) = 1;
        end
    end
end
