classdef IEEE_PSS1 < component.generator.abstract.SubClass
% クラス名： IEEE_PSS1
% 親クラス： component.generator.pss.abstract_SubClass
% 実行方法： component.generator.avr.IEEE_PSS1(parameter)
%
% 　引数　： parameter >>1. string型. "Kundur", "Kundur12_5", "Kundur12_8", "Board", "Chow"
%                    >>2. table型.「'Kpss','Tws','Td1','Tn1','Td2','Tn2','V_min','Vmax'」を列名として定義
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
% Section 12.5 >> "Kundur" "Kundur12_5"
%     Kpss,  Tws,   Td1,   Tn1,  Td2,, Tn2, V_min, Vmax
%     9.50, 01.4, 0.033, 0.154, 0.00, 0.00,  -inf,  inf
% 
% Section 12.8 >> "Kundur12_8"
%     Kpss,  Tws,   Td1,   Tn1,  Td2,, Tn2, V_min, Vmax
%     20.0, 10.0, 0.020, 0.050, 5.40, 3.00,  -inf,  inf 
%================================================================
% 
% 
% ▶︎ "Board"
%================================================================
% I.-S. S. Board. 
% Ieee recommended practice for excitation system models for
% power system stability studies. 2016.
%
%     Kpss,  Tws,   Td1,   Tn1,  Td2,, Tn2, V_min, Vmax
%     3.15, 10.0, 0.010, 0.760, 0.01, 0.76,  -inf,  inf
%================================================================
%
% 
% ▶︎ "Chow"
%================================================================
% J. H. Chow, G. E. Boukarim, and A. Murdoch. 
% Power system stabilizers as undergraduate control design projects. 
% IEEE Transactions on power systems, Vol. 19, No. 1, pp. 144–151, 2004.
% 
%     Kpss,  Tws,   Td1,   Tn1,  Td2,, Tn2, V_min, Vmax
%     1.57, 10.0, 0.030, 0.340, 0.03, 0.34,  -inf,  inf
%================================================================
% 

    properties(SetAccess=protected)
        mode
    end

    methods
        function obj = IEEE_PSS1(parameter)
            arguments
                parameter = "Kundur";
            end
            obj@component.generator.abstract.SubClass("PSS")
            [obj.parameter,obj.Tag] = ReadPara(parameter);
        end

        function set_parameter(obj,para)
            flag = para{:,{'Tws','Td1','Td2'}}~=0;
            obj.mode = array2table(flag,'VariableNames',{'ws','d1','d2'});
        end

        function name_tag = naming_state(obj)
            name = {'xi_ws','xi1','xi2'};
            name_tag = name(obj.mode.Variables);
        end


        function nx = get_nx(obj)
            nx =sum(obj.mode.Variables);
        end

        function [dx, v_pss] = get_dx_u(obj, x_pss, ~, omega)
            sys = obj.system_matrix;
            Vminmax = obj.parameter{:,{'V_min','V_max'}};

            dx  = sys.A*x_pss + sys.B*omega;
            Vpl = sys.C*x_pss + sys.D*omega;

            v_pss = obj.sat( Vpl, Vminmax(1), Vminmax(2));
        end

        function [x_st, u_st] = get_equilibrium(obj, omega_st)%#ok
            x_st = zeros(3,1);
            x_st = x_st(obj.mode.Variables);
            u_st = [];
        end

        function [A,B,C,D] = get_linear_matrix(obj, x_st, ~, omega_st)%#ok
            para = obj.parameter{:,{'Kpss','Tws','Td1','Tn1','Td2','Tn2'}};
            Kpss = para(1);     Tws  = para(2);
            Td1  = para(3);     Tn1  = para(4);
            Td2  = para(5);     Tn2  = para(6);

            if Tws~=0
                sys_ws = ss(-1/Tws,    Kpss/Tws, -1, Kpss);
            else
                sys_ws = ss(1);
            end

            if Td1~=0
                Tnd1 = Tn1/Td1;
                sys_d1 = ss(-1/Td1, (1-Tnd1), -Tnd1, Tnd1);
            else
                sys_d1 = ss(1);
            end

            if Td2~=0
                Tnd2 = Tn2/Td2;
                sys_d2 = ss(-1/Td2, (1-Tnd2), -Tnd2, Tnd2);
            else
                sys_d2 = ss(1);
            end

            sys = sys_d2 * sys_d1 * sys_ws;
            [A,B,C,D] = ssdata(sys);

        end
    end

end



function [datasheet,Tag] = ReadPara(ID)
    if istable(ID)
        datasheet = array2table([zeros(1,6),-inf,inf],'VariableNames',{'Kpss','Tws','Td1','Tn1','Td2','Tn2','V_min','V_max'});
        [idx,num] = ismember(datasheet.Properties.VariableNames, ID.Properties.VariableNames);
        datasheet{:,idx} = ID{:,num(idx)};
        Tag = "IEEE_PSS1";
        return
    end

    para = readtable(mfilename("fullpath")+"_DataSheet.csv");
    switch string(ID)
        case {"1","Kundur","Kundur12_5"}
            datasheet = para(1,:);
            Tag = "Kundur";

        case {"2","Kundur12_8"}
            datasheet = para(4,:);
            Tag = "Kundur2";
        
        case {"3","Board"}
            datasheet = para(2,:);
            Tag = "Board";

        case {"4","Chow"}
            datasheet = para(3,:);
            Tag = "Chow";

        otherwise
            error("Parameters could not be identified.")
    end
    Tag = "IEEE_PSS1_" + Tag;
end