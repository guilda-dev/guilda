classdef BadJacobianStub < DebugScript.helper.BadComponentStub
% validate が解析的なヤコビアンの誤りを検出することを確かめるための機器 (テスト専用)
%
%   comp = DebugScript.helper.BadJacobianStub()   % Axx の値と Bxu の大きさが誤り
    methods
        function obj = BadJacobianStub()
            obj@DebugScript.helper.BadComponentStub("none");
        end
    end
    methods (Static)
        function [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(~, ~, ~, ~, ~, ~, ~)
            Axx = 2*eye(2);  Bxv = zeros(2);  Bxi = zeros(2);  Bxu = zeros(2,3);
        end
    end
end
