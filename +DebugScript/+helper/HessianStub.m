classdef HessianStub < Component
% get_hessian の契約を確かめるための機器 (テスト専用、系統には追加しない)
%
%   dx = [x1^2 * Vre; x1 * u]   (x = [x1; x2], u はスカラー)
%   I  = x2 * (Vre + j Vim)
%   y  = x1
% Hessian_dx だけを定義し、Hessian_I / Hessian_Y は定義しない。
    properties (Constant)
        key = "test-hessian-stub"  % 機器の種類のキー
        sv_x = ["x1";"x2"]         % 状態の名前
        sv_u = "w"                 % 入力の名前
        sv_y = "x1"                % 出力の名前
        sv_para = strings(0,1)     % 動的パラメータの名前
    end

    methods
        function obj = HessianStub()
            arguments (Output)
                obj  % 作成したオブジェクト
            end
            opt = struct("baseMVA",100, "Pmin",-inf, "Pmax",inf, "Qmin",-inf, "Qmax",inf, ...
                         "P",0, "Q",0, "OPFinit_P0",0, "OPFinit_Q0",0, "OPFcost_HP",1, ...
                         "OPFcost_HQ",0, "OPFcost_fP",1, "OPFcost_fQ",0, "OPFcost_startup",0, ...
                         "OPFcost_shutdown",0, "Xaxis",nan, "Yaxis",nan, "Marker","o", ...
                         "MidXaxis","", "MidYaxis","", "BusTag","");
            obj@Component("HS1", opt);
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
            x = zeros(2,1);
            u = 0;
        end
    end

    methods (Static)
        function dx = fcn_dx(~, x, V, u, ~, ~)
            arguments (Input)
                ~
                x  % 状態
                V  % [pu] 母線電圧 [real; imag]
                u  % 入力
                ~
                ~
            end
            arguments (Output)
                dx  % 状態方程式の右辺
            end
            dx = [x(1)^2 * V(1); x(1) * u(1)];
        end
        function I = fcn_I(~, x, V, ~, ~, ~)
            arguments (Input)
                ~
                x  % 状態
                V  % [pu] 母線電圧 [real; imag]
                ~
                ~
                ~
            end
            arguments (Output)
                I  % [pu] 母線への注入電流 (複素数)
            end
            I = x(2) * (V(1) + 1j*V(2));
        end
        function y = fcn_Y(~, x, ~, ~, ~)
            arguments (Input)
                ~
                x  % 状態
                ~
                ~
                ~
            end
            arguments (Output)
                y  % 出力
            end
            y = x(1);
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
            M = eye(2);
        end

        function H = Hessian_dx(~, x, V, ~, ~, ~)
            % z = [x1 x2 Vre Vim w]
            arguments (Input)
                ~
                x  % 状態
                V  % [pu] 母線電圧 [real; imag]
                ~
                ~
                ~
            end
            arguments (Output)
                H  % fcn_dx の [x; V; u] による 2 階微分
            end
            H = zeros(2, 5, 5);
            H(1,1,1) = 2*V(1);
            H(1,1,3) = 2*x(1);  H(1,3,1) = 2*x(1);
            H(2,1,5) = 1;       H(2,5,1) = 1;
        end
    end
end
