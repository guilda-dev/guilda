classdef current < component.load.abstract
% モデル  ：定電流負荷モデル
% 状態　　：なし
% 入力　　：２ポート「電流フェーザの実部,電流フェーザの虚部」
%実行方法 ：obj = component.load.current()

        properties(Constant)
            xvars = [];
            uvars = ["Iabsload","Iargload"];
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
