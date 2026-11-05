classdef BadPSSStub < controller.pss.abstract
% initialize が AVR の下の制御器も調べることを確かめるための PSS (テスト専用)
%
% 状態がないのに、基底クラスの平衡点は x を 1 要素持つ。
    methods
        function obj = BadPSSStub(tag)
            arguments (Input)
                tag  % タグの接尾辞
            end
            arguments (Output)
                obj  % 作成したオブジェクト
            end
            obj@controller.pss.abstract(tag)
            obj.key     = "pss";
            obj.sv_x    = strings(0,1);
            obj.sv_para = strings(0,1);
        end
    end
    methods (Static)
        function [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(varargin)
            arguments (Input, Repeating)
                varargin  % 使わない入力
            end
            arguments (Output)
                Axx  % fcn_dx の x によるヤコビアン
                Bxv  % fcn_dx の V によるヤコビアン
                Bxi  % fcn_dx の I によるヤコビアン
                Bxu  % fcn_dx の u によるヤコビアン
            end
            [Axx,Bxv,Bxi,Bxu] = deal([]);
        end
        function [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(varargin)
            arguments (Input, Repeating)
                varargin  % 使わない入力
            end
            arguments (Output)
                Cyx  % fcn_y の x によるヤコビアン
                Dyv  % fcn_y の V によるヤコビアン
                Dyi  % fcn_y の I によるヤコビアン
                Dyu  % fcn_y の u によるヤコビアン
            end
            [Cyx,Dyv,Dyi,Dyu] = deal([]);
        end
    end
end
