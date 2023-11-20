classdef impedance < component.load.abstract
% モデル ：定インピーダンス付加モデル
%       ・状態：なし
%       ・入力：２ポート「インピーダンス値の実部の倍率,インピーダンス値の虚部の倍率」
%               *入力αのときインピーダンスの値は設定値の(1+α)倍となる．
%親クラス：componentクラス
%実行方法：obj = component.load.impedance()
%　引数　：なし
%　出力　：componentクラスのインスタンス
    

    properties(SetAccess = private)
        Y
    end
    
    methods
        function obj = impedance()
            obj.x_equilibrium = zeros(0, 1);
        end
        
        function set_equilibrium(obj)
            Veq = obj.V_equilibrium;
            Ieq = obj.I_equilibrium;
            obj.Y = Ieq/Veq;
            switch obj.porttype
                case 'value'
                    obj.u_equilibrium = [real(obj.Y);imag(obj.Y)];
                case 'rate'
                    obj.u_equilibrium = [1;1];
            end
        end

        function [dx, constraint] = get_dx_constraint(obj, ~, ~, V, I, u)
            dx = zeros(0, 1);
            switch obj.porttype
                case 'value'
                    I_ = [u(1),-u(2);u(2),u(1)]*V;
                case 'rate'
                    Yr = real(obj.Y)*u(1);
                    Yi = imag(obj.Y)*u(2);
                    I_ = [Yr,-Yi;Yi,Yr]*V;
            end
            constraint = I-I_;
        end
        
        function nu = get_nu(~)
            nu = 2;
        end

        function u_name = naming_port(obj)
            switch obj.porttype
                case 'value'
                    u_name = {'Conductance','Susceptance'};
                case 'rate'
                    u_name = {'ConductanceRate','SusceptanceRate'};
            end
        end

        % function [A, B, C, D, BV, DV, BI, DI, R, S] = get_linear_matrix(obj, ~, V)
        %     if nargin < 2
        %         [A, B, C, D, BV, DV, BI, DI, R, S] = obj.get_linear_matrix([], obj.V_st);
        %     else
        %         A = [];
        %         B = zeros(0, 2);
        %         C = zeros(2, 0);
        %         D = [tools.complex2matrix(real(obj.Y))*V, tools.complex2matrix(1j*imag(obj.Y))*V];
        %         BV = zeros(0, 2);
        %         DV = tools.complex2matrix(obj.Y);
        %         R = [];
        %         S = [];
        %         BI = zeros(0, 2);
        %         DI = -eye(2);
        %     end
        % end
        
    end
end
