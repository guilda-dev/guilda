classdef solar_farm < component

    properties
        idc_st
        S
        Qst
        Pst
    end


    methods
        %　引数　: params : table型．「'Ppvbase', 'Vbase','Lac','Rac','Gsw','Cdc','Rpv','Vpv', 'vdc_st', 'tau_ac', 'KPd', 'KId', 'KPq', 'KIq', 'm_max', 'baseMVA', 'gamma_pv', 'omega0'」を列名として定義
        function obj = solar_farm(params)
            if istable(params)
                obj.parameter = params;

            elseif isstruct(parameter)
                obj.parameter = struct2table(params);

            end

            obj.parameter = obj.parameter(:,{'Ppvbase', 'Vbase','Lac','Rac','Gsw','Cdc','Rpv','Vpv', 'vdc_st', 'tau_ac', 'KPd', 'KId', 'KPq', 'KIq', 'm_max', 'baseMVA', 'gamma_pv', 'omega0'});
            omega0 = obj.parameter.omega0;
            Pbase = obj.parameter.baseMVA*1e6;
            Ppvbase = obj.parameter.Ppvbase*1e6;
            Zbase = obj.parameter.Vbase^2/Ppvbase;
            obj.parameter.Lac = obj.parameter.Lac/Zbase*omega0*(Pbase/Ppvbase);
            obj.parameter.Rac = obj.parameter.Rac/Zbase*(Pbase/Ppvbase);
            obj.parameter.Gsw = obj.parameter.Gsw*Zbase*(Pbase/Ppvbase);
            obj.parameter.Cdc = obj.parameter.Cdc*1e-6*Zbase*omega0*(Pbase/Ppvbase);
            obj.parameter.Rpv = obj.parameter.Rpv/Zbase*(Pbase/Ppvbase);
            obj.parameter.Vpv = obj.parameter.Vpv/obj.parameter.Vbase;

            obj.parameter.vdc_st = obj.parameter.vdc_st/obj.parameter.Vbase;
            obj.idc_st = (obj.parameter.Vpv-obj.parameter.vdc_st)/obj.parameter.Rpv;
        end

%{
        % parameterをsolar_farmのプロパティにしたもの（エラー吐く）
        function obj = solar_farm(params)
            omega0 = params{:,'omega0'};
            Pbase = params{:,'baseMVA'}*1e6;
            Ppvbase = params{:,'Ppvbase_'}*1e6;
            Zbase = params{:,'Vbase_'}^2/Ppvbase;
            obj.parameter.Lac = params{:,'Lac_'}/Zbase*omega0*(Pbase/Ppvbase);
            obj.parameter.Rac = params{:,'Rac_'}/Zbase*(Pbase/Ppvbase);
            obj.parameter.Gsw = params{:,'Gsw_'}*Zbase*(Pbase/Ppvbase);
            obj.parameter.Cdc = params{:,'Cdc_'}*1e-6*Zbase*omega0*(Pbase/Ppvbase);
            obj.parameter.Rpv = params{:,'Rpv_'}/Zbase*(Pbase/Ppvbase);
            obj.parameter.Vpv = params{:,'Vpv_'}/params{:,'Vbase_'};

            obj.parameter.tau_ac = params{:,'tau_ac'};
            obj.parameter.KPd = params{:,'KPd'};
            obj.parameter.KId = params{:,'KId'};
            obj.parameter.KPq = params{:,'KPq'};
            obj.parameter.KIq = params{:,'KIq'};
            obj.parameter.m_max = params{:,'m_max'};

            obj.parameter.omega0 = omega0;
            obj.parameter.gamma_pv = params{:,'gamma_pv'};

            obj.parameter.vdc_st = params{:,'vdc_'}/params{:,'Vbase_'};
            obj.parameter.idc_st = (obj.parameter.Vpv-obj.parameter.vdc_st)/obj.parameter.Rpv;
        end
%}

