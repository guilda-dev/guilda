classdef voltage < component.load.abstract
% モデル ：定電圧負荷モデル
%       ・状態：なし
%       ・入力：２ポート「電圧フェーザの実部の倍率,電圧フェーザの虚部の倍率」
%               *入力αのとき値は設定値の(1+α)倍となる．
%親クラス：componentクラス
%実行方法：obj = component.load.voltage()
%　引数　：なし
%　出力　：componentクラスのインスタンス
    

    methods
        function set_equilibrium(obj)
            obj.x_equilibrium = zeros(0,1);
            switch obj.porttype
                case 'rate'
                    obj.u_equilibrium = [1;1];
                case 'value'
                    obj.u_equilibrium = obj.V_st;
            end
        end
        
        function [dx, constraint] = get_dx_constraint(obj, t, x, V, I, u)
            dx = zeros(0, 1);
            switch obj.porttype
                case 'rate'
                    constraint = V - obj.V_st .* u(:);
                case  'value'
                    constraint = V - u(:);
            end
        end

        function nu = get_nu(~)
            nu = 2;
        end
        
        function u_name = naming_port(obj)
            switch obj.porttype
                case 'value'
                    u_name = {'Vreal','Vimag'};
                case 'rate'
                    u_name = {'VrealRate','VimagRate'};
            end
        end
        
    end
end
