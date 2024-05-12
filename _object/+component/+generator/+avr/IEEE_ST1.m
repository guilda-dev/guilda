classdef IEEE_ST1 < component.generator.abstract.SubClass
% クラス名： IEEE_ST1
% 親クラス： component.generator.avr.abstract_SubClass
% 実行方法： component.generator.avr.IEEE_ST1(parameter)
%
% 　引数　： parameter >>1. string型. "Kundur", "Board", "Chow", "Sadamoto"
%                    >>2. table型.「'Ttr', 'k_ap','k0','gamma_max','gamma_min'」を列名として定義
%
%
% << Mode Discription >>
%   教科書p.224~226参照
% 
%
% << DataSheet for AVR IEEE_ST1 >>
%
% ▶︎ "Kundur"
%================================================================
% P. Kundur. 
% Power system stability and control. 
% Tata McGraw-Hill Education, 1994.
% 
%       Ttr,  Tap,  Kap, gamma_max, gamma_min,    k0
%    0.0015,  0.0,  200,      7.00,     -6.40, 0.040
%================================================================
% 
% 
% ▶︎ "Board"
%================================================================
% I.-S. S. Board. 
% Ieee recommended practice for excitation system models for 
% power system stability studies. 2016.
% 
%       Ttr,  Tap,  Kap, gamma_max, gamma_min,    k0
%    0.0200,    0,  210,      6.43,     -6.00, 0.038
%================================================================
% 
% 
% ▶︎ "Chow"
%================================================================
% J. H. Chow, G. E. Boukarim, and A. Murdoch. 
% Power system stabilizers as undergraduate control design projects. 
% IEEE Transactions on power systems, Vol. 19, No. 1, pp. 144–151, 2004.
% 
%       Ttr,   Tap,   Kap, gamma_max, gamma_min, k0
%         0, 0.076, 36.66,       inf,      -inf,  0
%================================================================
% 
% 
% ▶︎ "Sadamoto"
%================================================================
% T. Sadamoto, A. Chakrabortty, T. Ishizaki, and J.-i. Imura. 
% Dynamic modeling, stability, and control of power systems with distributed energy resources: 
% Handling faults using two control methods in tandem. IEEE Control Systems Magazine, Vol. 39, No. 2, pp. 34–65, 2019.
%
%      Ttr,   Tap,  Kap, gamma_max, gamma_min, k0
%        0, 0.050,   20,       inf,      -inf,  0
%================================================================
%
    
    properties(SetAccess=protected)
        mode
    end
    
    methods
        function obj = IEEE_ST1(parameter) % 引数はparameterを想定
            arguments
                parameter = "sadamoto";
            end
            obj@component.generator.abstract.SubClass("AVR")

            % Define Parameter
            [parameter,Tag] = ReadPara(parameter);
            obj.Tag = "IEEE_ST1"+Tag;
            obj.parameter = parameter(:,{'Kap','Ttr','Tap','k0','gamma_max','gamma_min'});
        end

        function set_parameter(obj,para)
            flag = para{:,{'Ttr','Tap'}} ~= 0;
            obj.mode = array2table(flag,'VariableNames',{'tr','ap'});
        end
        
        function name_tag = naming_state(obj)
            name = {'Vtr','Vap'};
            name_tag = name(obj.mode{:,:});
        end

        function [x_st,u_st] = get_equilibrium(obj, Vabs_st, Efd_st)
            x_st = [ Vabs_st;Efd_st ];
            x_st = x_st(obj.mode{:,:});
            u_st = Vabs_st + Efd_st/obj.parameter{:,'Kap'}; % 式(5.34)
        end
        
        function [dx, Vfd, V_ap] = get_dx_u(obj, x_avr, u_avr, Vabs, Efd)
            % x_avr : V_tr
            % u_avr : Vpss + u_avr_st

            para = obj.parameter{:,{'k0','gamma_min','gamma_max'}};
            V_ap_min = Vabs*para(2);
            V_ap_max = Vabs*para(3) - para(1)*Efd;

            u_avr = [Vabs;Efd;u_avr];
            sys = obj.system_matrix;
            
             dx  = sys.A * x_avr + sys.B * u_avr;
            V_ap = sys.C * x_avr + sys.D * u_avr;

            Vfd = obj.sat(V_ap, V_ap_min, V_ap_max);
        end
        
        function [A, B, C, D] = get_linear_matrix(obj,varargin)
            para = obj.parameter{:,{'Kap','Ttr','Tap'}};
            Kap = para(1);
            Ttr = para(2);
            Tap = para(3);

            if Ttr
                A1 = -1/Ttr;
                B1 = [1/Ttr, 0, 0];
                C1 = -Kap;
                D  = [ 0, 0, Kap];
            else
                A1 = []; 
                B1 = zeros(0,3); 
                C1 = zeros(1,0); 
                D  = [-Kap, 0, Kap];
            end
            if Tap
                A2 = -1/Tap;
                B2 = [-Kap, 0, Kap]/Tap;
                C2 = 1; 
                D  = zeros(1,3);
            else
                A2 = [];
                B2 = zeros(0,3);
                C2 = zeros(1,0); 
            end
            A = [A1;A2];
            B = [B1;B2];
            C = [C1,C2];
        end
        
    end
end



function [datasheet,Tag] = ReadPara(ID)
    if istable(ID)
        datasheet  = ID;
        Tag = [];
        return
    end

    para = readtable(mfilename("fullpath")+"_DataSheet.csv");
    switch string(ID)
        case {"1","Kundur"}
            datasheet = para(1,:);
            Tag = "_Kundur";
            
        case {"2","Board"}
            datasheet = para(2,:);
            Tag = "_Board";

        case {"3","Chow"}
            datasheet = para(3,:);
            Tag = "_Chow";

        case {"4","Sadamoto"}
            datasheet = para(4,:);
            Tag = "_Sadamoto";

        otherwise
            error("Parameters could not be identified.")
    end
end