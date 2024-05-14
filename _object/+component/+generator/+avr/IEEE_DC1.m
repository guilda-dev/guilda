classdef IEEE_DC1 < component.generator.abstract.SubClass
% クラス名 : IEEE_DC1モデル
% 親クラス : avrクラス
% 実行方法 : avr_IEEE_DC1(avr_tab)
%
% 引数　　 : ・avr_tab >>1. string型. "Anderson", "Sauer"
%                    >>2. table型.「'Ttr', 'Kap', 'Tap', 'Vap_max', 'Vap_min', 'Kst', 'Tst', 'Aex', 'Tex', 'a_ex', 'b_ex'」を列名として定義
%
%
% <<  Model Discription >>
% 　　　　   
%   (電力系統のシステム制御工学 p.221~224)
%   (Robust Control in Power Systems p.43)
%
%
% << DataSheet for AVR IEEE_DC1 >>
%
% ▶︎ "Anderson"
%==================================================================================
% P. M. Anderson and A. A. Fouad. 
% Power system control and stability. 
% John Wiley & Sons, 2008.
% 
%    Ttr,  Kap,  Tap, Vap_max, Vap_min,   Kst,  Tst,    Aex,   Tex,   a_ex,  b_ex
%   0.00, 57.1, 0.05,    1.00,   -1.00, 0.080, 1.00, -0.045, 0.500, 0.0012, 1.210
%==================================================================================
%
%
% ▶︎ "Sauer"
%==================================================================================
% P. W. Sauer, M. A. Pai, and J. H. Chow. 
% Power system dynamics and stability: with synchrophasor measurement and power system toolbox. 
% John Wiley & Sons, 2017.
%
%    Ttr,  Kap,  Tap, Vap_max, Vap_min,   Kst,  Tst,    Aex,   Tex,   a_ex,  b_ex
%   0.00, 20.0, 0.20,     inf,    -inf, 0.063, 0.35,  1.000, 0.314, 0.0039, 1.555
%==================================================================================


    methods
        function obj = IEEE_DC1(avr_tab)
            arguments
                avr_tab = "Sauer";
            end
            obj@component.generator.abstract.SubClass("AVR");

            % Define Parameter
            [obj.parameter,obj.Tag] = ReadPara(avr_tab);
        end

        function name_tag = naming_state(~)
            name_tag = {'Vtr','Vap','Vfd','Vst'};
        end

        function nx = get_nx(~)
            nx =4;
        end

        function [x_st,u_st] = get_equilibrium(obj, Vabs_st, Efd_st)
            para = obj.parameter{:,{'Kap', 'Aex', 'a_ex', 'b_ex'}};
            Kap = para(1);
            Aex = para(2);
            a_ex= para(3); 
            b_ex= para(4);

            Vtr_st = Vabs_st;
            Vfd_st = Efd_st;
            Vap_st = Vfd_st * (Aex + a_ex * exp(b_ex*Vfd_st) ); % = Kap * (u_st - Vtr_st - Vst_st);
            Vst_st = 0;

            x_st = [ Vtr_st; Vap_st; Vfd_st; Vst_st];
            u_st = Vabs_st + Vap_st/Kap;
        end

        function [dx, Vfd] = get_dx_u(obj, x_avr, u_avr, Vabs, Efd) %#ok
            % x_avr = [Vtr,Vap,Vfd,Vst]
            % u_avr = Vref + Vpss

            % parameter
            para = obj.parameter{:,{'Ttr', 'Kap', 'Tap', 'Aex', 'Tex', 'Kst', 'Tst', 'a_ex', 'b_ex', 'Vap_max', 'Vap_min'}};
            Aex = para(4);
            Kst = para(6);
            a_ex= para(8); 
            b_ex= para(9);
            Vap_max = para(10);
            Vap_min = para(11);

            % state
            Vtr = x_avr(1);
            Vap = x_avr(2);
            Vfd = x_avr(3);
            Vst = x_avr(4);

            %calculate dx
            dVtr = -Vtr+Vabs;
            Vcom = u_avr - Vtr - Vst;
            if ( (Vap>Vap_min) && (Vap<Vap_max) ) || (Vap*Vcom<=0)
                Kap = para(2);
                dVap = -Vap + Kap*Vcom;
            else
                dVap = 0;
            end
            dVfd = -( Aex+a_ex*exp(b_ex*Vfd) )*Vfd + Vap;
            dVst = -Vst + Kst * dVfd;
            E  = diag(1./para([1,3,5,7])); %1./[Ttr,Tap,Tex,Tst]
            dx = E * [dVtr; dVap; dVfd; dVst];
        end

    end
end

function [datasheet,Tag] = ReadPara(ID)
    if istable(ID)
        datasheet = array2table([zeros(1,3),inf,-inf,zeros(1,6)],'VariableNames',{'Ttr', 'Kap', 'Tap', 'Vap_max', 'Vap_min', 'Kst', 'Tst', 'Aex', 'Tex', 'a_ex', 'b_ex'});
        [idx,num] = ismember(datasheet.Properties.VariableNames, ID.Properties.VariableNames);
        datasheet{:,idx} = ID{:,num(idx)};
        Tag = "IEEE_DC1";
        return
    end

    para = readtable(mfilename("fullpath")+"_DataSheet.csv");
    switch string(ID)
        case {"1","Anderson"}
            datasheet = para(1,:);
            Tag = "Anderson";
            
        case {"2","Sauer"}
            datasheet = para(2,:);
            Tag = "Sauer";

        otherwise
            error("Parameters could not be identified.")
    end
    Tag = "IEEE_DC1_" + Tag;
end