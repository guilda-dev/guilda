classdef generator_classical < component
    properties(Access = private)
        parameter_vec
        system_matrix
        x_st
        V_st
        I_st
    end
    
    properties(SetAccess = private)
%         parameter
%         x_equilibrium
%         V_equilibrium
%         I_equilibrium
        avr
        pss
        governor
        alpha_st
        omega0
        Vfd
    end
    
    methods
        function obj = generator_classical(omega, parameter)
            obj.omega0 = omega;
            if isstruct(parameter)
                parameter = struct2table(parameter);
            end
            obj.parameter = parameter(:, {'Xd', 'M', 'D'});
            obj.parameter_vec = obj.parameter.Variables;
            obj.avr = avr();
            obj.governor = governor();
            obj.pss = pss();
            obj.system_matrix = struct();
        end
        
        function name_tag = get_x_name(obj)
            gen_state = {'delta','omega'};
            avr_state = obj.avr.get_state_name;
            pss_state = obj.pss.get_state_name;
            governor_state = obj.governor.get_state_name;
            name_tag = horzcat(gen_state,avr_state,pss_state,governor_state);
        end

        function u_name = get_port_name(obj)
            u_name = {'Vfd','Pm'};
        end
        
        function out = get_nx(obj)
            out = 2 + obj.avr.get_nx() + obj.pss.get_nx() + obj.governor.get_nx();
        end
        
        % Vfdは定数であるため、界磁電圧に関する入力は必要ないのですが、AGCのコードで入力が１つの発電機が入ると面倒臭そうなので２つのままにしておきます
        function nu = get_nu(obj)
            nu = 2;
        end
        
        function [dx, con] = get_dx_constraint(obj, t, x, V, I, u)
            X = obj.parameter_vec(1);
            M = obj.parameter_vec(2);
            d = obj.parameter_vec(3);
            nx = 2;
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
            omega = x_gen(2); %ok
            
            % Vq = V(1)*cos(delta)+V(2)*sin(delta);
            % Vd = V(1)*sin(delta)-V(2)*cos(delta); %ok

            Efd = 0;

            [dx_pss, v] = obj.pss.get_u(x_pss, omega);
            [dx_avr, ~] = obj.avr.get_Vfd(x_avr, Vabs, Efd, u(1)-v);
            [dx_gov, P] = obj.governor.get_P(x_gov, omega, u(2));
            
            Ir =  (obj.Vfd*sin(delta) - V(2))/X;
            Ii = -(obj.Vfd*cos(delta) - V(1))/X;
            
            con = I - [Ir; Ii]; %ok
            
            ddelta = obj.omega0 * omega;
            domega = (P - d*omega - obj.Vfd*Vabs*sin(delta-Vangle)/X)/M;
            
            dx = [ddelta; domega; dx_avr; dx_pss; dx_gov]; %ok
        end
        
        % 線形の場合はとりあえず使わないので、未実装
        % コメントアウトしているのは1軸モデルのコード
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
            X = obj.parameter_vec(1);
            M = obj.parameter_vec(2);
            d = obj.parameter_vec(3);
            
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
           
            
            dIr_dd = (-dVq*sin(delta)+(obj.Vfd-Vq)*cos(delta))/X + (dVd*cos(delta)-Vd*sin(delta))/X;
            dIi_dd = (dVq*cos(delta)+(obj.Vfd-Vq)*sin(delta))/X + (dVd*sin(delta)+Vd*cos(delta))/X; %ok
            
            Ist =  [(obj.Vfd*sin(delta) - Vq*sin(delta) + Vd*cos(delta))/X;
                    (-obj.Vfd*cos(delta) + Vq*cos(delta) + Vd*sin(delta))/X]; %ok
            
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
            ret_u = ret('I', {'u_avr',  'u_avr'});
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
        
        function x_st = set_equilibrium(obj, V, I)
            Vangle = angle(V);
            Vabs =  abs(V);
            Pow = conj(I)*V;
            P = real(Pow);
            Q = imag(Pow);
            X = obj.parameter{:, 'Xd'}; %ok
            delta = Vangle + atan(P/(Q+Vabs^2/X));
            obj.Vfd = P*X/Vabs/sin(delta-Vangle);
            x_avr = obj.avr.initialize(obj.Vfd, Vabs);
            x_gov = obj.governor.initialize(P);
            x_pss = obj.pss.initialize();
            x_st = [delta; 0; x_avr; x_gov; x_pss];
            obj.alpha_st = [P; obj.Vfd; Vabs];
            obj.x_equilibrium = x_st;
            obj.V_equilibrium = V;
            obj.I_equilibrium = I;
            obj.x_st = x_st;
            obj.V_st = tools.complex2vec(V);
            obj.I_st = tools.complex2vec(I);
            obj.set_linear_matrix(x_st, tools.complex2vec(V)); %ok
        end
    end
end