%{
        % 川口先生のコードまま
        function obj = solar_farm(pv_con, pv_params, baseMVA, gamma_pv, omega0)
            Pbase = baseMVA*1e6;
            Ppvbase = pv_con(1)*1e6;
            Zbase = pv_con(2)^2/Ppvbase;
            obj.parameter.Lac = pv_con(3)/Zbase*omega0*(Pbase/Ppvbase);
            obj.parameter.Rac = pv_con(4)/Zbase*(Pbase/Ppvbase);
            obj.parameter.Gsw = pv_con(5)*Zbase*(Pbase/Ppvbase);
            obj.parameter.Cdc = pv_con(6)*1e-6*Zbase*omega0*(Pbase/Ppvbase);
            obj.parameter.Rpv = pv_con(8)/Zbase*(Pbase/Ppvbase);
            obj.parameter.Vpv = pv_con(9)/pv_con(2);

            obj.parameter.tau_ac = pv_params(1);
            obj.parameter.KPd = pv_params(2);
            obj.parameter.KId = pv_params(3);
            obj.parameter.KPq = pv_params(4);
            obj.parameter.KIq = pv_params(5);
            obj.parameter.m_max = pv_params(6);

            obj.parameter.omega0 = omega0;
            obj.parameter.gamma_pv = gamma_pv;

            obj.parameter.vdc_st = pv_con(10)/pv_con(2);
            obj.parameter.idc_st = (obj.parameter.Vpv-obj.parameter.vdc_st)/obj.parameter.Rpv;    

        end
%}

        function [dx, constraint] = get_dx_constraint(obj, t, x, V, I, u)
            Rac = obj.parameter.Rac;
            Lac = obj.parameter.Lac;
            omega0 = obj.parameter.omega0;
            tau_ac = obj.parameter.tau_ac;
            KPd = obj.parameter.KPd;
            KPq = obj.parameter.KPq;
            KId = obj.parameter.KId;
            KIq = obj.parameter.KIq;
            Cdc = obj.parameter.Cdc;
            Gsw = obj.parameter.Gsw;

            Vpv = obj.parameter.Vpv;
            Rpv = obj.parameter.Rpv;


            gamma_pv = obj.parameter.gamma_pv;

            dx = zeros(7, 1);
            I_ = -gamma_pv*x(1:2);
            P = V'*I_;
            Q = -I_(2)*V(1)+I_(1)*V(2);
            i = x(1:2);
            vdc = x(7);
            Chi = x(3:4);
            zeta = x(5:6);
            iref = [KPd*(obj.Pst-P); KPq*(obj.Qst-Q)] + zeta;
            idc = obj.S*(Vpv-obj.S*vdc)/Rpv;

            m = 2/vdc*(V + ...
                [Lac/omega0/tau_ac, Lac; -Lac, Lac/omega0/tau_ac]*i...
                -Rac*Chi - Lac/omega0/tau_ac*iref) + u;
            m(m>obj.parameter.m_max) = obj.parameter.m_max;
            m(m<-obj.parameter.m_max) = -obj.parameter.m_max;


            dx(1:2) = omega0/Lac*([-Rac, Lac; -Lac, -Rac]*i+V-m*vdc/2);
            dx(3:4) = (iref-i)/tau_ac;
            dx(5) = KId*(obj.Pst-P);
            dx(6) = KIq*(obj.Qst-Q);
            dx(7) = omega0/Cdc*((V'*i + vdc*idc - Rac*(i'*i))/(2*vdc)-Gsw*vdc);

            constraint = I - I_;
        end

        function nu = get_nu(obj)
            nu = 2;
        end

        function nx = get_nx(obj)
            nx = 7;
        end

        function [x, u] = get_equilibrium(obj, V, I)
            P = V*conj(I);
            obj.Pst = real(P);
            obj.Qst = imag(P);
            Vr = real(V);
            Vi = imag(V);
            gamma_pv = obj.parameter.gamma_pv;
            Rac = obj.parameter.Rac;
            x0 = -[Vr, Vi; Vi, -Vr]\[obj.Pst; obj.Qst]/gamma_pv;
            vdc0 = sqrt((obj.parameter.vdc_st*obj.idc_st-obj.Pst/gamma_pv - Rac*(x0'*x0))/(2*obj.parameter.Gsw));
            obj.S = obj.parameter.vdc_st/vdc0;
            x = [x0; x0; x0; vdc0];
            % obj.numerical_diff(x, [Vr; Vi]);

            % inner loopの入力は0にする
            u = [0; 0];
        end

    end
end