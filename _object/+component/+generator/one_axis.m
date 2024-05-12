classdef one_axis < component.generator.abstract.Machine
%モデル　: 同期発電機の１軸モデル
%　状態　: ３変数「回転子偏角"delta",周波数偏差"omega",内部電圧"Ed"」
%　　　　  * AVRやPSSが付加されるとそれらの状態も追加される
%　入力　: ２ポート「界磁入力"Vfield", 機械入力"Pmech"」
%実行方法: obj =　component.generator.one_axis(parameter)
%　引数　: parameter : table型．「'Xd', 'Xd_p','Xq','Td_p','M','D'」を列名として定義
    
    properties(SetAccess=protected)
        GenState = {'delta','omega','Eq'};
        GenPort  = [];
    end

    methods
        function obj = one_axis(parameter)
            arguments
                parameter = 'NGT2';
            end
            obj@component.generator.abstract.Machine(parameter)
        end
        
        % 機器のダイナミクスを決めるメソッド
            function [dx, con] = get_dx_constraint(obj, ~, x, V, I, u)
                p = obj.parameter{:,{'Xd','Xd_p','Xq','Td_p','M','D'}};
                Xd   = p(1);    Xdp  = p(2);
                Xq   = p(3);
                Td_p = p(4);
                M    = p(5);    d    = p(6);
                
                % 状態の抽出
                delta = x(1);
                omega = x(2);
                E     = x(3);
                
                Vabs = norm(V);
                Vangle = atan2(V(2), V(1));
                
                Vabscos = V(1)*cos(delta)+V(2)*sin(delta);
                Vabssin = V(1)*sin(delta)-V(2)*cos(delta);
                
                Efd= Xd*E/Xdp - (Xd/Xdp-1)*Vabscos;
                P  = Vabs*E*sin(delta-Vangle)/Xdp - Vabs^2*(1/Xdp-1/Xq)*sin(2*(delta-Vangle))/2;
                
                
                % AVR,PSS,Governorの状態/入力を抽出
                    x_sub = x(4:end);
                    u_sub = u;
                    [dx_sub, Vfd, Pm] = obj.get_dx_u( x_sub,u_sub, omega, P, Vabs, Efd);

                % 微分項の計算
                    ddelta = obj.omega0 * omega;
                    domega = (- d*omega - P + Pm )/M;
                    dE     = (          -  Efd + Vfd)/Td_p;
                    dx = [ddelta; domega; dE; dx_sub];
                    
                % 制約条件の計算
                    Ir =  (E-Vabscos)*sin(delta)/Xdp + Vabssin*cos(delta)/Xq;
                    Ii = -(E-Vabscos)*cos(delta)/Xdp + Vabssin*sin(delta)/Xq;
                    con = I - [Ir; Ii];
            end

            function [A, B, C, D, BV, DV, BI, DI, R, S] = get_linear_matrix(obj, x_st, Vst, Ist)

                if nargin < 2 || isempty(x_st)
                    x_st = obj.x_equilibrium;
                end
                if nargin < 3 || isempty(Vst)
                    Vst = obj.V_st;
                end
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
                feedin  = [ig.Pout, ig.Efd, ig.Efd_swing,  ig.delta, ig.E, ig.V, ig.Vabs, ig.Vfd, ig.u_avr1, ig.omega, ig.omega_governor, ig.Pmech];
                feedout = [og.P   , og.Efd,       og.Efd,  og.delta, og.E, og.V, og.Vabs, og.Vfd, og.v_pss , og.omega, og.omega         , og.Pmech];
                I = ss(eye(numel(feedin)));
                
                ret = feedback(G, I, feedin, feedout, 1);
                ret_u = ret('I', {'u_avr1',  'Pm'});
                ret_V = ret('I', 'Vin');
                A = ret.a;
                B = ret_u.b;
                C = ret_u.c;
                D = ret_u.d;
                BV = ret_V.b;
                DV = ret_V.d;
                BI = zeros(size(A, 1), 2);
                DI = -eye(2);
                R = [];
                S = [];
            end

        % 定常潮流状態からモデルの平衡点と定常入力値を求めるメソッド
            function [x_st,u_st] = get_equilibrium(obj,V,I,flag)
                Vangle = angle(V);
                Vabs =  abs(V);
                Pow = conj(I)*V;
                P = real(Pow);
                Q = imag(Pow);
                Xd  = obj.parameter{:, 'Xd'};
                Xdp = obj.parameter{:, 'Xd_p'};
                Xq  = obj.parameter{:, 'Xq'};
                
                % 発電機の平衡点を計算
                Enum = Vabs^4 + Q^2*Xdp*Xq + Q*Vabs^2*Xdp + Q*Vabs^2*Xq + P^2*Xdp*Xq;
                Eden = Vabs*sqrt(P^2*Xq^2 + Q^2*Xq^2 + 2*Q*Vabs^2*Xq + Vabs^4);

                delta = Vangle + atan(P/(Q+Vabs^2/Xq));
                omega = 0;
                E = Enum/Eden;
                Vfd = Xd*E/Xdp - (Xd/Xdp-1)*Vabs*cos(delta-Vangle);

                % 発電機のサブクラスの計算
                    [x_avr,u_avr] = obj.avr.get_equilibrium(Vabs,Vfd);
                    [x_gov,u_gov] = obj.governor.get_equilibrium(omega, P);
                    [x_pss,u_pss] = obj.pss.get_equilibrium(omega);
                    
                    if nargin>3 && strcmp(flag,'set')
                        obj.avr.set_linear_matrix(x_avr,u_avr,Vabs,Vfd);
                        obj.governor.set_linear_matrix(x_gov,u_gov,omega, P);
                        obj.pss.set_linear_matrix(x_pss,u_pss,omega);
                    end
                
                x_st = [delta; omega; E; x_avr; x_pss; x_gov];
                u_st = [u_avr; u_pss; u_gov];
            end

        % GFMIのリファレンスモデルとして実装するために必要なメソッド
            function [delta,omega,Edq] = get_Vterminal(obj,x)%#ok
                delta = x(1);

                %[周波数偏差]から[周波数のpu値]へ変換
                omega = 1+x(2);

                %１軸はEdが0として近似されたモデル
                Ed = 0;
                Eq = x(3);
                Edq = [Ed; Eq];
            end

        function [ret, sys_fb, sys_V] = get_sys(obj)
 
            x_st = obj.x_equilibrium;
            Vst =  tools.complex2vec(obj.V_equilibrium);

            omega_bar = obj.omega0;
            Xd  = obj.parameter{:, 'Xd'};
            Xdp = obj.parameter{:, 'Xd_p'};
            Xq  = obj.parameter{:, 'Xq'};
            Td_p= obj.parameter{:, 'Td_p'};
            M   = obj.parameter{:, 'M'};
            D   = obj.parameter{:, 'D'};
            
            A_swing = [0 omega_bar 0;
                0 -D/M 0;
                0 0 0];
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
            dVabssin =  Vabscos;
            
            dEfd = -[dVabscos, 0, dVabscos_dV] * (Xd/Xdp-1) + [0, Xd/Xdp, 0, 0];
            
            dIr_dd = (-dVabscos*sin(delta)+(E-Vabscos)*cos(delta))/Xdp + (dVabssin*cos(delta)-Vabssin*sin(delta))/Xq;
            dIi_dd = (dVabscos*cos(delta)+(E-Vabscos)*sin(delta))/Xdp + (dVabssin*sin(delta)+Vabssin*cos(delta))/Xq;
            
            Ist =  [(E-Vabscos)*sin(delta)/Xdp + Vabssin*cos(delta)/Xq;
                -(E-Vabscos)*cos(delta)/Xdp + Vabssin*sin(delta)/Xq];
            
            % (delta, E, V) => (Ir, Ii)
            KI = [dIr_dd,  sin(delta)/Xdp, dIr_dV;
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
        end
    end
end


