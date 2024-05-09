classdef empty < component
% モデル  ：空の機器モデル
% 状態　　：なし
% 入力　　：ポートなし
%実行方法 ：obj = component.empty()
    
    
    methods
        function obj = empty()
            obj.Tag = 'non';
        end

        function [x_st,u_st] = get_equilibrium(obj,varargin)
            x_st = [];
            u_st = [];
        end
        
        function [dx, con] = get_dx_constraint(~,~,~,~,I,~)
            dx = [];
            con = I(:);
        end
        
    end
end

