classdef generator_1axis < component
% モデル  ：同期発電機の一軸モデル
%         ・状態：３つ「回転子偏角"δ",周波数偏差"Δω",内部電圧"E"」
%               *AVRやPSSが付加されるとそれらの状態も追加される
%         ・入力：２ポート「界磁入力"Vfield", 機械入力"Pmech"」
%               *定常値からの追加分を指定
% 親クラス：componentクラス
% 実行方法：obj =　generator_1axis(omega, parameter)
% 　引数　：・omega     : double値．系統周波数(50or60*2pi)
% 　　　　　・parameter : table型．「'Xd', 'Xd_prime','Xq','T','M','D'」を列名として定義
% 　出力　：componentクラスのインスタンス

    properties(Access = private)
        parameter_vec
        system_matrix
        x_st
        V_st
        I_st
    end
    
    properties(SetAccess = private)
        x_equilibrium
        V_equilibrium
        I_equilibrium
        avr
        pss
        governor
        alpha_st
        omega0
    end
    
    properties(SetAccess = public)
        parameter
    end
    
    methods
        function obj = generator_1axis(omega, parameter)
            obj.omega0 = omega;
            if isstruct(parameter)
                parameter = struct2table(parameter);
            end
            obj.parameter = parameter(:, {'Xd', 'Xd_prime', 'Xq', 'T', 'M', 'D'});
            obj.parameter_vec = obj.parameter.Variables;
            obj.avr = avr();
            obj.governor = governor();
            obj.pss = pss();
            obj.system_matrix = struct();
        end
        
        function name_tag = get_x_name(obj)
            gen_state = {'delta','omega','Ed'};
            avr_state = obj.avr.get_state_name;
            pss_state = obj.pss.get_state_name;
            governor_state = obj.governor.get_state_name;
            name_tag = horzcat(gen_state,avr_state,pss_state,governor_state);
        end

        function u_name = get_port_name(obj)
            u_name = {'Vfd','Pm'};
        end
        
        function out = get_nx(obj)
            out = 3 + obj.avr.get_nx() + obj.pss.get_nx() + obj.governor.get_nx();
        end
        
        function nu = get_nu(obj)
            nu = 2;
        end
        
        function [dx, con] = get_dx_constraint(obj, t, x, V, I, u)
            omega0 = obj.omega0; %#ok
            Xd = obj.parameter_vec(1);
            Xdp = obj.parameter_vec(2);
            Xq = obj.parameter_vec(3);
            Tdo = obj.parameter_vec(4);
            M = obj.parameter_vec(5);
            d = obj.parameter_vec(6);
            nx = 3;
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
            E = x_gen(3);
            
            Vabscos = V(1)*cos(delta)+V(2)*sin(delta);
            Vabssin = V(1)*sin(delta)-V(2)*cos(delta);
            
            Ir =  (E-Vabscos)*sin(delta)/Xdp + Vabssin*cos(delta)/Xq;
            Ii = -(E-Vabscos)*cos(delta)/Xdp + Vabssin*sin(delta)/Xq;
            
            con = I - [Ir; Ii];
            
            Efd = Xd*E/Xdp - (Xd/Xdp-1)*Vabscos;
            
            [dx_pss, v] = obj.pss.get_u(x_pss, omega);
            [dx_avr, Vfd] = obj.avr.get_Vfd(x_avr, Vabs, Efd, u(1)-v);
            [dx_gov, P] = obj.governor.get_P(x_gov, omega, u(2));
            
            
            dE = (-Efd + Vfd)/Tdo;
            ddelta = omega0 * omega; %#ok
            domega = (P - d*omega - Vabs*E*sin(delta-Vangle)/Xdp + Vabs^2*(1/Xdp-1/Xq)*sin(2*(delta-Vangle))/2)/M;
            
            dx = [ddelta; domega; dE; dx_avr; dx_pss; dx_gov];
        end
        
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
            omega_bar = obj.omega0;
            Xd = obj.parameter_vec(1);
            Xdp = obj.parameter_vec(2);
            Xq = obj.parameter_vec(3);
            Tdo = obj.parameter_vec(4);
            M = obj.parameter_vec(5);
            d = obj.parameter_vec(6);
            
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
        
        function x_st = set_equilibrium(obj, V, I)
            Vangle = angle(V);
            Vabs =  abs(V);
            Pow = conj(I)*V;
            P = real(Pow);
            Q = imag(Pow);
            Xd = obj.parameter{:, 'Xd'};
            Xdp = obj.parameter{:, 'Xd_prime'};
            Xq = obj.parameter{:, 'Xq'};
            delta = Vangle + atan(P/(Q+Vabs^2/Xq));
            Enum = Vabs^4 + Q^2*Xdp*Xq + Q*Vabs^2*Xdp + Q*Vabs^2*Xq + P^2*Xdp*Xq;
            Eden = Vabs*sqrt(P^2*Xq^2 + Q^2*Xq^2 + 2*Q*Vabs^2*Xq + Vabs^4);
            E = Enum/Eden;
            Vfd = Xd*E/Xdp - (Xd/Xdp-1)*Vabs*cos(delta-Vangle);
            x_avr = obj.avr.initialize(Vfd, Vabs);
            x_gov = obj.governor.initialize(P);
            x_pss = obj.pss.initialize();
            x_st = [delta; 0; E; x_avr; x_gov; x_pss];
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


