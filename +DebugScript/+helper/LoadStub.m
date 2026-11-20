classdef LoadStub < component.load.abstract
% コンストラクタを持たない負荷 (component.load.abstract が入力を受けることを確かめるため)
%
%   ld = DebugScript.helper.LoadStub("2B003", nan, opt)
    properties (Constant)
        key = "load-stub"       % 機器の種類のキー
        sv_x = strings(0,1)     % 状態の名前
        sv_u = strings(0,1)     % 入力の名前
        sv_y = strings(0,1)     % 出力の名前
        sv_para = strings(0,1)  % 動的パラメータの名前
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
            u = zeros(0,1);
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
