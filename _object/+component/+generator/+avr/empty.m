classdef empty < component.generator.abstract.SubClass
% クラス名： 空のAVRモデル
% 親クラス： component.generator.abstract.SubClass
% 実行方法： component.generator.avr.empty()
% 　引数　： なし
%
% <<モデル概要>>
%
%   Vfd = u_avr1
%
%   ・ 入力ポート : u_avr1
%   ・ 出力ポート : Vfd
% 

    methods
        function obj = empty(varargin)
            obj@component.generator.abstract.SubClass("AVR")
        end
        
        function [x_st,u_st] = get_equilibrium(obj, Vabs_st, Efd_st)%#ok
            x_st = [];
            u_st = Efd_st;
        end
        
        function [dx, Vfd] = get_dx_u(obj, x_avr, u_avr, Vabs, Efd)%#ok
            dx  = [];
            Vfd = u_avr;
        end

        function [A,B,C,D] = get_linear_matrix(obj, x_st, u_st, Vabs_st, Efd_st)%#ok
            A = [];
            B = zeros(0,3);
            C = [];
            D = [0,0,1];
        end
        
    end
end