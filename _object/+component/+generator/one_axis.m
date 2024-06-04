classdef one_axis < component.generator.base
%モデル　: 同期発電機の１軸モデル
%　状態　: ３変数「回転子偏角"delta",周波数偏差"omega",内部電圧"Ed"」
%　　　　  * AVRやPSSが付加されるとそれらの状態も追加される
%　入力　: ２ポート「界磁入力"Vfield", 機械入力"Pmech"」
%実行方法: obj =　component.generator.one_axis(parameter)
%　引数　: parameter : table型．「'Xd', 'Xd_p','Xq','Td_p','M','D'」を列名として定義

 
    methods
        function obj = one_axis(parameter)
            arguments
                parameter = 'NGT2';
            end
            obj@component.generator.base(parameter)

            obj.parameter = obj.parameter(:, {'Xd', 'Xd_p', 'Xq', 'Td_p', 'M', 'D'});
            obj.set_avr(      component.generator.avr.base()      );
            obj.set_governor( component.generator.governor.base() );
            obj.set_pss(      component.generator.pss.base()      );
        end

        function name_tag = naming_state(obj)
            gen_state = {'delta','omega','Ed'};
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

        % 機器のダイナミクスを決めるメソッド
            function [dx, con] = get_dx_constraint(obj, ~, x, V, I, u)
                Xd   = obj.parameter.Xd;
                Xdp  = obj.parameter.Xd_p;
                Xq   = obj.parameter.Xq;
                d    = obj.parameter.D;
                Td_p = obj.parameter.Td_p;
                M    = obj.parameter.M;

                nx_avr = obj.avr.get_nx();
                nx_pss = obj.pss.get_nx();
                nx_gov = obj.governor.get_nx();

                nu_avr = obj.avr.get_nu();
                nu_pss = obj.pss.get_nu();
                nu_gov = obj.governor.get_nu();

                % 状態の抽出
                delta = x(1);
                omega = x(2);
                E     = x(3);
                x_avr = x(3+(1:nx_avr));
                x_pss = x(3+nx_avr+(1:nx_pss));
                x_gov = x(3+nx_avr+nx_pss+(1:nx_gov));

                % 入力の抽出
                u_avr = u(1:nu_avr);
                u_pss = u(nu_avr+(1:nu_pss));
                u_gov = u(nu_avr+nu_pss+(1:nu_gov));


                Vabs = norm(V);
                Vangle = atan2(V(2), V(1));

                Vabscos = V(1)*cos(delta)+V(2)*sin(delta);
                Vabssin = V(1)*sin(delta)-V(2)*cos(delta);

                Ir =  (E-Vabscos)*sin(delta)/Xdp + Vabssin*cos(delta)/Xq;
                Ii = -(E-Vabscos)*cos(delta)/Xdp + Vabssin*sin(delta)/Xq;

                Efd  = Xd*E/Xdp - (Xd/Xdp-1)*Vabscos;
                Pout = Vabs*E*sin(delta-Vangle)/Xdp - Vabs^2*(1/Xdp-1/Xq)*sin(2*(delta-Vangle))/2;


                [dx_pss, v  ] = obj.pss.get_u(x_pss, omega, u_pss);
                [dx_avr, Vfd] = obj.avr.get_Vfd(x_avr, Vabs, Efd, u_avr-v);
                [dx_gov, Pm ] = obj.governor.get_P(x_gov, omega, u_gov);

                ddelta = obj.omega0 * omega;
                domega = (- d*omega - Pout + Pm )/M;
                dE     = (          -  Efd + Vfd)/Td_p;

                dx = [ddelta; domega; dE; dx_avr; dx_pss; dx_gov];
                con = I - [Ir; Ii];
            end

            function [A, B, C, D, BV, DV, BI, DI, R, S] = get_linear_matrix(obj, x_st, Vst)
                if nargin < 2 || isempty(x_st)
                    x_st = obj.x_equilibrium;
                end
                if nargin < 3 || isempty(Vst)
                    Vst =  tools.complex2vec(obj.V_equilibrium);
                end

                ret = get_sys(obj, x_st, Vst);
                ret_u = ret('I', {'u_avr',  'u_governor'});
                ret_V = ret('I', 'Vin');

                A = ret.a;
                B = ret_u.b;
                C = ret_u.c;
                D = ret_u.d;
                BV = ret_V.b;
                DV = ret_V.d;
                BI = zeros(size(A, 1), 2);
                DI = -eye(2);
                R = BV;
                S = zeros(1, size(A, 1));
                S(2) = 1;
                R = [];
                S = [];
            end

        % 定常潮流状態からモデルの平衡点と定常入力値を求めるメソッド
            function [x_st,u_st] = get_equilibrium(obj,V,I)
                Vangle = angle(V);
                Vabs =  abs(V);
                Pow = conj(I)*V;
                P = real(Pow);
                Q = imag(Pow);
                Xd  = obj.parameter{:, 'Xd'};
                Xdp = obj.parameter{:, 'Xd_p'};
                Xq  = obj.parameter{:, 'Xq'};
                delta = Vangle + atan(P/(Q+Vabs^2/Xq));
                Enum = Vabs^4 + Q^2*Xdp*Xq + Q*Vabs^2*Xdp + Q*Vabs^2*Xq + P^2*Xdp*Xq;
                Eden = Vabs*sqrt(P^2*Xq^2 + Q^2*Xq^2 + 2*Q*Vabs^2*Xq + Vabs^4);
                E = Enum/Eden;
                Vfd = Xd*E/Xdp - (Xd/Xdp-1)*Vabs*cos(delta-Vangle);
                [x_avr,u_avr] = obj.avr.initialize(Vfd, Vabs);
                [x_gov,u_gov] = obj.governor.initialize(P);
                [x_pss,u_pss] = obj.pss.initialize();

                x_st = [delta; 0; E; x_avr; x_pss; x_gov];
                u_st = [u_avr; u_pss; u_gov];
            end

        % GFMIのリファレンスモデルとして実装するために必要なメソッド
            function [delta,omega,Vdq] = get_Vterminal(obj,x,V,I,u)%#ok
                delta = x(1);
                omega = x(2);

                nx_avr = obj.avr.get_nx();
                nx_pss = obj.pss.get_nx();
                x_avr = x(2+(1:nx_avr));
                x_pss = x(2+nx_avr+(1:nx_pss));

                [~,  v ] = obj.pss.get_u(x_pss, omega);
                [~, Vfd] = obj.avr.get_Vfd(x_avr, norm(V), 0, u(1)-v);

                Vdq = [0;Vfd];
            end

        function [ret, sys_fb, sys_V] = get_sys(obj, x_st, Vst)
            if nargin < 2 || isempty(x_st)
                x_st = obj.x_equilibrium;
            end
            if nargin < 3 || isempty(Vst)
                Vst =  tools.complex2vec(obj.V_equilibrium);
            end
            omega0 = obj.omega0;
            Xd  = obj.parameter{:, 'Xd'};
            Xdp = obj.parameter{:, 'Xd_p'};
            Xq  = obj.parameter{:, 'Xq'};
            Td_p= obj.parameter{:, 'Td_p'};
            M   = obj.parameter{:, 'M'};
            D   = obj.parameter{:, 'D'};

            A_swing = [0 omega0 0;
                0 -D/M 0;
                0 0 -Xd/(Xdp*Td_p)];
            % u1 = Pmech;
            % u2 = Vfd;
            % u3 = Pout
            % u4 = Vabscos
            B_swing = [0, 0, 0, 0;
                1/M, 0, -1/M, 0;
                0, 1/Td_p, 0, -1/Td_p
                ];
            % y = [delta, E]
            C_swing = eye(3);
            sys_swing = ss(A_swing, B_swing, C_swing, 0);
            OutputGroup = struct();
            OutputGroup.delta = 1;
            OutputGroup.omega = 2;
            OutputGroup.E = 3;
            sys_swing.OutputGroup = OutputGroup;
            InputGroup = struct();
            InputGroup.Pmech = 1;
            InputGroup.Vfd = 2;
            InputGroup.Pout = 3;
            InputGroup.Ein_swing = 4;
            sys_swing.InputGroup = InputGroup;

            delta = x_st(1);
            E = x_st(3);

            dVabscos_dV = [cos(delta), sin(delta)];
            dVabssin_dV = [sin(delta), -cos(delta)];
            dIr_dV = -dVabscos_dV*sin(delta)/Xdp + dVabssin_dV*cos(delta)/Xq;
            dIi_dV =  dVabscos_dV*cos(delta)/Xdp + dVabssin_dV*sin(delta)/Xq;

            Vabscos = Vst(1)*cos(delta)+Vst(2)*sin(delta);
            Vabssin = Vst(1)*sin(delta)-Vst(2)*cos(delta);
            dVabscos = -Vabssin;
            dVabssin =  Vabscos;

            dEfd = -[dVabscos, 0, dVabscos_dV] * (Xd/Xdp-1) + [0, Xd/Xdp, 0, 0];
            dEin = -[dVabscos, 0, dVabscos_dV] * (Xd/Xdp-1);

            dIr_dd = (-dVabscos*sin(delta)+(E-Vabscos)*cos(delta))/Xdp + (dVabssin*cos(delta)-Vabssin*sin(delta))/Xq;
            dIi_dd = (dVabscos*cos(delta)+(E-Vabscos)*sin(delta))/Xdp + (dVabssin*sin(delta)+Vabssin*cos(delta))/Xq;

            Ist =  [(E-Vabscos)*sin(delta)/Xdp + Vabssin*cos(delta)/Xq;
                -(E-Vabscos)*cos(delta)/Xdp + Vabssin*sin(delta)/Xq];

            % (delta, E, V) => (Ir, Ii)
            KI = [dIr_dd,  sin(delta)/Xdp, dIr_dV;
                dIi_dd, -cos(delta)/Xdp, dIi_dV];

            dP = Vst'*KI + Ist'*[zeros(2), eye(2)];

            R_I = tools.matrix_polar_transform(obj.I_equilibrium);

            sys_fb = ss([dP; dEfd; dEin; KI; R_I*KI]);
            InputGroup = struct();
            InputGroup.delta = 1;
            InputGroup.E = 2;
            InputGroup.V = 3:4;
            sys_fb.InputGroup = InputGroup;
            OutputGroup = struct();
            OutputGroup.P = 1;
            OutputGroup.Efd = 2;
            OutputGroup.Ein = 3;
            OutputGroup.I = 4:5;
            OutputGroup.I_polar = 6:7;
            sys_fb.OutputGroup = OutputGroup;

            Vabs = norm(Vst);

            sys_V = ss([eye(2); Vst'/Vabs]);
            sys_V.InputGroup.Vin = 1:2;
            OutputGroup = struct();
            OutputGroup.V = 1:2;
            OutputGroup.Vabs = 3;
            sys_V.OutputGroup = OutputGroup;

            R_V = tools.matrix_polar_transform(obj.V_equilibrium, true);
            sys_V_polar = ss([0,1; R_V]);
            sys_V_polar.InputGroup.Vin_polar = 1:2;
            sys_V_polar.OutputGroup.Vabs_p = 1;
            sys_V_polar.OutputGroup.V_p = 2:3;

            sys_avr = obj.avr.get_sys();
            sys_pss = obj.pss.get_sys();
            sys_gov = obj.governor.get_sys();
            G = blkdiag(sys_swing, sys_fb, sys_V, sys_avr, -sys_pss, sys_gov, sys_V_polar);
            ig = G.InputGroup;
            og = G.OutputGroup;
            feedin = [ig.Pout, ig.Efd, ig.Ein_swing, ig.delta, ig.E, ig.V, ig.Vabs, ig.Vfd, ig.u_avr, ig.omega, ig.omega_governor, ig.Pmech, ig.V, ig.Vabs];
            feedout = [og.P, og.Efd, og.Ein,  og.delta, og.E, og.V, og.Vabs, og.Vfd, og.v_pss, og.omega, og.omega, og.Pmech, og.V_p, og.Vabs_p];
            I = ss(eye(numel(feedin)));

            ret = feedback(G, I, feedin, feedout, 1);
        end

        function [sys, sys_linear, sys_v] = get_sys4retrofit(obj)
            if ~isa(obj.avr, 'component.generator.avr.sadamoto2019')
                error('avr model assumes sadamoto2019 in retrofit controller');
            end
            if ~isa(obj.pss, 'component.generator.pss.base')
                error('pss model assumes base in retrofit controller');
            end
            if ~isa(obj.governor, 'component.generator.governor.base')
                error('governor model assumes base in retrofit controller');
            end

            omega0 = obj.omega0;
            Xd  = obj.parameter{:, 'Xd'};
            Xdp = obj.parameter{:, 'Xd_p'};
            Xq  = obj.parameter{:, 'Xq'};
            Tdp= obj.parameter{:, 'Td_p'};
            M   = obj.parameter{:, 'M'};
            D   = obj.parameter{:, 'D'};
            Tavr = obj.avr.Te;
            Kavr = obj.avr.Ka;
            [Apss, Bpss, Cpss, Dpss] = ssdata(obj.pss.sys);

            % x = [delta; omega; E; x_avr; x_pss]
            A_linear = [0, omega0, 0, 0, zeros(1,3);
                0, -D/M, 0, 0, zeros(1,3);
                0, 0, -Xd/Xdp/Tdp, 1/Tdp, zeros(1,3);
                0, Kavr*Dpss/Tavr, 0, -1/Tavr, Kavr*Cpss/Tavr;
                zeros(3,1), Bpss, zeros(3,2), Apss];
            % u = [u_governor; u_avr]
            Bu_linear = [0,0; 1/M, 0; 0, 0; 0, -Kavr/Tavr; zeros(3,2)];
            % v = [v_omega; v_E; v_x_avr]
            Bv_linear = [0, 0, 0; 1/M, 0, 0; 0, 1/Tdp, 0; 0, 0, 1/Tavr; zeros(3,3)];
            % w = [delta, E]
            C_linear = [1, 0, 0, 0, zeros(1,3); 0, 0, 1, 0, zeros(1,3)];
            sys_linear = ss(A_linear, [Bu_linear, Bv_linear], C_linear, 0);
            sys_linear.InputGroup.u_governor = 1;
            sys_linear.InputGroup.u_avr = 2;
            sys_linear.InputGroup.v_omega = 3;
            sys_linear.InputGroup.v_E = 4;
            sys_linear.InputGroup.v_x_avr = 5;
            sys_linear.OutputGroup.delta = 1;
            sys_linear.OutputGroup.E = 2;

            delta_st = obj.x_equilibrium(1);
            E_st = obj.x_equilibrium(3);
            angleV_st = angle(obj.V_equilibrium);
            absV_st = abs(obj.V_equilibrium);
            Vabscos_st = absV_st*cos(delta_st-angleV_st);
            Vabssin_st = absV_st*sin(delta_st-angleV_st);
            dv_omega_delta = E_st*Vabscos_st/Xdp - (1/Xdp-1/Xq)*(Vabscos_st^2-Vabssin_st^2);
            dv_omega_E = Vabssin_st/Xdp;
            dv_omega_angleV = -dv_omega_delta;
            dv_omega_absV = E_st*sin(delta_st-angleV_st)/Xdp - 2*(1/Xdp-1/Xq)*absV_st*sin(delta_st-angleV_st)*cos(delta_st-angleV_st);
            dv_omega = [dv_omega_delta, dv_omega_E, dv_omega_angleV, dv_omega_absV];
            dv_E = [-(Xd/Xdp-1)*Vabssin_st, 0, (Xd/Xdp-1)*Vabssin_st, (Xd/Xdp-1)*cos(delta_st-angleV_st)];
            dv_x_avr = [0,0,0,Kavr];
            sys_v = ss([-dv_omega; dv_E; -dv_x_avr]);
            sys_v.InputGroup.delta = 1;
            sys_v.InputGroup.E = 2;
            sys_v.InputGroup.angleV = 3;
            sys_v.InputGroup.absV = 4;
            sys_v.OutputGroup.v_omega = 1;
            sys_v.OutputGroup.v_E = 2;
            sys_v.OutputGroup.v_x_avr = 3;

            sys_ = blkdiag(sys_linear, sys_v);
            ig = sys_.InputGroup; og = sys_.OutputGroup;
            feedin = [ig.v_omega, ig.v_E, ig.v_x_avr, ig.delta, ig.E];
            feedout = [og.v_omega, og.v_E, og.v_x_avr, og.delta, og.E];
            sys = feedback(sys_, eye(numel(feedin)), feedin, feedout, 1);
        end
    end
end


