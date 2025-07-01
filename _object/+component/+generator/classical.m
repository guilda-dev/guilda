classdef classical < component.generator.abstract.Machine
%モデル　: 同期発電機の古典モデル
%　状態　: ２変数「回転子偏角"delta",周波数偏差"omega"」
%　　　　  * AVRやPSSが付加されるとそれらの状態も追加される
%　入力　: １ポート「機械入力"Pmech"」
%実行方法: obj =　component.generator.classical(parameter)
%　引数　: parameter : table型．「'Xd', 'Xq','M','D'」を列名として定義

    properties(SetAccess=protected)
        GenState = {'delta','omega'};
        GenPort  = [];
    end
    
    methods
        function obj = classical(parameter)
            arguments
                parameter = 'NGT2';
            end
            obj@component.generator.abstract.Machine(parameter)
        end
        
        % 機器のダイナミクスを決めるメソッド
            function [dx, con] = get_dx_constraint(obj, ~, x, V, I, u)
                p = obj.parameter{:,{'Xd','Xq','M','D'}};
                Xd   = p(1);
                Xq   = p(2);
                M    = p(3);
                d    = p(4);
                
                % 状態の抽出
                delta = x(1);
                omega = x(2);
                
                Vabs = norm(V);

                Efd= 0;
                P  = V.'*I;

                
                % AVR,PSS,Governorの状態/入力を抽出
                    x_sub = x(3:end);
                    u_sub = u;
                    [dx_sub, Vfd, Pm] = obj.get_dx_u( x_sub,u_sub, omega, P, Vabs, Efd);

                    Edq = [0;Vfd];

                % Idq,Vdqの導出
                    tensor = [ sin(delta), -cos(delta);...
                               cos(delta),  sin(delta)];

                    Vdq = tensor * V;

                % 微分項の計算
                    ddelta = obj.omega0 * omega;
                    domega = (- d*omega - P + Pm ) / M;

                    dx = [ddelta; domega; dx_sub];
                    
                % 制約条件の計算
                    Iri = tensor \ [     0, 1/Xd ;...
                                     -1/Xq,    0 ] * (Edq-Vdq);
                    con = I - Iri;
            end

        % 定常潮流状態からモデルの平衡点と定常入力値を求めるメソッド
            function [x_st,u_st] = get_equilibrium(obj, V, I,flag)
                arguments
                    obj 
                    V   = obj.V_equilibrium;
                    I   = obj.I_equilibrium;
                    flag = 'get';
                end
                p = obj.parameter;
    
                Vangle = angle(V);
                Vabs =  abs(V);
                Pow = conj(I)*V;
                P = real(Pow);
                Q = imag(Pow);
    
                delta = Vangle + atan(P/(Q+Vabs^2/p.Xq));
                omega = 0;
    
                Id = real(  1j*I*exp(-1j*delta) );
                Vq = imag(  1j*V*exp(-1j*delta) );
                Vfd = Id*p.Xd+Vq;


                % 発電機のサブクラスの計算
                switch flag
                    case 'get'
                        [x_avr,u_avr] = obj.avr.get_equilibrium(Vabs,Vfd);
                        [x_gov,u_gov] = obj.governor.get_equilibrium(omega, P);
                        [x_pss,u_pss] = obj.pss.get_equilibrium(omega);
        
                        x_st = [delta; omega; x_avr; x_pss; x_gov];
                        u_st = [u_avr; u_pss; u_gov];

                    case 'set'
                        obj.avr.set_equilibrium(Vabs,Vfd);
                        obj.governor.set_equilibrium(omega, P);
                        obj.pss.set_equilibrium(omega);

                        x_st = [delta; omega];
                        u_st = [];
                end
            end

        % GFMIのリファレンスモデルとして実装するために必要なメソッド
            function [delta,omega,Edq] = get_Vterminal(obj,x,V,I,u)%#ok
                delta = x(1);

                %[周波数偏差]から[周波数のpu値]へ変換
                omega = x(2);

                %古典はEq=Vfdとして近似されたモデル
                Ed = 0;
                Vfd = u(1);
                Edq = [Ed; Vfd];
            end


    end
end

