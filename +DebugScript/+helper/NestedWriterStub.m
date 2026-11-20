classdef NestedWriterStub < controller.avr.abstract
% 入れ子の枠 a_LocalController に直接書き込む AVR (LocalController の枠の検査を確かめるため)
%
%   avr = DebugScript.helper.NestedWriterStub("1");
%   avr.write_nested({gov})     % AVR の下は PSS だけなので GUILDA:LocalController:NestedControllerSlot
    properties (Constant, Hidden)
        key = "test-nested-writer"  % モデルのキー (登録しないので使わない)
    end
    methods
        function obj = NestedWriterStub(tag)
            arguments (Input)
                tag  % タグの接尾辞
            end
            arguments (Output)
                obj  % 作成したオブジェクト
            end
            obj@controller.avr.abstract(tag)
            obj.sv_x    = strings(0,1);
            obj.sv_para = strings(0,1);
        end
        function write_nested(obj, a_con)
            % a_LocalController にそのまま書き込む
            arguments (Input)
                obj
                a_con (:,1) cell  % 書き込む制御器の一覧
            end
            obj.a_LocalController = a_con;
        end
    end
    methods (Static)
        function dx = fcn_dx(varargin)
            arguments (Input, Repeating)
                varargin  % 使わない入力
            end
            arguments (Output)
                dx  % 状態方程式の右辺
            end
            dx = zeros(0,1);
        end
        function y = fcn_y(varargin)
            arguments (Input, Repeating)
                varargin  % 使わない入力
            end
            arguments (Output)
                y  % 出力
            end
            y = 0;
        end
        function M = fcn_Mass(varargin)
            arguments (Input, Repeating)
                varargin  % 使わない入力
            end
            arguments (Output)
                M  % 質量行列
            end
            M = zeros(0);
        end
        function [Axx,Bxv,Bxu] = Jacobi_dx(varargin)
            arguments (Input, Repeating)
                varargin  % 使わない入力
            end
            arguments (Output)
                Axx  % fcn_dx の x によるヤコビアン
                Bxv  % fcn_dx の V によるヤコビアン
                Bxu  % fcn_dx の u によるヤコビアン
            end
            Axx = zeros(0); Bxv = zeros(0,2); Bxu = zeros(0,2);
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
            Cyx = zeros(1,0); Dyv = zeros(1,2); Dyu = zeros(1,2);
        end
    end
end
