classdef sadamoto2019 < component.generator.avr.IEEE_ST1
% クラス名： IEEE_ST1
% 親クラス： component.generator.avr.IEEE_ST1("sadamoto")
% 実行方法： component.generator.avr.sadamoto2019
%
%<<モデル概要>>
% 定本先生が2019年の論文で紹介されたモデル 
%    
    properties
        Ka
        Te
    end
    
    methods
        function obj = sadamoto2019(p)
            obj@component.generator.avr.IEEE_ST1("Sadamoto")
            obj.parameter.Kap = p.Ka;
            obj.parameter.Tap = p.Te;
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

