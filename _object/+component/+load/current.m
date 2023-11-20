classdef current < component.load.abstract
% モデル ：定電流負荷モデル
%       ・状態：なし
%       ・入力：２ポート「電流フェーザの実部の倍率,電流フェーザの虚部の倍率」
%               *入力αのとき値は設定値の(1+α)倍となる．
%親クラス：componentクラス
%実行方法：obj = component.load.current()
%　引数　：なし
%　出力　：componentクラスのインスタンス    

    
    methods

        function u_name = naming_port(obj)
            switch obj.porttype
                case 'value'
                    u_name = {'Ireal','Iimag'};
                case 'rate'
                    u_name = {'IrealRate','IimagRate'};
            end
        end
        
        function [dx, constraint] = get_dx_constraint(obj, ~, ~, ~, I, u)
            dx = zeros(0, 1);
            switch obj.porttype
                case 'rate'
                    constraint = I - obj.I_st .* u(:);
                case 'value'
                    constraint = I - u(:);
            end
        end

        function [x_st,u_st] = get_equilibrium(obj,~,Ieq)
            if nargin<2
                Ieq = obj.I_equilibrium;
            end

            switch obj.porttype
                case 'rate'
                    u_st = [1;1];
                case 'value'
                    u_st = tools.complex2vec(Ieq);
            end
            x_st = zeros(0, 1);
        end
        
    end
end
