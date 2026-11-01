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
    properties (SetAccess=protected, Hidden)
        key     = "local"
        sv_x    = "x1"
        sv_u    = ["omega";"Vppss"]
        sv_y    = "Vfield"
        sv_para = "bad"
    end
    properties (Constant, Hidden)
        sv_bad = ["none","jacobian","jacsize","xsize","massx","currentdep"]
    end
    methods
        function obj = BadControllerStub(str_bad)
            obj@LocalController("CLbad")
            obj.para_dynamics.add_entry("bad", find(obj.sv_bad == str_bad), "double");
            obj.set_odefcn(obj.r_Hz)
        end
        function get_equilibrium(obj, ~, u)
            obj.rv_Xequilibrium = u(2);
            if obj.sv_bad(obj.para_dynamics.bad) == "xsize"
                obj.rv_Xequilibrium = [u(2); 0];
            end
            obj.rv_Uequilibrium = [0; 0];
        end
    end
    methods (Static)
        function dx = fcn_dx(~, ~, ~, I, u, param, ~)
            dx = u(1);
            if DebugScript.helper.BadControllerStub.sv_bad(param) == "currentdep"
                dx = dx + 1e-3*I(1);
            end
        end
        function y = fcn_y(~, x, ~, ~, ~, ~, ~)
            y = x(1);
        end
        function M = fcn_Mass(~, x, ~, ~, ~, param, ~)
            M = 1;
            if DebugScript.helper.BadControllerStub.sv_bad(param) == "massx"
                M = 1 + x(1)^2;
            end
        end
        function [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(~, ~, ~, ~, ~, param, ~)
            Axx = 0;  Bxv = zeros(1,2);  Bxi = zeros(1,2);  Bxu = [1, 0];
            if DebugScript.helper.BadControllerStub.sv_bad(param) == "jacobian"
                Axx = 5;
            elseif DebugScript.helper.BadControllerStub.sv_bad(param) == "jacsize"
                Axx = zeros(2);
            end
        end
        function [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(~, ~, ~, ~, ~, ~, ~)
            Cyx = 1;  Dyv = zeros(1,2);  Dyi = zeros(1,2);  Dyu = zeros(1,2);
        end
    end
end
