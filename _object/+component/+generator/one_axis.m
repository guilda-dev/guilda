classdef one_axis < component.generator.abstract
%モデル　: 同期発電機の１軸モデル
%　状態　: ３変数「回転子偏角"delta",周波数偏差"omega",内部電圧"Ed"」
%　　　　  * AVRやPSSが付加されるとそれらの状態も追加される
%　入力　: ２ポート「界磁入力"Vfield", 機械入力"Pmech"」
%実行方法: obj =　component.generator.one_axis(parameter)
%　引数　: parameter : table型．「'Xd', 'Xd_p','Xq','Td_p','M','D'」を列名として定義
<<<<<<< HEAD
    
    
=======

    properties(SetAccess=protected)
        GenState = {'delta','omega','Eq'};
        GenPort  = [];
    end

>>>>>>> develop/code_refactoring
    methods
        function obj = one_axis(parameter)
            arguments
                parameter = 'NGT2';
            end
            obj@component.generator.abstract(parameter)
            
            obj.parameter = obj.parameter(:, {'Xd', 'Xd_p', 'Xq', 'Td_p', 'M', 'D'});
            obj.set_avr(      component.generator.avr.base()      );
            obj.set_governor( component.generator.governor.base() );
            obj.set_pss(      component.generator.pss.base()      );
            
        end
        
        function name_tag = naming_state(obj)
            gen_state = {'delta','omega','Eq'};
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
                p = obj.parameter.Variables;
                Xd   = p(1);
                Xdp  = p(2);
                Xq   = p(3);
                Td_p = p(4);
                M    = p(5);
                d    = p(6);
<<<<<<< HEAD
    
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

            function [A, B, C, D, BV, DV, BI, DI, R, S] = get_linear_matrix(obj, x_st, Vst, Ist)
=======

                % 状態の抽出
                delta = x(1);
                omega = x(2);
                Edq   = [ 0; x(3) ];

                Vabs = norm(V);

                tensor = [ sin(delta), -cos(delta);...
                            cos(delta),  sin(delta)];

                Vdq = tensor * V;
                Idq = tensor * I;

                Efd= Edq(2) + (Xd-Xdp)*Idq(1);
                P  = V.'*I;


                % AVR,PSS,Governorの状態/入力を抽出
                    x_sub = x(4:end);
                    u_sub = u;
                    [dx_sub, Vfd, Pm] = obj.get_dx_u( x_sub,u_sub, omega, P, Vabs, Efd);

                % 微分項の計算
                    ddelta = obj.omega0 * omega;
                    domega = (- d*omega - P + Pm ) / M;
                    dEq    = (       -  Efd + Vfd) / Tdp;

                    dx = [ddelta; domega; dEq; dx_sub];

                % 制約条件の計算
                    Iri = tensor \ [     0, 1/Xdp ;...
                                     -1/Xq,     0 ] * (Edq-Vdq);
                    con = I - Iri;
            end

        % 定常潮流状態からモデルの平衡点と定常入力値を求めるメソッド
            function [x_st,u_st] = get_equilibrium(obj,V,I,flag)
                arguments
                    obj
                    V   = obj.V_equilibrium;
                    I   = obj.I_equilibrium;
                    flag = 'get';
                end

                Xd  = obj.parameter.Xd;
                Xdp = obj.parameter.Xd_p;
                Xq  = obj.parameter.Xq;

                Vangle = angle(V);
                Vabs   =  abs(V);
                Pow    = conj(I)*V;
                P      = real(Pow);
                Q      = imag(Pow);


                % 発電機の平衡点を計算
                delta  = Vangle + atan(P/(Q+Vabs^2/Xq));
                omega  = 0;
                tensor = [ sin(delta), -cos(delta);...
                            cos(delta),  sin(delta)];
                Idq = tensor * tools.complex2vec(I);
                Vdq = tensor * tools.complex2vec(V);

                Eq = Vdq(2) + Xdp*Idq(1);
                % Ed = Vdq(1) - Xqp*Idq(2);

                Vfd = Eq + (Xd-Xdp) * Idq(1);


                % 発電機のサブクラスの計算
                switch flag
                    case 'get'
                        [x_avr,u_avr] = obj.avr.get_equilibrium(Vabs,Vfd);
                        [x_gov,u_gov] = obj.governor.get_equilibrium(omega, P);
                        [x_pss,u_pss] = obj.pss.get_equilibrium(omega);

                        x_st = [delta; omega; Eq; x_avr; x_pss; x_gov];
                        u_st = [u_avr; u_pss; u_gov];

                    case 'set'
                        obj.avr.set_equilibrium(Vabs,Vfd);
                        obj.governor.set_equilibrium(omega, P);
                        obj.pss.set_equilibrium(omega);

                        x_st = [delta; omega; Eq];
                        u_st = [];
                end
            end


        % GFMIのリファレンスモデルとして実装するために必要なメソッド
            function [delta,omega,Edq] = get_Vterminal(obj,x,V,I,u)%#ok
                delta = x(1);

                %[周波数偏差]から[周波数のpu値]へ変換
                omega = x(2);

                %１軸はEdが0として近似されたモデル
                Ed = 0;
                Eq = x(3);
                Edq = [Ed; Eq];
            end


            function [A, B, C, D, BV, DV, BI, DI, R, S] = get_linear_matrix(obj, x_st, Vst, ~)