%{

削除済みのメソッド

        function [dx, con] = get_dx_constraint(obj, t, x, V, I, u)%#ok
            % Vfdは定数であるため、界磁電圧に関する入力は必要ないのですが、AGCのコードで入力が１つの発電機が入ると面倒臭そうなので２つのままにしておきます
            p = obj.parameter;
            nx_avr = obj.avr.get_nx();
            nx_pss = obj.pss.get_nx();
            nx_gov = obj.governor.get_nx();
            
            x_gen = x(1:2);
            x_avr = x(2+(1:nx_avr));
            x_pss = x(2+nx_avr+(1:nx_pss));
            x_gov = x(2+nx_avr+nx_pss+(1:nx_gov));
            
            Vabs = norm(V);
            %Vangle = atan2(V(2), V(1));
            
            delta = x_gen(1);
            omega = x_gen(2);
            
            Efd = 0;

            [dx_pss, v] = obj.pss.get_u(x_pss, omega);
            [dx_avr, Vfd] = obj.avr.get_Vfd(x_avr, Vabs, Efd, u(1)-v);
            [dx_gov, P] = obj.governor.get_P(x_gov, omega, u(2));

            Vd  = V(1)*sin(delta)-V(2)*cos(delta);
            Vq  = V(1)*cos(delta)+V(2)*sin(delta);
            Id  = (Vfd-Vq)/p.Xd;...
            Iq  = Vd/p.Xq;

            Ir  =   Id*sin(delta) + Iq*cos(delta);
            Ii  = - Id*cos(delta) + Iq*sin(delta);

            ddelta = obj.omega0 * omega;
            domega = ( P - p.D*omega - Vq*Iq - Vd*Id )/p.M;

            con = I - [Ir;Ii];
            dx = [ddelta; domega; dx_avr; dx_pss; dx_gov];
        end

        function [A, B, C, D, BV, DV, BI, DI, R, S] = get_linear_matrix(obj, x_st, Vst, Ist)
            if nargin < 2 || isempty(x_st)
                x_st = obj.x_equilibrium;
            end
            if nargin < 3 || isempty(Vst)
                Vst = obj.V_st;
            end
            omega_bar = obj.omega0;
            X = obj.parameter.Xd;
            Xq = obj.parameter.Xq;
            M  = obj.parameter.M;
            d  = obj.parameter.D;

            % x1 = delta
            % x2 = omega
            A_swing = [0 obj.omega0;
                       0 -d/M];
            % u1 = Pmech
            % u2 = Pout
            B_swing = [0, 0;
                       1/M, -1/M];
            % y = [delta, omega]
            C_swing = eye(2);
            sys_swing = ss(A_swing, B_swing, C_swing, 0);
            OutputGroup = struct();
            OutputGroup.delta = 1;
            OutputGroup.omega = 2;
            sys_swing.OutputGroup = OutputGroup;
            InputGroup = struct();
            InputGroup.Pmech = 1;
            InputGroup.Pout = 2;
            sys_swing.InputGroup = InputGroup;

            % ここから下は平衡点
            delta = x_st(1); %ok

            dVq_dV = [cos(delta), sin(delta)];
            dVd_dV = [sin(delta), -cos(delta)]; %ok
            dIr_dV = -dVq_dV*sin(delta)/X + dVd_dV*cos(delta)/X;
            dIi_dV =  dVq_dV*cos(delta)/X + dVd_dV*sin(delta)/X;

            Vq = Vst(1)*cos(delta)+Vst(2)*sin(delta);
            Vd = Vst(1)*sin(delta)-Vst(2)*cos(delta);
            dVq = -Vd;
            dVd = Vq; %ok


            dIr_dd = (-dVq*sin(delta)+(obj.Vfield-Vq)*cos(delta))/X + (dVd*cos(delta)-Vd*sin(delta))/X;
            dIi_dd = (dVq*cos(delta)+(obj.Vfield-Vq)*sin(delta))/X + (dVd*sin(delta)+Vd*cos(delta))/X; %ok

            Ist =  [(obj.Vfield*sin(delta) - Vq*sin(delta) + Vd*cos(delta))/X;
                    (-obj.Vfield*cos(delta) + Vq*cos(delta) + Vd*sin(delta))/X]; %ok

            % (delta, V) => (Ir, Ii)
            KI = [dIr_dd, dIr_dV;
                  dIi_dd, dIi_dV];

            dP = Vst'*KI + Ist'*[zeros(2,1), eye(2)]; %ok


            sys_fb = ss([dP; KI]);
            InputGroup = struct();
            InputGroup.delta = 1;
            InputGroup.V = 2:3;
            sys_fb.InputGroup = InputGroup;
            OutputGroup = struct();
            OutputGroup.P = 1;
            OutputGroup.I = 2:3;
            sys_fb.OutputGroup = OutputGroup;

            Vabs = norm(Vst); %ok

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
            feedin = [ig.Pout, ig.delta, ig.V, ig.omega_governor, ig.Pmech];
            feedout = [og.P, og.delta, og.V, og.omega, og.Pmech];
            I = ss(eye(numel(feedin))); %ok

            ret = feedback(G, I, feedin, feedout, 1);
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
            R = [];
            S = [];
        end
%}

