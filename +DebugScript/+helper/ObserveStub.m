classdef ObserveStub < LocalController
% 観測 (入力名による機器の出力・状態の読み取り) を確かめるための制御器
%
%   con = DebugScript.helper.ObserveStub(["Xall"])
%   gen.add_local_controller(con)
%
% 状態も出力も持たず、入力 sv_u を与えた名前にする (予約語 "Xall" / "Yall" は付けるときに展開)。
    properties (SetAccess=protected, Hidden)
        key     = "local"
        sv_x    = strings(0,1)
        sv_u    = strings(0,1)
        sv_y    = strings(0,1)
        sv_para = strings(0,1)
    end
    methods
        function obj = ObserveStub(sv_u)
            obj@LocalController("CSstub")
            obj.sv_u = reshape(string(sv_u), [], 1);
            obj.set_odefcn(obj.r_Hz)
        end
        function get_equilibrium(obj, V, u) %#ok
            obj.rv_Xequilibrium = zeros(0,1);
            obj.rv_Uequilibrium = zeros(numel(obj.sv_u),1);
        end
    end
    methods (Access=protected)
        function set_inputs(obj, sv_name)
            obj.sv_u = sv_name;
        end
    end
    methods (Static)
        function dx = fcn_dx(t, x, V, I, u, param, omega0) %#ok
            dx = zeros(0,1);
        end
        function y = fcn_y(t, x, V, I, u, param, omega0) %#ok
            y = zeros(0,1);
        end
        function M = fcn_Mass(t, x, V, I, u, param, omega0) %#ok
            M = zeros(0,0);
        end
        function [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t, x, V, I, u, param, omega0) %#ok
            Axx = zeros(0,0);  Bxv = zeros(0,2);  Bxi = zeros(0,2);  Bxu = zeros(0,numel(u));
        end
        function [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t, x, V, I, u, param, omega0) %#ok
            Cyx = zeros(0,0);  Dyv = zeros(0,2);  Dyi = zeros(0,2);  Dyu = zeros(0,numel(u));
        end
    end
end
