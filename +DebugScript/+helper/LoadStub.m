classdef LoadStub < component.load.abstract
% コンストラクタを持たない負荷 (component.load.abstract が入力を受けることを確かめるため)
%
%   ld = DebugScript.helper.LoadStub("2B003", nan, opt)
    properties (Constant)
        key     = "load-stub"
        sv_x    = strings(0,1)
        sv_u    = strings(0,1)
        sv_y    = strings(0,1)
        sv_para = strings(0,1)
    end
    methods
        function [x, u] = get_equilibrium(~, ~, ~, ~, ~)
            x = zeros(0,1);
            u = zeros(0,1);
        end
    end
    methods (Static)
        function dx = fcn_dx(varargin); dx = zeros(0,1); end
        function I  = fcn_I(varargin);  I  = 0;          end
        function y  = fcn_Y(varargin);  y  = zeros(0,1); end
        function M  = fcn_Mass(varargin); M = zeros(0);  end
    end
end
