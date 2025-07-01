classdef wind_farm < component

    properties
        KPG
        KIG
        kappaP
        kappaI
        KPR
        vdc_st
        Shm
        Shl
        coeff_Pa
        Pa_st
        Vabs_m_st
        omega_r_st
        ir_st
        windspeed
    end

    methods
        %　引数　: params : table型．「'rho', 'A', 'windspeed_st', 'Jl', 'Bl', 'Jr', 'Br', 'dc', 'Kc', 'Ng', 'p', 'Xs', 'Xr', 'Xm', 'Rs', 'Rr', 'Pwbase', 'Vbase', 'Vl', 'LG', 'RG', 'Gsw', 'Cdc', 'tauG', 'KPdG', 'KIdG', 'KPqG', 'KIqG', 'KappaPd', 'KappaId', 'KappaPq', 'KappaIq', 'Pr_st', 'Qr_st', 'm_max', 'KPdR', 'KPqR', 'Cb', 'Lb', 'Gb', 'Rb', 'S', 'gamma', 'baseMVA', 'omega0', 'fl', 'w'」を列名として定義
        % wind_conの引数の番号は「3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25」
        % winpの引数の番号は「1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 14, 16」
        % sto_conの引数の番号は「1, 2, 3, 4, 5」
        function obj = wind_farm(params)
            if istable(params)
                obj.parameter = params;

            elseif isstruct(parameter)
                obj.parameter = struct2table(params);

            end

            obj.parameter = obj.parameter(:,{'rho', 'A', 'windspeed_st', 'Jl', 'Bl', 'Jr', 'Br', 'dc', 'Kc', 'Ng', 'p', 'Xs', 'Xr', 'Xm', 'Rs', 'Rr', 'Pwbase', 'Vbase', 'Vl', 'LG', 'RG', 'Gsw', 'Cdc', 'tauG', 'KPdG', 'KIdG', 'KPqG', 'KIqG', 'KappaPd', 'KappaId', 'KappaPq', 'KappaIq', 'Pr_st', 'Qr_st', 'm_max', 'KPdR', 'KPqR', 'Cb', 'Lb', 'Gb', 'Rb', 'S', 'gamma', 'baseMVA', 'omega0', 'fl', 'w'});
            Pbase = obj.parameter.baseMVA*1e6;
            omega0 = obj.parameter.omega0;
            Tbase = Pbase/(omega0/2);

            obj.parameter.Jl = obj.parameter.Jl*(omega0/2)/Tbase;
            obj.parameter.Bl = obj.parameter.Bl*(omega0/2)/Tbase;
            obj.parameter.Jr = obj.parameter.Jr*(omega0/2)/Tbase;
            obj.parameter.Br = obj.parameter.Br*(omega0/2)/Tbase;
            obj.parameter.dc = obj.parameter.dc*(omega0/2)/Tbase;
            obj.parameter.Kc = obj.parameter.Kc/Tbase;

            Pwbase = obj.parameter.Pwbase*1e6;
            obj.parameter.Xs = obj.parameter.Xs*(Pbase/Pwbase); % for grid base
            obj.parameter.Xr = obj.parameter.Xr*(Pbase/Pwbase);
            obj.parameter.Xm = obj.parameter.Xm*(Pbase/Pwbase);
            obj.parameter.Rs = obj.parameter.Rs*(Pbase/Pwbase);
            obj.parameter.Rr = obj.parameter.Rr*(Pbase/Pwbase);

            obj.KPG = -[obj.parameter.KPdG; obj.parameter.KPqG];
            obj.KIG = -[obj.parameter.KIdG; obj.parameter.KIqG];
            obj.kappaP = [obj.parameter.KappaPd; obj.parameter.KappaPq];
            obj.kappaI = [obj.parameter.KappaId; obj.parameter.KappaIq];
            obj.KPR = [obj.parameter.KPdR; obj.parameter.KPqR];


            Zbase = obj.parameter.Vbase^2/(Pwbase);
            obj.parameter.LG = obj.parameter.LG/Zbase*omega0*(Pbase/Pwbase);
            obj.parameter.RG = obj.parameter.RG/Zbase*(Pbase/Pwbase);

            obj.parameter.Gsw = obj.parameter.Gsw*Zbase*(Pbase/Pwbase);
            obj.parameter.Cdc = obj.parameter.Cdc*1e-6*Zbase*omega0*(Pbase/Pwbase);
            obj.vdc_st = obj.parameter.Pr_st/obj.parameter.Vbase;


            obj.Shm = 1;
            obj.Shl = obj.parameter.Vl/obj.parameter.Vbase;

            Cp = 0.410955856214939;
            obj.coeff_Pa = 0.5*Cp*obj.parameter.rho*obj.parameter.A/Pbase;
            obj.Pa_st = obj.coeff_Pa * obj.parameter.windspeed_st^3;


            obj.parameter.Lb = obj.parameter.Lb/Zbase*omega0*(Pbase/Pwbase);
            obj.parameter.Rb = obj.parameter.Rb/Zbase*(Pbase/Pwbase);
            obj.parameter.Gb = obj.parameter.Gb*Zbase*(Pbase/Pwbase);
            obj.parameter.Cb = obj.parameter.Cb*1e-6*Zbase*omega0*(Pbase/Pwbase);

            obj.windspeed = @(t) obj.parameter.windspeed_st + obj.parameter.fl * sin(obj.parameter.w*t);

        end

