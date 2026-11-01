classdef GeneratorStub < component.generator.abstract
% parameter.csv にない列を要求する発電機 (MissingParameter を既定の入力で確かめるため)
%
%   gen = DebugScript.helper.GeneratorStub("1B001", nan, opt)
    properties (Constant)
        key     = "gen-stub"
        sv_x    = strings(0,1)
        sv_u    = strings(0,1)
        sv_y    = strings(0,1)
        sv_para = ["M","Zeta"]
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
