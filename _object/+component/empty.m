classdef empty < component
% モデル  ：空の機器モデル
%       ・状態：なし
%       ・入力：ポートなし
%親クラス：componentクラス
%実行方法：obj = component.empty()
%　引数　：なし
%　出力　：componentクラスのインスタンス
    
    
    methods
        function obj = empty()
            obj.Tag = 'none';
        end

        function set_equilibrium(obj,varargin)
            obj. x_equilibrium = [];
        end
        
        function nu = get_nu(~)
            nu = 0;
        end
        
        function [dx, con] = get_dx_constraint(~,~,~,~,I,~)
            dx = [];
            con = I(:);
        end
        
        function [dx, con] = get_dx_constraint_linear(~,~,~,~,I,~)
            dx = [];
            con = I(:);
        end
        
    end
end

