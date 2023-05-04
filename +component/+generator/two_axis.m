classdef two_axis < base_class.component % 状態・パラメーターはqを先においている
    properties(Access = private)
        parameter_vec
        system_matrix
        x_st
        V_st
        I_st
    end
    
    properties(SetAccess = private)
        avr
        pss
        governor
        alpha_st
        omega0
    end
    
    methods
        function obj = two_axis(parameter)
            if isstruct(parameter)
                parameter = struct2table(parameter);
            end
            % 2軸用のパラメータ名に変更
            obj.parameter = parameter(:, {'Xq', 'Xq_prime', 'Xd', 'Xd_prime', 'Tdo', 'Tqo', 'M', 'D'});   % ソートしてるだけ
            obj.parameter_vec = obj.parameter.Variables;
            obj.avr = component.generator.avr.base();
            obj.governor = component.generator.governor.base();
            obj.pss = component.generator.pss.base();
            obj.system_matrix = struct();
        end
        
        function name_tag = naming_state(obj)
            gen_state = {'delta','omega','Ed','Eq'};
            avr_state = obj.avr.get_state_name;
            pss_state = obj.pss.get_state_name;
            governor_state = obj.governor.get_state_name;
            name_tag = horzcat(gen_state,avr_state,pss_state,governor_state);
        end

        function u_name = naming_port(obj)
            u_name = {'Vfd','Pm'};
        end
        
        function out = get_nx(obj)
            % 右辺の第１項を３から４に変更
            out = 4 + obj.avr.get_nx() + obj.pss.get_nx() + obj.governor.get_nx();
        end
        
        function nu = get_nu(obj)
            nu = 2;
        end
        
        function [dx, con] = get_dx_constraint(obj, t, x, V, I, u)
            % このx,V,Iは平衡状態ではなく、その時刻における値
            omega0 = obj.omega0;
            % パラメータを追加
            Xq = obj.parameter_vec(1);
            Xqp = obj.parameter_vec(2);
            Xd = obj.parameter_vec(3);
            Xdp = obj.parameter_vec(4);
            Tdo = obj.parameter_vec(5);
            Tqo = obj.parameter_vec(6);
            M = obj.parameter_vec(7);
            d = obj.parameter_vec(8);
            % nxの値を３から４に変更
            nx = 4;
            nx_avr = obj.avr.get_nx();
            nx_pss = obj.pss.get_nx();
            nx_gov = obj.governor.get_nx();
            
            x_gen = x(1:nx);
            x_avr = x(nx+(1:nx_avr));
            x_pss = x(nx+nx_avr+(1:nx_pss));
            x_gov = x(nx+nx_avr+nx_pss+(1:nx_gov));
            
            Vabs = norm(V);
            Vangle = atan2(V(2), V(1));
            
            delta = x_gen(1);
            omega = x_gen(2);
            Eq = x_gen(3);
            Ed = x_gen(4);
            
            % Vd, Vqを定義
            Vq = V(1)*cos(delta)+V(2)*sin(delta);
            Vd = V(1)*sin(delta)-V(2)*cos(delta);

            % Id, Iqを定義
            Iq = -(Ed-Vd)/Xqp;
            Id = (Eq-Vq)/Xdp;
            
            % |I|cosI, |I|sinIを逆算
            Ir = Iq*cos(delta)+Id*sin(delta);
            Ii = Iq*sin(delta)-Id*cos(delta);
            
            con = I - [Ir; Ii];
            
            % Efdの修正とEfqの追加
            Efd = Xd*Eq/Xdp - (Xd/Xdp-1)*Vq;
            Efq = Xq*Ed/Xqp - (Xq/Xqp-1)*Vd;
            
            [dx_pss, v] = obj.pss.get_u(x_pss, omega);
            [dx_avr, Vfd] = obj.avr.get_Vfd(x_avr, Vabs, Efd, u(1)-v);
            [dx_gov, P] = obj.governor.get_P(x_gov, omega, u(2));
            
            % dEをdEqに，dEdの追加
            dEq = (-Efd + Vfd)/Tdo;
            dEd = (-Efq)/Tqo;
            ddelta = omega0 * omega; 
            % PはPmechを指す
            domega = (P - d*omega - Vq*Iq - Vd*Id)/M;
            
            % ここで，dEqとdEdの順序を逆にする必要があるかも
            dx = [ddelta; domega; dEq; dEd; dx_avr; dx_pss; dx_gov];
        end %ok
        
        % ここで，obj.system_matrixをこのまま使って良いかわからない
        function [dx, con] = get_dx_constraint_linear(obj, t, x, V, I, u)
            A  = obj.system_matrix.A;
            B  = obj.system_matrix.B;
            C  = obj.system_matrix.C;
            D  = obj.system_matrix.D;
            BV = obj.system_matrix.BV;
            DV = obj.system_matrix.DV;
            BI = obj.system_matrix.BI;
            DI = obj.system_matrix.DI;
            dx = A*(x-obj.x_st) + B*u + BV*(V-obj.V_st) + BI*(I-obj.I_st);
            con = C*(x-obj.x_st) + D*u + DV*(V-obj.V_st) + DI*(I-obj.I_st);
        end
        
        function [A, B, C, D, BV, DV, BI, DI, R, S] = get_linear_matrix(obj, x_st, Vst)
            if nargin < 2 || (isempty(x_st) && isempty(Vst))
                A  = obj.system_matrix.A;
                B  = obj.system_matrix.B;
                C  = obj.system_matrix.C;
                D  = obj.system_matrix.D;
                BV = obj.system_matrix.BV;
                DV = obj.system_matrix.DV;
                BI = obj.system_matrix.BI;
                DI = obj.system_matrix.DI;
                R = obj.system_matrix.R;
                S = obj.system_matrix.S;
                return;
            end
            if nargin < 2 || isempty(x_st)
                x_st = obj.x_st;
            end
            if nargin < 3 || isempty(Vst)
                Vst = obj.V_st;
            end
            omega0 = obj.omega0;
            % パラメータを追加
            Xq = obj.parameter_vec(1);
            Xqp = obj.parameter_vec(2);
            Xd = obj.parameter_vec(3);
            Xdp = obj.parameter_vec(4);
            Tdo = obj.parameter_vec(5);
            Tqo = obj.parameter_vec(6);
            M = obj.parameter_vec(7);
            d = obj.parameter_vec(8);
            
            % 表記を変更：Vabscos -> Vq, Vabssin -> Vd

            % 動揺方程式の状態変数を４つに変更
            % x1 = delta
            % x2 = omega
            % x3 = Eq
            % x4 = Ed
            A_swing = [0 omega0 0 0;
                0 -d/M 0 0;
                0 0 0 0;
                0 0 0 0];
            % u1 = Pmech
            % u2 = Vfd
            % u3 = Pout
            % u4 = Efd
            % u5 = Efq
            B_swing = [0, 0, 0, 0, 0;
                1/M, 0, -1/M, 0, 0;
                0, 1/Tdo, 0, -1/Tdo, 0;
                0, 0, 0, 0, -1/Tqo
                ];
            % y = [delta, omega, Eq, Ed]
            C_swing = eye(4);
            sys_swing = ss(A_swing, B_swing, C_swing, 0);
            OutputGroup = struct();
            OutputGroup.delta = 1;
            OutputGroup.omega = 2;
            OutputGroup.Eq = 3;
            OutputGroup.Ed = 4;
            sys_swing.OutputGroup = OutputGroup;
            InputGroup = struct();
            InputGroup.Pmech = 1;
            InputGroup.Vfd = 2;
            InputGroup.Pout = 3;
            InputGroup.Efd_swing = 4;
            InputGroup.Efq_swing = 5;
            sys_swing.InputGroup = InputGroup;
            
            % テイラー展開を用いるので，ここからは平衡状態
            delta = x_st(1);
            Eq = x_st(3);
            Ed = x_st(4);
            
            dVq_dV = [cos(delta), sin(delta)];
            dVd_dV = [sin(delta), -cos(delta)]; %ok
            dIr_dV = -dVq_dV*sin(delta)/Xdp + dVd_dV*cos(delta)/Xqp;
            dIi_dV =  dVq_dV*cos(delta)/Xdp + dVd_dV*sin(delta)/Xqp;
            
            Vq = Vst(1)*cos(delta)+Vst(2)*sin(delta);
            Vd = Vst(1)*sin(delta)-Vst(2)*cos(delta);
            % d/ddelta
            dVq_dd = -Vd;
            dVd_dd = Vq; %ok
            
            % d/dxV => [d/ddelta, d/dEq, d/dEd, d/dVr, d/dVi]
            dEfd_dxV = -[dVq_dd, 0, 0, dVq_dV] * (Xd/Xdp-1) + [0, Xd/Xdp, 0, 0, 0];
            dEfq_dxV = -[dVd_dd, 0, 0, dVd_dV] * (Xq/Xqp-1) + [0, 0, Xq/Xqp, 0, 0]; %ok
            
            dIr_dd = (-dVq_dd*sin(delta)+(Eq-Vq)*cos(delta))/Xdp + (dVd_dd*cos(delta)-(Vd-Ed)*sin(delta))/Xqp;
            dIi_dd = (dVq_dd*cos(delta)+(Eq-Vq)*sin(delta))/Xdp + (dVd_dd*sin(delta)+(Vd-Ed)*cos(delta))/Xqp; %ok
            
            Ist =  [(Eq-Vq)*sin(delta)/Xdp + (Vd-Ed)*cos(delta)/Xqp;
                    (Vq-Eq)*cos(delta)/Xdp + (Vd-Ed)*sin(delta)/Xqp]; %ok
            
            % (delta, Eq, Ed, V) => (Ir, Ii)
            KI = [dIr_dd, sin(delta)/Xdp, -cos(delta)/Xqp, dIr_dV;
                  dIi_dd, -cos(delta)/Xdp, -sin(delta)/Xqp, dIi_dV]; %ok
            
            dP = Vst'*KI + Ist'*[zeros(2,3), eye(2)]; %ok
            % ここまで平衡状態
            
            sys_fb = ss([dP; dEfd_dxV; dEfq_dxV; KI]);
            InputGroup = struct();
            InputGroup.delta = 1;
            InputGroup.Eq = 2;
            InputGroup.Ed = 3;
            InputGroup.V = 4:5;
            sys_fb.InputGroup = InputGroup;
            OutputGroup = struct();
            OutputGroup.P = 1;
            OutputGroup.Efd = 2;
            OutputGroup.Efq = 3;
            OutputGroup.I = 4:5;
            sys_fb.OutputGroup = OutputGroup; %ok
            
            % これも平衡点
            Vabs = norm(Vst);
            
            sys_V = ss([eye(2); Vst'/Vabs]);
            sys_V.InputGroup.Vin = 1:2;
            OutputGroup = struct();
            OutputGroup.V = 1:2;
            OutputGroup.Vabs = 3;
            sys_V.OutputGroup = OutputGroup; %ok
            
            sys_avr = obj.avr.get_sys(); %avrのシステムを取得
            sys_pss = obj.pss.get_sys(); %pssのシステムを取得
            sys_gov = obj.governor.get_sys(); %governorのシステムを取得
            G = blkdiag(sys_swing, sys_fb, sys_V, sys_avr, -sys_pss, sys_gov);
            ig = G.InputGroup;
            og = G.OutputGroup;
            % Efqを追加、Eq,Edに変更、ig.Vinとog.Vをつなげた
            feedin = [ig.Pout, ig.Efd, ig.Efd_swing, ig.Efq_swing, ig.delta, ig.Eq, ig.Ed, ig.V, ig.Vabs, ig.Vfd, ig.u_avr, ig.omega, ig.omega_governor, ig.Pmech];
            feedout = [og.P, og.Efd, og.Efd, og.Efq, og.delta, og.Eq, og.Ed, og.V, og.Vabs, og.Vfd, og.v_pss, og.omega, og.omega, og.Pmech];
            I = ss(eye(numel(feedin)));
            
            ret = feedback(G, I, feedin, feedout, 1);

            % ここから先はよくわかっていない
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
        end
        
        function set_avr(obj, avr)
            if isa(avr, 'avr')
                obj.avr = avr;
            else
               error(''); 
            end
        end
        
        function set_pss(obj, pss)
            if isa(pss, 'pss')
                obj.pss = pss;
            else
                error('');
            end
        end

        function set_governor(obj, governor)
            if isa(governor, 'governor')
                obj.governor = governor;
            else
                error('');
            end
        end
        
        function initialize_net(obj)
            if ~isempty(obj.net)
                obj.net.initialize(false);
            end
        end
        
        function set_linear_matrix(obj, varargin)
            if isempty(obj.omega0)
                return
            end
            mat = struct();
            [mat.A, mat.B, mat.C, mat.D, mat.BV, mat.DV, mat.BI, mat.DI, mat.R, mat.S] = obj.get_linear_matrix(varargin{:});
            obj.system_matrix = mat;
        end
        
        % 潮流計算結果から逆算して平衡点を算出
        function x_st = set_equilibrium(obj, V, I)
            Vangle = angle(V);
            Vabs = abs(V);
            Iangle = angle(I);
            Iabs = abs(I);
            Pow = conj(I)*V;
            P = real(Pow);
            Q = imag(Pow);
            Xd = obj.parameter{:, 'Xd'};
            Xdp = obj.parameter{:, 'Xd_prime'};
            Xq = obj.parameter{:, 'Xq'};
            Xqp = obj.parameter{:, 'Xq_prime'};
            delta = Vangle + atan(P/(Q+Vabs^2/Xq));
            Eqnum = P^2*Xdp*Xq + Q^2*Xdp*Xq + Vabs^2*Q*Xq + Vabs^2*Q*Xdp + Vabs^4;
            Eqden = Vabs*sqrt(P^2*Xq^2 + Q^2*Xq^2 + 2*Vabs^2*Q*Xq + Vabs^4);
            Eq = Eqnum/Eqden;
            Ednum = (Xq-Xqp)*Vabs*P;
            Edden = sqrt(P^2*Xq^2 + Q^2*Xq^2 + 2*Vabs^2*Q*Xq +Vabs^4);
            Ed = Ednum/Edden;
            Vfd = Eq + (Xd-Xdp)*Iabs*sin(delta-Iangle);

            x_avr = obj.avr.initialize(Vfd, Vabs);
            x_gov = obj.governor.initialize(P);
            x_pss = obj.pss.initialize();
            x_st = [delta; 0; Eq; Ed; x_avr; x_gov; x_pss];
            obj.alpha_st = [P; Vfd; Vabs];
            obj.x_equilibrium = x_st;
            obj.V_equilibrium = V;
            obj.I_equilibrium = I;
            obj.x_st = x_st;
            obj.V_st = tools.complex2vec(V);
            obj.I_st = tools.complex2vec(I);
            obj.set_linear_matrix(x_st, tools.complex2vec(V));
        end
    end
end