>>>>>>> develop/code_refactoring

                if nargin < 2 || isempty(x_st)
                    x_st = obj.x_equilibrium;
                end
                if nargin < 3 || isempty(Vst)
                    Vst = tools.complex2vec(obj.V_equilibrium);
                end
<<<<<<< HEAD
                omega_bar = obj.omega0;
                Xd  = obj.parameter.Xd;
                Xdp = obj.parameter.Xd_p;
                Xq  = obj.parameter.Xq;
                Tdo = obj.parameter.Td_p;
                M   = obj.parameter.M;
                d   = obj.parameter.D;
                
                A_swing = [0 obj.omega0 0;
                    0 -d/M 0;
                    0 0 0];
                % u1 = Pmech;
                % u2 = Vfd;
                % u3 = Pout
                % u4 = Vabscos
                B_swing = [0, 0, 0, 0;
                    1/M, 0, -1/M, 0;
                    0, 1/Tdo, 0, -1/Tdo
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
                InputGroup.Efd_swing = 4;
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
                dVabssin = Vabscos;
                
                dEfd = -[dVabscos, 0, dVabscos_dV] * (Xd/Xdp-1) + [0, Xd/Xdp, 0, 0];
                
                dIr_dd = (-dVabscos*sin(delta)+(E-Vabscos)*cos(delta))/Xdp + (dVabssin*cos(delta)-Vabssin*sin(delta))/Xq;
                dIi_dd = (dVabscos*cos(delta)+(E-Vabscos)*sin(delta))/Xdp + (dVabssin*sin(delta)+Vabssin*cos(delta))/Xq;
                
                Ist =  [(E-Vabscos)*sin(delta)/Xdp + Vabssin*cos(delta)/Xq;
                    -(E-Vabscos)*cos(delta)/Xdp + Vabssin*sin(delta)/Xq];
                
                % (delta, E, V) => (Ir, Ii)
                KI = [dIr_dd, sin(delta)/Xdp, dIr_dV;
                    dIi_dd, -cos(delta)/Xdp, dIi_dV];
                
                dP = Vst'*KI + Ist'*[zeros(2), eye(2)];
                
                
                sys_fb = ss([dP; dEfd; KI]);
                InputGroup = struct();
                InputGroup.delta = 1;
                InputGroup.E = 2;
                InputGroup.V = 3:4;
                sys_fb.InputGroup = InputGroup;
                OutputGroup = struct();
                OutputGroup.P = 1;
                OutputGroup.Efd = 2;
                OutputGroup.I = 3:4;
                sys_fb.OutputGroup = OutputGroup;
                
                Vabs = norm(Vst);
                
                sys_V = ss([eye(2); Vst'/Vabs]);
                sys_V.InputGroup.Vin = 1:2;
                OutputGroup = struct();
                OutputGroup.V = 1:2;
                OutputGroup.Vabs = 3;
                sys_V.OutputGroup = OutputGroup;
                
                sys_avr = obj.avr.get_sys();
                sys_pss = obj.pss.get_sys();
                sys_gov = obj.governor.get_sys();
                G = blkdiag(sys_swing, sys_fb, sys_V, sys_avr, -sys_pss, sys_gov);
                ig = G.InputGroup;
                og = G.OutputGroup;
                feedin = [ig.Pout, ig.Efd, ig.Efd_swing, ig.delta, ig.E, ig.V, ig.Vabs, ig.Vfd, ig.u_avr, ig.omega, ig.omega_governor, ig.Pmech];
                feedout = [og.P, og.Efd, og.Efd,  og.delta, og.E, og.V, og.Vabs, og.Vfd, og.v_pss, og.omega, og.omega, og.Pmech];
                I = ss(eye(numel(feedin)));
                
                ret = feedback(G, I, feedin, feedout, 1);
                ret_u = ret('I', {'u_avr',  'u_governor'});
=======

                ret = obj.get_sys(x_st, Vst);

                ret_u = ret('I', {'u_avr1',  'Pm'});
>>>>>>> develop/code_refactoring
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

<<<<<<< HEAD
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
=======
>>>>>>> develop/code_refactoring


        function [ret, sys_fb, sys_V] = get_sys(obj, x_st, Vst)

            if nargin < 2 || isempty(x_st)
                x_st = obj.x_equilibrium;
            end
            if nargin < 3 || isempty(Vst)
                Vst = tools.complex2vec(obj.V_equilibrium);
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
<<<<<<< HEAD
            
            
            sys_fb = ss([dP; dEfd; KI]);
=======

            R_I = tools.matrix_polar_transform(obj.I_equilibrium);

            sys_fb = ss([dP; dEfd; dEin; KI; R_I*KI]);
>>>>>>> develop/code_refactoring
            InputGroup = struct();
            InputGroup.delta = 1;
            InputGroup.E = 2;
            InputGroup.V = 3:4;
            sys_fb.InputGroup = InputGroup;
            OutputGroup = struct();
            OutputGroup.P = 1;
            OutputGroup.Efd = 2;
<<<<<<< HEAD
            OutputGroup.I = 3:4;
=======
            OutputGroup.Ein = 3;
            OutputGroup.I = 4:5;
            OutputGroup.I_polar = 6:7;
>>>>>>> develop/code_refactoring
            sys_fb.OutputGroup = OutputGroup;

            Vabs = norm(Vst);

            sys_V = ss([eye(2); Vst'/Vabs]);
            sys_V.InputGroup.Vin = 1:2;
            OutputGroup = struct();
            OutputGroup.V = 1:2;
            OutputGroup.Vabs = 3;
            sys_V.OutputGroup = OutputGroup;
<<<<<<< HEAD
            
            sys_avr = obj.avr.get_sys();
            sys_pss = obj.pss.get_sys();
            sys_gov = obj.governor.get_sys();
            G = blkdiag(sys_swing, sys_fb, sys_V, sys_avr, -sys_pss, sys_gov);
            ig = G.InputGroup;
            og = G.OutputGroup;
            feedin = [ig.Pout, ig.Efd, ig.Efd_swing, ig.delta, ig.E, ig.V, ig.Vabs, ig.Vfd, ig.u_avr, ig.omega, ig.omega_governor, ig.Pmech];
            feedout = [og.P, og.Efd, og.Efd,  og.delta, og.E, og.V, og.Vabs, og.Vfd, og.v_pss, og.omega, og.omega, og.Pmech];
=======

            R_V = tools.matrix_polar_transform(obj.V_equilibrium, true);
            sys_V_polar = ss([0,1; R_V]);
            sys_V_polar.InputGroup.Vin_polar = 1:2;
            sys_V_polar.OutputGroup.Vabs_p = 1;
            sys_V_polar.OutputGroup.V_p = 2:3;

            sys_avr = obj.avr.get_sys();
            sys_pss = obj.pss.get_sys();
            sys_gov = obj.governor.get_sys();

            G = blkdiag(sys_swing, sys_fb, sys_V, sys_avr, sys_pss, sys_gov, sys_V_polar);
            ig = G.InputGroup;
            og = G.OutputGroup;
            feedin = [ig.Pout, ig.Efd, ig.Ein_swing, ig.delta, ig.E, ig.V, ig.Vabs, ig.Vfd, ig.u_avr1, ig.omega, ig.omega_governor, ig.Pmech, ig.V, ig.Vabs];
            feedout = [og.P, og.Efd, og.Ein,  og.delta, og.E, og.V, og.Vabs, og.Vfd, og.v_pss, og.omega, og.omega, og.Pmech, og.V_p, og.Vabs_p];
>>>>>>> develop/code_refactoring
            I = ss(eye(numel(feedin)));

            ret = feedback(G, I, feedin, feedout, 1);
        end

        % レトロフィット制御器のために必要なメソッド
        function [sys, sys_linear, sys_v] = get_sys4retrofit(obj)
            omega0 = obj.omega0;
            Xd  = obj.parameter{:, 'Xd'};
            Xdp = obj.parameter{:, 'Xd_p'};
            Xq  = obj.parameter{:, 'Xq'};
            Tdp= obj.parameter{:, 'Td_p'};
            M   = obj.parameter{:, 'M'};
            D   = obj.parameter{:, 'D'};
            [Aavr, Bavr, Cavr, Davr] = ssdata(obj.avr.get_sys);
            Bavr_absV = Bavr(:, 1); Bavr_Efd = Bavr(:, 2); Bavr_pss = Bavr(:, 3);
            Davr_absV = Davr(:, 1); Davr_Efd = Davr(:, 2); Davr_pss = Davr(:, 3);
            n_avr = size(Aavr, 1);
            [Apss, Bpss, Cpss, Dpss] = ssdata(obj.pss.get_sys);
            n_pss = size(Apss, 1);

            % x = [delta; omega; E; x_avr; x_pss]
            A_linear = [0, omega0, zeros(1, 1+n_avr+n_pss);
                0, -D/M, zeros(1, 1+n_avr+n_pss);
                0, Davr_pss*Dpss/Tdp, (Xd/(Xdp*Tdp))*(Davr_Efd-1), Cavr/Tdp, Davr_pss*Cpss/Tdp;
                zeros(n_avr, 1), Bavr_pss*Dpss, Bavr_Efd*Xd/Xdp, Aavr, Bavr_pss*Cpss;
                zeros(n_pss, 1), Bpss, zeros(n_pss, 1+n_avr), Apss];
            % u = [u_governor; u_avr]
            Bu_linear = [0,0; 1/M, 0; 0, -Davr_pss/Tdp; 0, Bavr_pss; zeros(n_pss, 2)];
            % v = [v_omega; v_E; v_x_avr]
            Bv_linear = [zeros(1, 2+n_avr); 1/M, 0, zeros(1, n_avr); 0, 1/Tdp, zeros(1, n_avr); zeros(n_avr, 2), eye(n_avr); zeros(n_pss, 2+n_avr)];
            % w = [delta, E]
            C_linear = [1, zeros(1, 2+n_avr+n_pss); 0, 0, 1, zeros(1, n_avr+n_pss)];
            sys_linear = ss(A_linear, [Bu_linear, Bv_linear], C_linear, []);
            sys_linear.InputGroup.u_governor = 1;
            sys_linear.InputGroup.u_avr = 2;
            sys_linear.InputGroup.v_omega = 3;
            sys_linear.InputGroup.v_E = 4;
            sys_linear.InputGroup.v_x_avr = 5;
            sys_linear.OutputGroup.delta = 1;
            sys_linear.OutputGroup.E = 2;

            delta_st  =obj.x_equilibrium(1);
            E_st =obj.x_equilibrium(3);
            angleV_st = angle(obj.V_equilibrium);
            absV_st = abs(obj.V_equilibrium);
            sin_st = sin(delta_st-angleV_st);
            cos_st = cos(delta_st-angleV_st);
            dv_omega_ddelta = -(absV_st*E_st/Xdp)*cos_st + ((1/Xdp)-(1/Xq))*absV_st*absV_st*(cos_st*cos_st-sin_st*sin_st);
            dv_omega_dE = -(absV_st/Xdp)*sin_st;
            dv_omega_dangleV = -dv_omega_ddelta;
            dv_omega_dabsV = -(E_st/Xdp)*sin_st + 2*((1/Xdp)-(1/Xq))*absV_st*sin_st*cos_st;
            dv_E_ddelta = -(Xd/Xdp-1)*absV_st*sin_st + Davr_Efd*((Xd/Xdp)-1)*absV_st*sin_st;
            dv_E_dE = 0;
            dv_E_dangleV = -dv_E_ddelta;
            dv_E_dabsV = (Xd/Xdp-1)*cos_st + Davr_absV - Davr_Efd*((Xd/Xdp)-1)*cos_st;
            dv_x_avr_ddelta = Bavr_Efd*(Xd/Xdp-1)*absV_st*cos_st;
            dv_x_avr_dE = 0;
            dv_x_avr_dangleV = -dv_x_avr_ddelta;
            dv_x_avr_dabsV = Bavr_absV + Bavr_Efd*(Xd/Xdp-1)*sin_st;
            sys_v = ss([dv_omega_ddelta, dv_omega_dE, dv_omega_dangleV, dv_omega_dabsV;
                dv_E_ddelta, dv_E_dE, dv_E_dangleV, dv_E_dabsV;
                dv_x_avr_ddelta, dv_x_avr_dE, dv_x_avr_dangleV, dv_x_avr_dabsV]);
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

