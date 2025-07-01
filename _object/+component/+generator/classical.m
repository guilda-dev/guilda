classdef classical < component.generator.abstract
%モデル　: 同期発電機の古典モデル
%　状態　: ２変数「回転子偏角"delta",周波数偏差"omega"」
%　　　　  * AVRやPSSが付加されるとそれらの状態も追加される
%　入力　: １ポート「機械入力"Pmech"」
%実行方法: obj =　component.generator.classical(parameter)
%　引数　: parameter : table型．「'Xd', 'Xq','M','D'」を列名として定義

    properties
        Vfield
    end
    
    methods
        function obj = classical(parameter)
            arguments
                parameter = 'NGT2';
            end
            obj@component.generator.abstract(parameter)
            
            obj.parameter = obj.parameter(:, {'Xd', 'Xq', 'M', 'D'});
            obj.set_avr( component.generator.avr.base() );
            obj.set_governor( component.generator.governor.base() );
            obj.set_pss( component.generator.pss.base() );
            obj.system_matrix = struct();
        end
        
        function name_tag = naming_state(obj)
            gen_state = {'delta','omega'};
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
            out = 2 + obj.avr.get_nx() + obj.pss.get_nx() + obj.governor.get_nx();
        end
        
        function nu = get_nu(obj)
            nu = obj.avr.get_nu() + obj.pss.get_nu() + obj.governor.get_nu();
        end
        
        % 機器のダイナミクスを決めるメソッド
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
        % 
        % 
        % function [A, B, C, D, BV, DV, BI, DI, R, S] = get_linear_matrix(obj, x_st, Vst, Ist)
        %     if nargin < 2 || isempty(x_st)
        %         x_st = obj.x_equilibrium;
        %     end
        %     if nargin < 3 || isempty(Vst)
        %         Vst = obj.V_st;
        %     end
        %     omega_bar = obj.omega0;
        %     X = obj.parameter.Xd;
        %     Xq = obj.parameter.Xq;
        %     M  = obj.parameter.M;
        %     d  = obj.parameter.D;
        % 
        %     % x1 = delta
        %     % x2 = omega
        %     A_swing = [0 obj.omega0;
        %                0 -d/M];
        %     % u1 = Pmech
        %     % u2 = Pout
        %     B_swing = [0, 0;
        %                1/M, -1/M];
        %     % y = [delta, omega]
        %     C_swing = eye(2);
        %     sys_swing = ss(A_swing, B_swing, C_swing, 0);
        %     OutputGroup = struct();
        %     OutputGroup.delta = 1;
        %     OutputGroup.omega = 2;
        %     sys_swing.OutputGroup = OutputGroup;
        %     InputGroup = struct();
        %     InputGroup.Pmech = 1;
        %     InputGroup.Pout = 2;
        %     sys_swing.InputGroup = InputGroup;
        % 
        %     % ここから下は平衡点
        %     delta = x_st(1); %ok
        % 
        %     dVq_dV = [cos(delta), sin(delta)];
        %     dVd_dV = [sin(delta), -cos(delta)]; %ok
        %     dIr_dV = -dVq_dV*sin(delta)/X + dVd_dV*cos(delta)/X;
        %     dIi_dV =  dVq_dV*cos(delta)/X + dVd_dV*sin(delta)/X;
        % 
        %     Vq = Vst(1)*cos(delta)+Vst(2)*sin(delta);
        %     Vd = Vst(1)*sin(delta)-Vst(2)*cos(delta);
        %     dVq = -Vd;
        %     dVd = Vq; %ok
        % 
        % 
        %     dIr_dd = (-dVq*sin(delta)+(obj.Vfield-Vq)*cos(delta))/X + (dVd*cos(delta)-Vd*sin(delta))/X;
        %     dIi_dd = (dVq*cos(delta)+(obj.Vfield-Vq)*sin(delta))/X + (dVd*sin(delta)+Vd*cos(delta))/X; %ok
        % 
        %     Ist =  [(obj.Vfield*sin(delta) - Vq*sin(delta) + Vd*cos(delta))/X;
        %             (-obj.Vfield*cos(delta) + Vq*cos(delta) + Vd*sin(delta))/X]; %ok
        % 
        %     % (delta, V) => (Ir, Ii)
        %     KI = [dIr_dd, dIr_dV;
        %           dIi_dd, dIi_dV];
        % 
        %     dP = Vst'*KI + Ist'*[zeros(2,1), eye(2)]; %ok
        % 
        % 
        %     sys_fb = ss([dP; KI]);
        %     InputGroup = struct();
        %     InputGroup.delta = 1;
        %     InputGroup.V = 2:3;
        %     sys_fb.InputGroup = InputGroup;
        %     OutputGroup = struct();
        %     OutputGroup.P = 1;
        %     OutputGroup.I = 2:3;
        %     sys_fb.OutputGroup = OutputGroup;
        % 
        %     Vabs = norm(Vst); %ok
        % 
        %     sys_V = ss([eye(2); Vst'/Vabs]);
        %     sys_V.InputGroup.Vin = 1:2;
        %     OutputGroup = struct();
        %     OutputGroup.V = 1:2;
        %     OutputGroup.Vabs = 3;
        %     sys_V.OutputGroup = OutputGroup;
        % 
        %     sys_avr = obj.avr.get_sys();
        %     sys_pss = obj.pss.get_sys();
        %     sys_gov = obj.governor.get_sys();
        %     G = blkdiag(sys_swing, sys_fb, sys_V, sys_avr, -sys_pss, sys_gov);
        %     ig = G.InputGroup;
        %     og = G.OutputGroup;
        %     feedin = [ig.Pout, ig.delta, ig.V, ig.omega_governor, ig.Pmech];
        %     feedout = [og.P, og.delta, og.V, og.omega, og.Pmech];
        %     I = ss(eye(numel(feedin))); %ok
        % 
        %     ret = feedback(G, I, feedin, feedout, 1);
        %     ret_u = ret('I', {'u_avr',  'u_governor'});
        %     ret_V = ret('I', 'Vin');
        %     A = ret.a;
        %     B = ret_u.b;
        %     C = ret_u.c;
        %     D = ret_u.d;
        %     BV = ret_V.b;
        %     DV = ret_V.d;
        %     BI = zeros(size(A, 1), 2);
        %     DI = -eye(2);
        %     R = [];
        %     S = [];
        % end

        % 定常潮流状態からモデルの平衡点と定常入力値を求めるメソッド
            function [x_st,u_st] = get_equilibrium(obj, V, I)
                p = obj.parameter;
    
                Vangle = angle(V);
                Vabs =  abs(V);
                Pow = conj(I)*V;
                P = real(Pow);
                Q = imag(Pow);
    
                delta = Vangle + atan(P/(Q+Vabs^2/p.Xq));
    
                Id = real(  1j*I*exp(-1j*delta) );
                Vq = imag(  1j*V*exp(-1j*delta) );
                Vfd = Id*p.Xd+Vq;
                [x_avr,u_avr] = obj.avr.initialize(Vfd, Vabs);
                [x_gov,u_gov] = obj.governor.initialize(P);
                [x_pss,u_pss] = obj.pss.initialize();
    
                obj.Vfield = Vfd;
                x_st = [delta; 0; x_avr; x_gov; x_pss];
                u_st = [u_avr;u_pss;u_gov];
            end

        % GFMIのリファレンスモデルとして実装するために必要なメソッド
            function [delta,omega,Vdq] = get_Vterminal(obj,x,V,I,u)%#ok
                delta  = x(1);
                domega = x(2);
                omega  = domega + 1;

                nx_avr = obj.avr.get_nx();
                nx_pss = obj.pss.get_nx();
                x_avr = x(2+(1:nx_avr));
                x_pss = x(2+nx_avr+(1:nx_pss));

                [~,  v ] = obj.pss.get_u(x_pss, domega);
                [~, Vfd] = obj.avr.get_Vfd(x_avr, norm(V), 0, u(1)-v);

                Vdq = [0;Vfd];
            end
    end
end


