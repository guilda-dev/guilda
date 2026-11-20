classdef BadPSSStub < controller.pss.abstract
% initialize が AVR の下の制御器も調べることを確かめるための PSS (テスト専用)
%
% 状態がないのに、基底クラスの平衡点は x を 1 要素持つ。
%
%   c   = DebugScript.helper.register_stub("BadPSSStub", "controller.test_bad_pss");
%   pss = gen.add_local_controller("test-bad-pss");
    properties (Constant, Hidden)
        key = "test-bad-pss"  % モデルのキー (register_stub が写しのクラス名に置き換える)
    end
    methods
        function obj = BadPSSStub(tag)
            arguments (Input)
                tag  % タグの接尾辞
            end
            arguments (Output)
                obj  % 作成したオブジェクト
            end
            obj@controller.pss.abstract(tag)
            obj.sv_x    = strings(0,1);
            obj.sv_para = strings(0,1);
        end
    end
    methods (Static)
        function [Axx,Bxv,Bxu] = Jacobi_dx(varargin)
            arguments (Input, Repeating)
                varargin  % 使わない入力
            end
            arguments (Output)
                Axx  % fcn_dx の x によるヤコビアン
                Bxv  % fcn_dx の V によるヤコビアン
                Bxu  % fcn_dx の u によるヤコビアン
            end
            [Axx,Bxv,Bxu] = deal([]);
        end
        function [Cyx,Dyv,Dyu] = Jacobi_Y(varargin)
            arguments (Input, Repeating)
                varargin  % 使わない入力
            end
            arguments (Output)
                Cyx  % fcn_y の x によるヤコビアン
                Dyv  % fcn_y の V によるヤコビアン
                Dyu  % fcn_y の u によるヤコビアン
            end
            [Cyx,Dyv,Dyu] = deal([]);
        end
    end
end
