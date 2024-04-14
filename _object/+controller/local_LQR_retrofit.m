classdef local_LQR_retrofit <  controller
    
    properties(SetAccess=private)
        type = 'local';
        port_input = 'u_avr';
        port_observe = 'Vfield'; % delta,omega,Ed,Vfieldだが、仮で設定
    end

    properties(Access=private)
       x_avr
       x_pss
       x_gov
    end
    
    properties
        A
        Bw
        Bv
        K
        nx
        Xd
        Xdp
        x0
        V0
        I0
        u0
        sys_fb
        sys_design
        avr
        pss
        gov
        Vfd0
        Vabs0
        Efd0
        Vabscos0
        E0
        delta0
        x_avr0
    end
    
    methods
        function obj = local_LQR_retrofit(net, idx, Q, R, model, model_agc)
            obj@controller(net, idx, idx);
            if nargin < 5
                model = [];
            end
            if nargin < 6
                model_agc = [];
            end
            obj.avr = net.a_bus{idx}.component.avr;
            obj.pss = net.a_bus{idx}.component.pss;
            obj.gov = net.a_bus{idx}.component.governor;
            n_avr = obj.avr.get_nx;
            n_pss = obj.pss.get_nx;
            n_gov = obj.gov.get_nx;
            nx = 3;
            
            obj.x_avr = @(x) x(nx+(1:n_avr));
            obj.x_pss = @(x) x(nx+n_avr+(1:n_pss));
            obj.x_gov = @(x) x(nx+n_avr+n_pss+(1:n_gov));
            
            if isempty(model)
               model = ss(zeros(2, 2));
               model.InputGroup.E_m = 1;
               model.InputGroup.delta_m = 2;
               model.OutputGroup.V_m = 1:2;
            end
            
            if isempty(model_agc)
               model_agc = ss(zeros(1, 2));
               model_agc.InputGroup.omega_agc = 1;
               model_agc.InputGroup.delta_agc = 2;
               model_agc.OutputGroup.u_agc = 1;
            end
            
            sys = net.a_bus{idx}.component.get_sys();
            sys_ = sys;
            sys_cat = blkdiag(sys, model, model_agc);
            feedout = [sys_cat.OutputGroup.delta, sys_cat.OutputGroup.E, sys_cat.OutputGroup.V_m,...
                sys_cat.OutputGroup.u_agc, sys_cat.OutputGroup.omega, sys_cat.OutputGroup.delta];
            feedin = [sys_cat.InputGroup.delta_m, sys_cat.InputGroup.E_m, sys_cat.InputGroup.Vin,...
                sys_cat.InputGroup.u_governor, sys_cat.InputGroup.omega_agc, sys_cat.InputGroup.delta_agc];
            sys = feedback(sys_cat, eye(numel(feedin)), feedin, feedout, 1);
            obj.sys_design = sys;
            
            [A, B, ~, ~] = ssdata(sys(:, {'u_avr'}));
            [~, Br, ~, ~] = ssdata(sys(:, {'Pout', 'Efd_swing', 'Vabs', 'Vfd' 'u_avr',  'u_governor'}));
            [~, Bw, ~, ~] = ssdata(sys(:, {'delta', 'delta_m', 'delta_agc', 'omega_agc', 'E', 'E_m', 'Vfd'}));
            
            L = Br;
            
            obj.A = A;
            obj.Bv = L;
            obj.Bw = [sum(Bw(:, 1:3), 2), Bw(:, 4), sum(Bw(:, [5, 6]), 2), Bw(:, 7:end)];
            
            Q_ = zeros(size(A));
            Q_(1:size(Q, 1), 1:size(Q, 2)) = Q;
            if isinf(R)
                obj.K = zeros(1, size(A, 1));
            else
                obj.K = lqr(A, B(:, 1), Q_, R);
            end
            obj.nx = size(A, 1);
            obj.Xdp = net.a_bus{idx}.component.parameter{:, 'Xd_p'};
            obj.Xd = net.a_bus{idx}.component.parameter{:, 'Xd'};
            obj.x0 = net.a_bus{idx}.component.x_equilibrium;
            obj.V0 = tools.complex2vec(net.a_bus{idx}.component.V_equilibrium);
            obj.I0 = tools.complex2vec(net.a_bus{idx}.component.I_equilibrium);
            obj.u0 = net.a_bus{idx}.component.u_equilibrium;

            obj.sys_fb = ss((A-B(:, 1)*obj.K), B(:, 1), [eye(size(A)); -obj.K], 0);
            Vabs0 = norm(obj.V0);
            Xd = obj.Xd;
            Xdp = obj.Xdp;
            E0 = obj.x0(3);
            delta0 = obj.x0(1);            
            Vabscos0 = obj.V0(1)*cos(delta0) + obj.V0(2)*sin(delta0);

            Efd0 = Xd*E0/Xdp - (Xd/Xdp-1)*Vabscos0;

            [~, obj.Vfd0] = obj.avr.get_Vfd(obj.x_avr(obj.x0), Vabs0, Efd0, 0);
            obj.x_avr0 = obj.x_avr(obj.x0);
            obj.Vabs0 = Vabs0;
            obj.Efd0 = Efd0;
            obj.E0 = E0;
            obj.delta0 = delta0;
        end
        
        function nx = get_nx(obj)
            nx = obj.nx;
        end
        
        function nu = get_nu(obj)
            nu = 2;
        end
        
        function initialize(obj)
            % レトロフィット制御器導入時は解列シミュレーション不可
        end
        
        function [dx, u] = get_dx_u(obj, t, x, X, Vcell, Icell, U)
            u = zeros(2, 1);
            x1 = x(1:numel(obj.x0));
            x2 = x(numel(obj.x0)+1:end);
            u(1) = -obj.K*[(X{1}-obj.x0-x1); -x2];

            V = cell2mat(Vcell);
            I = cell2mat(Icell);

            P = I'*V - obj.I0'*obj.V0;
            Xd = obj.Xd;
            Xdp = obj.Xdp;
            E = X{1}(3);
            delta = X{1}(1);
            omega = X{1}(2);
            x_pss = obj.x_pss(X{1});
            x_avr = obj.x_avr(X{1});
            x_gov = obj.x_gov(X{1});
            
            Vabs = norm(V);
            
            Vabscos = V(1)*cos(delta)+V(2)*sin(delta);
            Efd = Xd*E/Xdp - (Xd/Xdp-1)*Vabscos;
            
            [~, v] = obj.pss.get_u(x_pss, omega);
            [~, Vfd, Vap] = obj.avr.get_Vfd(x_avr, Vabs, Efd, u(1) + U{1}(1)-v);
            [~, Pm] = obj.gov.get_P(x_gov, omega, U{1}(2));
            
            dx = obj.A*x + obj.Bv*[P-Pm; Efd-obj.Efd0; Vabs-obj.Vabs0; Vfd-obj.Vfd0; U{1}] ...
                - obj.Bw*[delta-obj.delta0; omega; E-obj.E0; Vap-obj.Vfd0];
            u = num2cell(u(:),1);

        end
    end
end
