classdef empty < component.generator.abstract.SubClass
% クラス名： 空のPSSモデル
% 親クラス： component.generator.abstract.SubClass
% 実行方法： component.generator.pss.empty()
% 　引数　： なし
%
% <<モデル概要>>
%
%   v_pss = 0 * omega
%
%   ・ 入力ポート : []
%   ・ 出力ポート : v_pss
%
    
    
    methods
        function obj = empty(varargin)
            obj@component.generator.abstract.SubClass("PSS")
        end
        
        function [dx, v_pss] = get_dx_u(obj, x_pss, u_pss, omega)%#ok
             dx   = [];
            v_pss = 0 ;
        end

        function nx = get_nx(~)
            nx = 0;
        end
        
        function [x_st, u_st] = get_equilibrium(obj, omega_st)%#ok
            x_st = [];
            u_st = [];
        end

        function [A,B,C,D] = get_linear_matrix(obj, x_st, u_st, omega_st)%#ok
            A = zeros(0,0);  B = zeros(0,1);
            C = zeros(1,0);  D = zeros(1,1);
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

