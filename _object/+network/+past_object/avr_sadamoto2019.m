classdef avr_sadamoto2019 < component.generator.avr.IEEE_ST1
% クラス名： avr_sadamoto2019
% 親クラス： component.generator.avr.IEEE_ST1("sadamoto")
% 実行方法： network.past_object.avr_sadamoto2019(parameter)
%
%<<モデル概要>>
% T.sadamoto, Dynamic Modeling, Stability, and Control of Power Systems With Distributed Energy Resources: Handling Faults Using Two Control Methods in Tandem, IEEE Control Systems Magazine, 2019.
% 　Ka,   Te
% 　0.05, 200
%
% 　引数　： parameter >>table型.「'Ka', 'Te'」を列名として定義
%
%
% component.generator.avr.IEEE_ST1("sadamoto")と同じ構造を持つが、Ka, Teのみを変更する
%    
    properties
        Ka
        Te
    end
    
    methods
        function obj = avr_sadamoto2019(parameter)
            obj@component.generator.avr.IEEE_ST1("Sadamoto")
            if nargin==1
                obj.parameter.Kap = parameter.Ka;
                obj.parameter.Tap = parameter.Te;
            end
        end
        
        function name_tag = naming_state(obj)
            name_tag = {'Vfield'};
        end
        
        function Ka = get.Ka(obj)
            Ka = obj.parameter{:,'Kap'};
        end
        
        function Te = get.Te(obj)
            Te = obj.parameter{:,'Tap'};
        end
        
        % IEEE_ST1クラスで定義ずみ。閾値InfのSaturation等の処理が入るため処理速度を上げたい場合はオーバーライド推奨
        % function [dVfd, Vfd, Vap] = get_Vfd(obj, Vfd, Vabs, Efd, u)
        %     Vef = obj.Ka*(Vabs-obj.Vabs_st+u(1));
        %     dVfd = (-Vfd+obj.Vfd_st-Vef)/obj.Te;
        %     Vap = Vfd;
        % end
        
    end
end