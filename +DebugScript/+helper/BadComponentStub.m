classdef BadComponentStub < Component
% validate が契約違反を検出することを確かめるための機器 (テスト専用、系統には追加しない)
%
%   comp = DebugScript.helper.BadComponentStub("equilibrium")
%
% 正常な形は dx = u - x, I = x1 + j x2, y = x1, 平衡点 x = u = [Ire; Iim]。
% 引数で次の1つの誤りを入れる ("none" は誤りなし)。
%   equilibrium : 平衡点が 0.1 ずれている
%   xsize       : get_equilibrium の x が 3 要素
%   currentreal : fcn_I が [re; im] を返す
%   massx       : fcn_Mass が x を使う
%   needpq      : get_equilibrium の r_P, r_Q が必須
%   currentdep  : fcn_dx が I に依存する
%   dxsize      : fcn_dx が 3 要素を返す
%   ysize       : fcn_Y が 2 要素を返す
%   masssize    : fcn_Mass が正方でない
%   dxerror     : fcn_dx がエラーで止まる
    properties (Constant)
        key = "test-bad-stub"                                                                                                      % 機器の種類のキー
        sv_x = ["x1";"x2"]                                                                                                         % 状態の名前
        sv_u = ["u1";"u2"]                                                                                                         % 入力の名前
        sv_y = "x1"                                                                                                                % 出力の名前
        sv_para = "bad"                                                                                                            % 動的パラメータの名前
        sr_bad = ["none","equilibrium","xsize","currentreal","massx","needpq","currentdep","dxsize","ysize","masssize","dxerror"]  % 入れられる誤りの種類 ("none" は誤りなし)
    end

    methods
        function obj = BadComponentStub(s_bad, s_tag, opt)
            arguments (Input)
                s_bad           % 入れる誤りの種類
                s_tag = "1"     % タグの接尾辞
                opt   = struct  % add_component の設定 (省略時は既定値)
            end
            arguments (Output)
                obj  % 作成したオブジェクト
            end
            if nargin < 3   % 系統につなぐときは add_component が渡す
                s_tag = "1";
                opt = struct("baseMVA",100, "Pmin",-inf, "Pmax",inf, "Qmin",-inf, "Qmax",inf, ...
                         "P",0, "Q",0, "OPFinit_P0",0, "OPFinit_Q0",0, "OPFcost_HP",1, ...
                         "OPFcost_HQ",0, "OPFcost_fP",1, "OPFcost_fQ",0, "OPFcost_startup",0, ...
                         "OPFcost_shutdown",0, "Xaxis",nan, "Yaxis",nan, "Marker","o", ...
                         "MidXaxis","", "MidYaxis","");
            end
            obj@Component("BS" + s_tag, opt);
            obj.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", obj.a_Parameter)}.add_entry("bad", find(obj.sr_bad == s_bad), "double");
        end

        function [x, u] = get_equilibrium(obj, ~, c_I, r_P, ~)
            arguments (Input)
                obj
                ~
                c_I  % [pu] 注入電流 (複素数)
                r_P  % [pu] 有効電力
                ~
            end
            arguments (Output)
                x  % 平衡点の状態
                u  % 平衡点の入力
            end
            s_bad = obj.sr_bad(obj.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", obj.a_Parameter)}.bad);
            if s_bad == "needpq"
                r_P; %#ok<VUNUS> 2 引数で呼ぶと MATLAB:minrhs になる
            end
            u = [real(c_I); imag(c_I)];
            x = u;
            if s_bad == "equilibrium"
                x = x + 0.1;
            elseif s_bad == "xsize"
                x = [x; 0];
            end
        end
    end

    methods (Static)
        function dx = fcn_dx(~, x, ~, I, u, param, ~)
            arguments (Input)
                ~
                x      % 状態
                ~
                I      % [pu] 母線電流 [real; imag]
                u      % 入力
                param  % 動的パラメータ (sv_para の順)
                ~
            end
            arguments (Output)
                dx  % 状態方程式の右辺
            end
            dx = u - x;
            if DebugScript.helper.BadComponentStub.sr_bad(param) == "currentdep"
                dx = dx + 1e-3*I(1);
            elseif DebugScript.helper.BadComponentStub.sr_bad(param) == "dxsize"
                dx = [dx; 0];
            elseif DebugScript.helper.BadComponentStub.sr_bad(param) == "dxerror"
                error("test:BadComponentStub", "stub stopped")
            end
        end
        function I = fcn_I(~, x, ~, ~, ~, param, ~)
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
                I  % [pu] 母線への注入電流 (複素数)
            end
            I = x(1) + 1j*x(2);
            if DebugScript.helper.BadComponentStub.sr_bad(param) == "currentreal"
                I = [x(1); x(2)];
            end
        end
        function y = fcn_Y(~, x, ~, ~, ~, param, ~)
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
            if DebugScript.helper.BadComponentStub.sr_bad(param) == "ysize"
                y = [x(1); x(2)];
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
            M = eye(2);
            if DebugScript.helper.BadComponentStub.sr_bad(param) == "massx"
                M = (1 + x(1)^2) * M;
            elseif DebugScript.helper.BadComponentStub.sr_bad(param) == "masssize"
                M = eye(3);
            end
        end
    end
end
