classdef BadJacobianStub < DebugScript.helper.BadComponentStub
% validate が解析的なヤコビアンの誤りを検出することを確かめるための機器 (テスト専用)
%
%   comp = DebugScript.helper.BadJacobianStub()   % Axx の値と Bxu の大きさが誤り
    methods
        function obj = BadJacobianStub()
            arguments (Output)
                obj  % 作成したオブジェクト
            end
            obj@DebugScript.helper.BadComponentStub("none");
        end
    end
    methods (Static)
        function [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(~, ~, ~, ~, ~, ~, ~)
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
                Axx  % fcn_dx の x によるヤコビアン
                Bxv  % fcn_dx の V によるヤコビアン
                Bxi  % fcn_dx の I によるヤコビアン
                Bxu  % fcn_dx の u によるヤコビアン
            end
            Axx = 2*eye(2);  Bxv = zeros(2);  Bxi = zeros(2);  Bxu = zeros(2,3);
        end
    end
end
