classdef impedance < component.load.abstract
% モデル  ：定インピーダンス負荷モデル
% 状態　　：なし
% 入力　　：２ポート「インピーダンス値の実部,インピーダンス値の虚部」
%実行方法 ：obj = component.load.impedance()
    properties(Constant)
        xvars = [];
        uvars = ["Gload","Bload"];        
        yvars = [];
        pvars = [];
    end
    methods(Static)
        [dx,I,y] = dynamics( x, V, u, parameter,opt)
    end
    methods
        ust = get_uequilibrium(obj,c_V,c_I)
        I   = fcn_I( obj, r_time, rvec_x, c_V, rvec_u)
    end
end
