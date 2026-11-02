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
        key     = "test-bad-stub"
        sv_x    = ["x1";"x2"]
        sv_u    = ["u1";"u2"]
        sv_y    = "x1"
        sv_para = "bad"
        sv_bad  = ["none","equilibrium","xsize","currentreal","massx","needpq","currentdep","dxsize","ysize","masssize","dxerror"]
    end

    methods
        function obj = BadComponentStub(str_bad, str_tag, opt)
            if nargin < 3   % 系統につなぐときは add_component が渡す
                str_tag = "1";
                opt = struct("baseMVA",100, "Pmin",-inf, "Pmax",inf, "Qmin",-inf, "Qmax",inf, ...
                         "P",0, "Q",0, "OPFinit_P0",0, "OPFinit_Q0",0, "OPFcost_HP",1, ...
                         "OPFcost_HQ",0, "OPFcost_fP",1, "OPFcost_fQ",0, "OPFcost_startup",0, ...
                         "OPFcost_shutdown",0, "Xaxis",nan, "Yaxis",nan, "Marker","o", ...
                         "MidXaxis","", "MidYaxis","");
            end
            obj@Component("BS" + str_tag, opt);
            obj.para_dynamics.add_entry("bad", find(obj.sv_bad == str_bad), "double");
            obj.set_odefcn();
        end

        function [x, u] = get_equilibrium(obj, ~, c_I, r_P, ~)
            str_bad = obj.sv_bad(obj.para_dynamics.bad);
            if str_bad == "needpq"
                r_P; %#ok<VUNUS> 2 引数で呼ぶと MATLAB:minrhs になる
            end
            u = [real(c_I); imag(c_I)];
            x = u;
            if str_bad == "equilibrium"
                x = x + 0.1;
            elseif str_bad == "xsize"
                x = [x; 0];
            end
        end
    end

    methods (Static)
        function dx = fcn_dx(~, x, ~, I, u, param, ~)
            dx = u - x;
            if DebugScript.helper.BadComponentStub.sv_bad(param) == "currentdep"
                dx = dx + 1e-3*I(1);
            elseif DebugScript.helper.BadComponentStub.sv_bad(param) == "dxsize"
                dx = [dx; 0];
            elseif DebugScript.helper.BadComponentStub.sv_bad(param) == "dxerror"
                error("test:BadComponentStub", "stub stopped")
            end
        end
        function I = fcn_I(~, x, ~, ~, ~, param, ~)
            I = x(1) + 1j*x(2);
            if DebugScript.helper.BadComponentStub.sv_bad(param) == "currentreal"
                I = [x(1); x(2)];
            end
        end
        function y = fcn_Y(~, x, ~, ~, ~, param, ~)
            y = x(1);
            if DebugScript.helper.BadComponentStub.sv_bad(param) == "ysize"
                y = [x(1); x(2)];
            end
        end
        function M = fcn_Mass(~, x, ~, ~, ~, param, ~)
            M = eye(2);
            if DebugScript.helper.BadComponentStub.sv_bad(param) == "massx"
                M = (1 + x(1)^2) * M;
            elseif DebugScript.helper.BadComponentStub.sv_bad(param) == "masssize"
                M = eye(3);
            end
        end
    end
end
