classdef vsm1axis < component.GFM.ReferenceModel.AbstractClass
    properties(SetAccess=protected)
        P_st
        Vabs_st
        Q_st
        Vfd_st
        avr
        pss
        E_st
    end

    methods
        function obj = vsm1axis(params)
            if nargin==0
                params = readtable([mfilename("fullpath"),'.csv']);
            end
            obj.parameter = params(:,{'Xd', 'Xd_p', 'Xq', 'Td_p', 'M', 'D','Kv'});
            %obj.avr = component.generator.avr.base;
            Te = 0.05;
            Ka = 2;
            avr_params = table(Te, Ka);
            obj.avr = component.generator.avr.sadamoto2019(avr_params);

            No_bus = 2; Kpss = 200; Tpss = 10; TL1p = 0.05; TL1 = 0.015; TL2p = 0.08; TL2 = 0.01;
            pss_data = table(No_bus,Kpss,Tpss,TL1p,TL1,TL2p,TL2);
            obj.pss = component.generator.pss.base(pss_data);
        end
       

        function tag = naming_state(~)
            tag = {'delta','omega','Eq','Vfd'};
        end

        function nx = get_nx(obj)
            nx = 4;
        end
        
        function nu = get_nu(obj)
            nu = 0;
        end

        
        % 機器のダイナミクスを決めるメソッド
            function [dx, con] = get_dx_constraint(obj, ~, x, V, I, u)
                p = obj.parameter.Variables;
                Xd   = p(1);
                Xdp  = p(2);
                Xq   = p(3);
                Td_p = p(4);
                M    = p(5);
                d    = p(6);
                Kv = p(7);
                
                % 状態の抽出
                
                delta = x(1);
                omega = x(2);
                E     = x(3);
                zeta = x(4);
                

                % 状態の抽出
                %{
                delta = x(1);
                omega = x(2);
                E     = x(3);
                x_avr = x(4);
                x_pss = x(5:7);
                %}

                Vabs = norm(V);
                Vangle = atan2(V(2), V(1));
                
                Vq = V(1)*cos(delta)+V(2)*sin(delta);
                Vd = V(1)*sin(delta)-V(2)*cos(delta);
                Iq = I(1)*cos(delta)+I(2)*sin(delta);
                Id = I(1)*sin(delta)-I(2)*cos(delta);
                
                Pout = Vq*Iq + Vd*Id;
                Qout = Vq*Id - Vd*Iq;
                          
                ddelta = obj.omega0 * omega;
                domega = (- d*omega - Pout + obj.P_st )/M;

                Efd  = Xd*E/Xdp - (Xd/Xdp-1)*Vq;

                
                Vfd = 0.001*(obj.Q_st - Qout + obj.Vabs_st - norm(V) )+zeta;
                dE     = ( -  E - (Xd-Xdp)*Id + Vfd)/Td_p;
                dzeta = 0.1*(obj.Q_st - Qout + obj.Vabs_st - norm(V) );
                
                dx = [ddelta; domega; dE; dzeta];
                con = [];
                

                %using pss and avr
                %{
                [dx_pss, v  ] = obj.pss.get_u(x_pss, omega, 0);
                [dx_avr,Vfd] = obj.avr.get_Vfd(x_avr, Vabs, Efd, [0;0]);

                dE     = ( -  E - (Xd-Xdp)*Id + Vfd)/Td_p;
                dx = [ddelta; domega; dE; dx_avr; dx_pss];
                con = [];
                %}
            end

        function [delta,omega,Vdq] = get_Vterminal(obj,x,V,I,u) %#ok

            % 状態の抽出
            delta = x(1);
            omega = x(2);
            E     = x(3);
            zeta = x(4);
            %{
            Vq = V(1)*cos(delta)+V(2)*sin(delta);
            Vd = V(1)*sin(delta)-V(2)*cos(delta);
            Iq = I(1)*cos(delta)+I(2)*sin(delta);
            Id = I(1)*sin(delta)-I(2)*cos(delta);

            Pout = Vq*Iq + Vd*Id;
            Qout = Vq*Id - Vd*Iq;


            p = obj.parameter.Variables;
            Xd   = p(1);
            Xdp  = p(2);
            Xq   = p(3);

            % Id, Iqを定義
            Iq = I(1)*cos(delta)+I(2)*sin(delta);
            Id = I(1)*sin(delta)-I(2)*cos(delta);

            % Vd, Vqを定義
            Vd = Iq*Xq;
            Vq = E - Id*Xdp;
            %}
            Vdq = [0; E];
        end

        function [x_ref, u_ref] = get_equilibrium(obj,V,I)  
            Vabs = abs(V);
            Vangle = angle(V);
            Power = V * conj(I);
            P = real(Power);
            Q = imag(Power);

            L_g  = obj.converter.parameter.L_g / obj.converter.Lbase;
            p = obj.parameter.Variables;
            Xd   = p(1);
            Xdp  = p(2);
            Xq   = p(3);

            %Calculate delta_st 
            %{
            delta_st = Vangle + atan((P * L_g) / (Vabs^2 + Q * L_g));
            Id = real(I)*sin(delta_st)-imag(I)*cos(delta_st); %Iabs*sin(delta-Iang)   
            Iq = real(I)*cos(delta_st)+imag(I)*sin(delta_st); %Iabs*cos(delta-Iang)


            Eq_st = (P * (L_g))/ (Vabs * sin(delta_st - Vangle));

            Vq = Eq_st - Xdp*Id - Id*L_g;
            Vd = Iq*Xq + Iq*L_g;
            %}
            
           
            syms del e
            Iq = real(I)*cos(del)+imag(I)*sin(del); %Iabs*cos(delta-Iang)
            Id = real(I)*sin(del)-imag(I)*cos(del); %Iabs*sin(delta-Iang)
            Vq = e - Xdp*Id - Id*L_g;
            Vd = Iq*Xq+ Iq*L_g;

    
            eq1 = P-Vq*Iq-Vd*Id == 0;
            eq2 = Q-Vq*Id+Vd*Iq == 0;
            
            S = solve([eq1;eq2],[del e]);
            if(S.e(1)>0);delta_st = double(S.del(1));Eq_st = double(S.e(1));
            else; delta_st = double(S.del(2)); Eq_st= double(S.e(2));end

            Iq = real(I)*cos(delta_st)+imag(I)*sin(delta_st); %Iabs*cos(delta-Iang)
            Id = real(I)*sin(delta_st)-imag(I)*cos(delta_st); %Iabs*sin(delta-Iang)

            Vfd_st = Eq_st + (Xd-Xdp)*Id;
            omega_st = 0;
            vq_st = Eq_st;
            vd_st = 0;
            zeta_st = Vfd_st;
            obj.E_st = Eq_st;
            v_st = [vd_st;vq_st];

            % if strcmp(flag,'init')    
                obj.Vabs_st = norm(V);
                obj.P_st = P;
                obj.Q_st = Q;
                obj.Vfd_st = Vfd_st;
            % end

            % Stack the calculated equilibrium points and steady-state inputs
                x_ref = [delta_st; omega_st; Eq_st; zeta_st];
                u_ref = [];
            %using pss and avr
            %{
            [x_avr_st,u_avr] = obj.avr.initialize(Vfd_st, Vabs);
            [x_pss_st,u_pss] = obj.pss.initialize();

                x_ref = [delta_st; omega_st; Eq_st; x_avr_st; x_pss_st];
                u_ref = [];
            %}

        end
        
    end
    
end


