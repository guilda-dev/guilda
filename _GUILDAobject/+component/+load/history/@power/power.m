classdef power < component.load.abstract
% モデル  ：定電力負荷モデル
% 状態　　：なし
% 入力　　：２ポート「有効電力・無効電力」
%実行方法 ：obj = component.load.power()
    
    properties
        PQ_st
    end

    properties(Constant)
        xvars = [];
        uvars = ["Pload","Qload"];
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
