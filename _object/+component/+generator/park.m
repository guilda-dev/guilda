classdef park < component.generator.base % 状態・パラメーターはqを先においている
    %edited
    %VとIの関係をedit
    
    methods
        function obj = park(parameter)
            if isstruct(parameter)
                parameter = struct2table(parameter);
            end
            % PARK用のパラメータ名に変更
            obj.parameter = parameter(:, {'Xq', 'Xq_prime', 'Xq_pp','Xd', 'Xd_prime', 'Xd_pp','X_ls','Tdo', 'Tqo', 'TTdo','TTqo','M', 'D'});   % ソートしてるだけ
            obj.set_avr( component.generator.avr.base() );
            obj.set_governor( component.generator.governor.base() );
            obj.set_pss( component.generator.pss.base() );
            obj.system_matrix = struct();
        end
        
        function name_tag = get_x_name(obj)
            %Added psiq, psid
            gen_state = {'delta','omega','Eq','Ed','psiq','psid'};
            avr_state = obj.avr.naming_state;
            pss_state = obj.pss.naming_state;
            governor_state = obj.governor.naming_state;
            name_tag = horzcat(gen_state,avr_state,pss_state,governor_state);
        end

        function u_name = naming_port(obj)
            u_avr = obj.avr.naming_port;
            u_pss = obj.pss.naming_port;
            u_gov = obj.governor.naming_port;
            u_name = [u_avr,u_pss,u_gov];
        end
        
        function out = get_nx(obj)
            out = 6 + obj.avr.get_nx() + obj.pss.get_nx() + obj.governor.get_nx();
        end
        
        function nu = get_nu(obj)
            nu = obj.avr.get_nu() + obj.pss.get_nu() + obj.governor.get_nu();
        end
        
        function [dx, con] = get_dx_constraint(obj, ~, x, V, I, u)
            Xd  = obj.parameter.Xd;
            Xdp = obj.parameter.Xd_prime;
            Xdpp = obj.parameter.Xd_pp;
            Xq  = obj.parameter.Xq;
            Xqp = obj.parameter.Xq_prime;
            Xqpp = obj.parameter.Xq_pp;
            d   = obj.parameter.D;
            Xls = obj.parameter.X_ls;

            nx_avr = obj.avr.get_nx();
            nx_pss = obj.pss.get_nx();
            nx_gov = obj.governor.get_nx();

            nu_avr = obj.avr.get_nu();
            nu_pss = obj.pss.get_nu();
            nu_gov = obj.governor.get_nu();

            nx = 6;            
            x_gen = x(1:nx);
            x_avr = x(nx+(1:nx_avr));
            x_pss = x(nx+nx_avr+(1:nx_pss));
            x_gov = x(nx+nx_avr+nx_pss+(1:nx_gov));
            
            %状態の抽出
            delta = x_gen(1);
            omega = x_gen(2);
            Eq = x_gen(3);
            Ed = x_gen(4);
            psiq = x_gen(5);
            psid = x_gen(6);

            % 入力の抽出
            u_avr = u(1:nu_avr);
            u_pss = u(nu_avr+(1:nu_pss));
            u_gov = u(nu_avr+nu_pss+(1:nu_gov));

            Vabs = norm(V);
            Vangle = atan2(V(2), V(1));
            
            % Vd, Vqを定義
            Vq = V(1)*cos(delta)+V(2)*sin(delta); %Vabs*cos(delta-Vang)
            Vd = V(1)*sin(delta)-V(2)*cos(delta); %Vabs*sin(delta-Vang)
            
            %omega を無視せずにId,Iq を定義
            for_Id = (1+omega)*((Xdpp-Xls)*Eq/(Xdp-Xls) + (Xdp-Xdpp)*psid/(Xdp-Xls));
            for_Iq = (1+omega)*((Xqpp-Xls)*Ed/(Xqp-Xls) - (Xqp-Xqpp)*psiq/(Xqp-Xls));
            Iq = (Vd - for_Iq)/(Xqpp);
            Id = (for_Id - Vq)/(Xdpp);
            %Iq = (Vd - for_Iq)/((1+omega)*Xqpp);
            %Id = (for_Id - Vq)/((1+omega)*Xdpp);
            
        
            % omegaを無視してId, Iqを定義
            %{
            for_Id = (Xdpp-Xls)*Eq/(Xdp-Xls) + (Xdp-Xdpp)*psid/(Xdp-Xls);
            for_Iq = (Xqpp-Xls)*Ed/(Xqp-Xls) - (Xqp-Xqpp)*psiq/(Xqp-Xls);
            Iq = (Vd - for_Iq)/Xqpp;
            Id = (for_Id - Vq)/Xdpp;
            %}

            
            Efd = Eq + (Xd-Xdp)*(Id- ((Xdp-Xdpp)/(Xdp-Xls)^2)*(psid+(Xdp-Xls)*Id-Eq));
            Efq = Ed - (Xq-Xqp)*(Iq- ((Xqp-Xqpp)/(Xqp-Xls)^2)*(psiq+(Xqp-Xls)*Iq+Ed));
            
            [dx_pss, v] = obj.pss.get_u(x_pss, omega, u_pss);
            [dx_avr, Vfd] = obj.avr.get_Vfd(x_avr, Vabs, Efd, u_avr-v);
            [dx_gov, Pm] = obj.governor.get_P(x_gov, omega, u_gov);
                
            %dEq = (-Efd + Vfd)/Tdo;
            %dEd = (-Efq)/Tqo;
            dEq = (-Efd + Vfd);
            dEd = (-Efq);

            ddelta = omega; 
            domega = Pm - d*omega - Vq*Iq - Vd*Id;
            %domega = (Pm - d*omega - Vq*Iq - Vd*Id)/M;

            %dpsid, dpsiqを追加
            psiq_ = -psiq-Ed-(Xqp-Xls)*Iq;
            psid_ = -psid+Eq-(Xdp-Xls)*Id;
            %dpsiq = psiq_/TTqo;
            %dpsid = psid_/TTdo;
            dpsiq = psiq_;
            dpsid = psid_;

            % |I|cosI, |I|sinIを逆算
            Ir = Id*sin(delta)+Iq*cos(delta);
            Ii = -Id*cos(delta)+Iq*sin(delta);
            
            con = I - [Ir; Ii];
            
            dx = [ddelta; domega; dEq; dEd; dpsiq; dpsid; dx_avr; dx_pss; dx_gov];
        end 

        function M = Mass(obj)
            Tdo = obj.parameter.Tdo;
            Tqo = obj.parameter.Tqo;
            TTdo = obj.parameter.TTdo;
            TTqo = obj.parameter.TTqo;
            M   = obj.parameter.M;
            
            Msys = diag([1/obj.omega0,M,Tdo,Tqo,TTqo,TTdo]);
            Mavr = obj.avr.Mass;
            Mpss = obj.pss.Mass;
            Mgov = obj.governor.Mass;

            M = blkdiag(Msys,Mavr,Mpss,Mgov,0,0);
        end

        function x_st = set_equilibrium(obj,V,I)
            if nargin<2
                V = obj.V_equilibrium;
                I = obj.I_equilibrium;
            end
            Vangle = angle(V);
            Vabs =  abs(V);
            Pow = conj(I)*V;
            P = real(Pow);
            Q = imag(Pow);

            Xd = obj.parameter{:, 'Xd'};
            Xdp = obj.parameter{:, 'Xd_prime'};
            Xq = obj.parameter{:, 'Xq'};
            Xqp = obj.parameter{:, 'Xq_prime'};
            Xls = obj.parameter{:,'X_ls'};
            Xdpp = obj.parameter{:,'Xd_pp'};
            Xqpp = obj.parameter{:,'Xq_pp'};

            syms del e
            Iq = real(I)*cos(del)+imag(I)*sin(del); %Iabs*cos(delta-Iang)
            Id = real(I)*sin(del)-imag(I)*cos(del); %Iabs*sin(delta-Iang)
            Ed = (Xq-Xqp)*Iq;
            psiq = -Ed-(Xqp-Xls)*Iq;
            psid = e-(Xdp-Xls)*Id;
            for_Id = (Xdpp-Xls)*e/(Xdp-Xls) + (Xdp-Xdpp)*psid/(Xdp-Xls);
            for_Iq = (Xqpp-Xls)*Ed/(Xqp-Xls) - (Xqp-Xqpp)*psiq/(Xqp-Xls);
            Vq = -Xdpp*Id + for_Id;
            Vd = Xqpp*Iq+for_Iq;
            
            eq1 = P-Vq*(Iq)-Vd*(Id) == 0;
            eq2 = Q-Vq*(Id)+Vd*(Iq) == 0;
            eq = [eq1;eq2];
            S = solve(eq);
            %solve(eq) gives more than 1 solution
            if(S.e(1)>0);delta = double(S.del(1));Eq = double(S.e(1));
            else; delta = double(S.del(2)); Eq = double(S.e(2));end

            Iq = real(I)*cos(delta)+imag(I)*sin(delta); %Vabs*cos(delta-Vang)
            Id = real(I)*sin(delta)-imag(I)*cos(delta); %Vabs*sin(delta-Vang)

            Ed = (Xq-Xqp)*Iq;
            psiq = -Ed-(Xqp-Xls)*Iq;
            psid = Eq-(Xdp-Xls)*Id;
            
            Vfd = Eq + (Xd-Xdp)*Id;

            %{
            delta = Vangle + atan(P/(Q+Vabs^2/Xq));
            Enum = Vabs^4 + Q^2*Xdp*Xq + Q*Vabs^2*Xdp + Q*Vabs^2*Xq + P^2*Xdp*Xq;
            Eden = Vabs*sqrt(P^2*Xq^2 + Q^2*Xq^2 + 2*Q*Vabs^2*Xq + Vabs^4);
            E = Enum/Eden;
            Vfd = Xd*E/Xdp - (Xd/Xdp-1)*Vabs*cos(delta-Vangle);
            %}

            [x_avr,u_avr] = obj.avr.initialize(Vfd, Vabs);
            [x_gov,u_gov] = obj.governor.initialize(P);
            [x_pss,u_pss] = obj.pss.initialize();
            x_st = [delta; 0; Eq; Ed; psiq; psid; x_avr; x_gov; x_pss];
            obj.x_equilibrium = x_st;
            obj.u_equilibrium = [u_avr;u_pss;u_gov];
            
            obj.set_linear_matrix();
        end
    end        
end


