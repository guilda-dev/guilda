classdef SlotWriterStub < component.generator.abstract
% a_LocalController に直接書き込む発電機 (制御器の枠の検査が add_local_controller 以外の書き込みも弾くことを確かめるため)
%
%   [gen, c] = DebugScript.helper.stub_component("SlotWriterStub");
%   gen.write_slots({gov; avr})     % 枠の順でないので GUILDA:Component:ControllerSlots
    properties (Constant)
        key = "gen-slot-writer-stub"        % 機器の種類のキー
        sv_x = strings(0,1)     % 状態の名前
        sv_u = ["Vfield";"Pmech"] % 入力の名前
        sv_y = strings(0,1)     % 出力の名前
        sv_para = "M"           % 動的パラメータの名前
    end
    methods
        function [x, u] = get_equilibrium(~, ~, ~, ~, ~)
            arguments (Input)
                ~
                ~
                ~
                ~
                ~
            end
            arguments (Output)
                x  % 平衡点の状態
                u  % 平衡点の入力
            end
            x = zeros(0,1);
            u = zeros(2,1);
        end
        function write_slots(obj, a_con)
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
        function I = fcn_I(varargin)
            arguments (Input, Repeating)
                varargin  % 使わない入力
            end
            arguments (Output)
                I  % [pu] 母線への注入電流 (複素数)
            end
            I  = 0;
        end
        function y = fcn_Y(varargin)
            arguments (Input, Repeating)
                varargin  % 使わない入力
            end
            arguments (Output)
                y  % 出力
            end
            y  = zeros(0,1);
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
    end
end
