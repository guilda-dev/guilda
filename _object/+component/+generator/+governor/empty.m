classdef empty < component.generator.abstract.SubClass
% クラス名： 空のGOVERNORモデル
% 親クラス： component.generator.abstract.SubClass
% 実行方法： component.generator.governor.empty()
% 　引数　： なし
%
% <<モデル概要>>
%
%   Pmech = u_gov1
%
%   ・ 入力ポート : u_gov1
%   ・ 出力ポート : Pmech
%
    
    methods
        function obj = empty(varargin)
            obj@component.generator.abstract.SubClass("GOVERNOR")
        end
        
        
        function [x_st,u_st] = get_equilibrium(obj, omega_st, P_st)%#ok
            x_st = [];
            u_st = P_st;
        end
        
        function [dx, Pm] = get_dx_u(obj, x_gov, u_gov, omega, P)%#ok
            dx  = [];
            Pm = u_gov;
        end

        function [A,B,C,D] = get_linear_matrix(obj, x_st, u_st, omega_st, P_st)%#ok
            A = zeros(0,1);
            B = zeros(0,3);
            C = zeros(1,0);
            D = [0,0,1];
        end

        function name = naming_port(~)
            name = {'Pm'};
        end
    end

    methods(Access=protected)
        function PropEditor_Set(obj,prop,val)
            obj.(prop) = val;
        end
        function val = PropEditor_Get(obj,prop)
            val = obj.(prop);
        end
    end
end

