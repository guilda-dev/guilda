classdef BadAGCStub < controller.agc.broadcast_PI_AGC
% initialize が大域制御器の誤りを検出することを確かめるための AGC (テスト専用)
%
%   agc = DebugScript.helper.BadAGCStub(net, "agc", "output", comp)
%
%   output : 積分器の平衡点が 0 でなく、出力が機器の入力を動かす
%   xsize  : 平衡点の x が 2 要素
    properties (SetAccess=immutable)
        str_bad
    end
    methods
        function obj = BadAGCStub(net, tag, str_bad, varargin)
            arguments (Input)
                net      % 電力系統
                tag      % タグの接尾辞
                str_bad  % 入れる誤りの種類 ("output" / "xsize")
            end
            arguments (Input, Repeating)
                varargin  % broadcast_PI_AGC へ渡す制御対象の機器
            end
            arguments (Output)
                obj  % 作成したオブジェクト
            end
            obj@controller.agc.broadcast_PI_AGC(net, tag, varargin{:});
            obj.str_bad = str_bad;
        end
        function [x, u] = get_equilibrium(obj)
            arguments (Input)
                obj
            end
            arguments (Output)
                x  % 平衡点の状態
                u  % 平衡点の入力
            end
            [x, u] = get_equilibrium@controller.agc.broadcast_PI_AGC(obj);
            if obj.str_bad == "output"
                x = 0.5;
            else
                x = [0; 0];
            end
        end
    end
end
