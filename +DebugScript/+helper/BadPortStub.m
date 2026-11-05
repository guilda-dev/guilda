classdef BadPortStub < Component
% 入力名にポート名 (Vre) を使った機器。validate の検査を確かめる (テスト専用)
    properties (Constant)
        key     = "test-bad-port-stub"
        sv_x    = strings(0,1)
        sv_u    = "Vre"
        sv_y    = strings(0,1)
        sv_para = strings(0,1)
    end
    methods
        function obj = BadPortStub()
            arguments (Output)
                obj  % 作成したオブジェクト
            end
            opt = struct("baseMVA",100, "Pmin",-inf, "Pmax",inf, "Qmin",-inf, "Qmax",inf, ...
                         "P",0, "Q",0, "OPFinit_P0",0, "OPFinit_Q0",0, "OPFcost_HP",1, ...
                         "OPFcost_HQ",0, "OPFcost_fP",1, "OPFcost_fQ",0, "OPFcost_startup",0, ...
                         "OPFcost_shutdown",0, "Xaxis",nan, "Yaxis",nan, "Marker","o", ...
                         "MidXaxis","", "MidYaxis","");
            obj@Component("BP1", opt);
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
        function dx = fcn_dx(~, ~, ~, ~, ~, ~, ~)
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
                dx  % 状態方程式の右辺
            end
            dx = zeros(0,1);
        end
        function I = fcn_I(~, ~, ~, ~, ~, ~, ~)
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
                I  % [pu] 母線への注入電流 (複素数)
            end
            I = 0j;
        end
        function y = fcn_Y(~, ~, ~, ~, ~, ~, ~)
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
                y  % 出力
            end
            y = zeros(0,1);
        end
        function M = fcn_Mass(~, ~, ~, ~, ~, ~, ~)
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
                M  % 質量行列
            end
            M = zeros(0,0);
        end
    end
end
