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
            obj@controller.agc.broadcast_PI_AGC(net, tag, varargin{:});
            obj.str_bad = str_bad;
        end
        function [x, u] = get_equilibrium(obj)
            [x, u] = get_equilibrium@controller.agc.broadcast_PI_AGC(obj);
            if obj.str_bad == "output"
                x = 0.5;
            else
                x = [0; 0];
            end
        end
    end
end