%{
        % 川口先生のコードのまま
        function obj = wind_farm(wind_con, winp, sto_con, windspeed, gamma, baseMVA, omega0)
            obj.params.gamma = gamma;
            Pbase = baseMVA*1e6;
            Tbase = Pbase/(omega0/2);
            obj.params.omega0 = omega0;
            obj.params.Jl = wind_con(6)*(omega0/2)/Tbase;
            obj.params.Bl = wind_con(7)*(omega0/2)/Tbase;
            obj.params.Jr = wind_con(8)*(omega0/2)/Tbase;
            obj.params.Br = wind_con(9)*(omega0/2)/Tbase;
            obj.params.dc = wind_con(10)*(omega0/2)/Tbase;
            obj.params.Kc = wind_con(11)/Tbase;
            obj.params.Ng = wind_con(12);

            Pwbase = wind_con(19)*1e6;
            obj.params.p = wind_con(13);
            obj.params.Xs = wind_con(14)*(Pbase/Pwbase); % for grid base
            obj.params.Xr = wind_con(15)*(Pbase/Pwbase);
            obj.params.Xm = wind_con(16)*(Pbase/Pwbase);
            obj.params.Rs = wind_con(17)*(Pbase/Pwbase);
            obj.params.Rr = wind_con(18)*(Pbase/Pwbase);
            obj.params.tauG = winp(1);
            obj.params.KPG = -[winp(2); winp(4)];
            obj.params.KIG = -[winp(3); winp(5)];
            obj.params.kappaP = [winp(6); winp(8)];
            obj.params.kappaI = [winp(7); winp(9)];
            obj.params.KPR = [winp(14); winp(16)];
            obj.params.m_max = winp(13);

            obj.params.Pr_st = winp(10);
            obj.params.Qr_st = winp(11);

            Zbase = wind_con(20)^2/(wind_con(19)*1e6);
            obj.params.LG = wind_con(22)/Zbase*omega0*(Pbase/Pwbase);
            obj.params.RG = wind_con(23)/Zbase*(Pbase/Pwbase);

            obj.params.Gsw = wind_con(24)*Zbase*(Pbase/Pwbase);
            obj.params.Cdc = wind_con(25)*1e-6*Zbase*omega0*(Pbase/Pwbase);
            obj.params.vdc_st = winp(10)/wind_con(20);


            obj.params.Shm = 1;
            obj.params.Shl = wind_con(21)/wind_con(20);

            Cp = 0.410955856214939;
            obj.params.coeff_Pa = 0.5*Cp*wind_con(3)*wind_con(4)/Pbase;
            obj.params.Pa_st = obj.params.coeff_Pa * wind_con(5)^3;

            obj.windspeed = windspeed;

            obj.params.S = sto_con(5);
            obj.params.Lb = sto_con(2)/Zbase*omega0*(Pbase/Pwbase);
            obj.params.Rb = sto_con(4)/Zbase*(Pbase/Pwbase);
            obj.params.Gb = sto_con(3)*Zbase*(Pbase/Pwbase);
            obj.params.Cb = sto_con(1)*1e-6*Zbase*omega0*(Pbase/Pwbase);

        end
%}

        function nu = get_nu(obj)
            nu = 5;
        end

        function nx = get_nx(obj)
            nx = 18;
        end

        function [x, u] = get_equilibrium(obj, V, I)
            x = zeros(obj.get_nx, 1);
            u = zeros(obj.get_nu, 1);

            Vm = obj.Shm * V;
            Vl = obj.Shl * V;

            Ng = obj.parameter.Ng;
            Br = obj.parameter.Br;
            Bl = obj.parameter.Bl;
            % Pa_st = obj.Pa_st;

            Rs = obj.parameter.Rs;
            Rr = obj.parameter.Rr;
            Xs = obj.parameter.Xs;
            Xm = obj.parameter.Xm;
            Xr = obj.parameter.Xr;

            RG = obj.parameter.RG;
            Rb = obj.parameter.Rb;
            Gb = obj.parameter.Gb;
            S = obj.parameter.S;
            Gsw = obj.parameter.Gsw;

            Kc = obj.parameter.Kc;

            obj.Vabs_m_st = abs(Vm);
            iG_st = conj((obj.parameter.Pr_st+1j*obj.parameter.Qr_st)/Vl);
            x(8) = real(iG_st);
            x(9) = imag(iG_st);
            PQ_s_st = V*conj(I)/obj.parameter.gamma + (obj.parameter.Pr_st+1j*obj.parameter.Qr_st);
            is_st = conj(PQ_s_st/Vm);
            x(6) = real(is_st);
            x(7) = imag(is_st);
            x(12:13) = x(8:9);
            x(10:11) = x(8:9);

            ir_st = 1j*(Vm + (Rs+1j*Xs)*is_st)/Xm;
            x(4) = real(ir_st);
            x(5) = imag(ir_st);

            T_st = Xm*imag(ir_st*conj(is_st));
            a = Ng^2*Br + Bl;
            b = Ng * T_st;
            c = -obj.Pa_st;
            x(1) = (-b + sqrt(b^2-4*a*c))/(2*a);
            x(2) = Ng * x(1);
            x(3) = (Ng*T_st + Ng^2*Br*x(1))/Kc;

            omega_r = x(2);
            vr_st = -(Rr+1j*Xr*(1-omega_r))*ir_st - 1j*Xm*(1-omega_r)*is_st;
            obj.vdc_st = sqrt(...
                (real(Vl*conj(iG_st)+vr_st*conj(ir_st))-RG*abs(iG_st)^2)/...
                (2*Gsw+Gb*S^2/(1+Rb*Gb)));
            x(16) = obj.vdc_st;
            vb_st = S*obj.vdc_st/(1+Rb*Gb);
            x(17) = vb_st;
            x(18) = -Gb * vb_st;
            x(14:15) = [real(vr_st); imag(vr_st)];

            obj.omega_r_st = x(2);
            obj.ir_st = x(4:5);

            % obj.numerical_diff(x, [real(V); imag(V)]);
        end

        function [dx, constraint] = get_dx_constraint(obj, t, x, V, I, u)
            dc = obj.parameter.dc;
            Bl = obj.parameter.Bl;
            Ng = obj.parameter.Ng;
            Kc = obj.parameter.Kc;
            Br = obj.parameter.Br;
            Jl = obj.parameter.Jl;
            Jr = obj.parameter.Jr;
            Rr = obj.parameter.Rr;
            Xr = obj.parameter.Xr;
            Xm = obj.parameter.Xm;
            Xs = obj.parameter.Xs;
            Rs = obj.parameter.Rs;

            kappaI = obj.kappaI;
            kappaP = obj.kappaP;

            KIG = obj.KIG;
            KPG = obj.KPG;
            KPR = obj.KPR;
            Vabs_m_st = obj.Vabs_m_st;
            omega_r_st = obj.omega_r_st;

            vdc_st = obj.vdc_st;

            RG = obj.parameter.RG;
            LG = obj.parameter.LG;

            tauG = obj.parameter.tauG;

            m_max = obj.parameter.m_max;
            Shm = obj.Shm;
            Shl = obj.Shl;
            gamma = obj.parameter.gamma;

            Qr_st = obj.parameter.Qr_st;

            Vm = Shm * V;
            Vl = Shl * V;

            omega0_m = obj.parameter.omega0/2;
            omega0 = obj.parameter.omega0;

            Gsw = obj.parameter.Gsw;

            beta = Xs*Xr-Xm^2;

            Cdc = obj.parameter.Cdc;
            S = obj.parameter.S;
            Cb = obj.parameter.Cb;
            Gb = obj.parameter.Gb;
            Rb = obj.parameter.Rb;
            Lb = obj.parameter.Lb;

            dx = zeros(obj.get_nx, 1);

            omega_r = x(2);
            iG = x(8:9);
            vdc = x(16);
            ChiG = x(10:11);
            zetaG = x(12:13);
            ids = x(6);
            iqs = x(7);
            iqr = x(5);
            idr = x(4);
            ir = [idr; iqr];
            ChiR = x(14:15);
            idcp = x(18);
            vb = x(17);

            uR = u(3:4);
            uG = u(1:2);
            uS = u(5);

            Vabs_m = sqrt(Vm'*Vm);
            I_ = gamma*(Shm*x(6:7) - Shl*x(8:9));

            Qr = Vl'*[-iG(2); iG(1)];

            T = Xm*(ids*iqr - iqs*idr);
            Ai = [
                -Rr*Xs, beta-omega_r*Xs*Xr, Rs*Xm, -omega_r*Xs*Xm;
                -beta+omega_r*Xs*Xr, -Rr*Xs, omega_r*Xs*Xm, Rs*Xm;...
                Rr*Xm, omega_r*Xr*Xm, -Rs*Xr, beta+omega_r*Xm^2;...
                -omega_r*Xr*Xm, Rr*Xm, -beta-omega_r*Xm^2, -Rs*Xr]/beta;
            Bi = [-Xs, 0;
                0, -Xs;
                Xm, 0;
                0, Xm]/beta;
            Gi = [Xm, 0, -Xr, 0; 0 Xm, 0, -Xr]'/beta;

            ir_ref = KPR.*[Vabs_m-Vabs_m_st; omega_r-omega_r_st] + obj.ir_st;

            mR = 2*(kappaP.*(ir-ir_ref) + ChiR + uR)/vdc;
            mR(mR > m_max) = m_max;
            mR(mR < -m_max) = -m_max;

            Pa = obj.windspeed(t)^3*obj.coeff_Pa;
            vr = mR*vdc/2;

            iGref = KPG.*[(vdc-vdc_st); gamma*(Qr - Qr_st)] + zetaG;

            mG = (Vl + [LG/omega0/tauG LG;-LG LG/omega0/tauG]*iG -RG*ChiG - LG*iGref/omega0/tauG + uG)*2/vdc;
            mG(mG>m_max) = m_max;
            mG(mG<-m_max) = -m_max;

            p = S + uS;
            p(p<0) = 0;
            idc = p * idcp;
            vdcp = p * vdc;


            dx(1:3) = ([-(dc+Bl), dc/Ng, -Kc;
                dc/Ng, -(dc/Ng^2+Br), Kc/Ng;
                omega0_m, -omega0_m/Ng, 0] * x(1:3) + [Pa/x(1); -T; 0])./[Jl;Jr;1];
            dx(4:7) = Ai * x(4:7) + Gi*Vm + Bi*vr;
            dx(8:9) = ([-RG, LG; -LG, -RG] * iG + Vl - mG*vdc/2)*omega0/LG;
            dx(10:11) = (iGref- iG)/tauG;
            dx(12:13) = KIG.*[vdc-vdc_st; gamma*(Qr - Qr_st)];
            dx(14:15) = kappaI.*(ir - ir_ref);
            dx(16) = ((iG'*Vl + ir'*vr - RG*(iG'*iG))/(2*vdc) - Gsw*vdc + idc/2)*omega0/Cdc;
            dx(17) = (-idcp - Gb*vb)*omega0/Cb;
            dx(18) = (vb-Rb*idcp-vdcp)*omega0/Lb;

            constraint = I - I_;
        end
    end
end

