classdef BadPSSStub < controller.pss.abstract
% initialize が AVR の下の制御器も調べることを確かめるための PSS (テスト専用)
%
% 状態がないのに、基底クラスの平衡点は x を 1 要素持つ。
    methods
        function obj = BadPSSStub(tag)
            obj@controller.pss.abstract(tag)
            obj.key     = "pss";
            obj.sv_x    = strings(0,1);
            obj.sv_para = strings(0,1);
            obj.set_odefcn(obj.r_Hz);
        end
    end
    methods (Static)
        function [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(varargin)
            [Axx,Bxv,Bxi,Bxu] = deal([]);
        end
        function [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(varargin)
            [Cyx,Dyv,Dyi,Dyu] = deal([]);
        end
    end
end
