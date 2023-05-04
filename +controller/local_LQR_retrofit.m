classdef local_LQR_retrofit <  base_class.controller
    
    properties(Access=private)
       x_avr
       x_pss
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
        sys_fb
        sys_design
        avr
        pss
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
            obj@base_class.controller(idx, idx);
            if nargin < 5
                model = [];
            end
            if nargin < 6
                model_agc = [];
            end
            obj.avr = net.a_bus{idx}.component.avr;
            obj.pss = net.a_bus{idx}.component.pss;
            n_avr = obj.avr.get_nx;
            n_pss = obj.pss.get_nx;
            nx = 3;
            
            obj.x_avr = @(x) x(nx+(1:n_avr));
            obj.x_pss = @(x) x(nx+n_avr+(1:n_pss));
            
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
            
            [A, B, C, D] = ssdata(sys('I', {'u_avr'}));
            [~, N, ~, M] = ssdata(sys('I', {'Vin'}));
            [~, Br, ~, Dr] = ssdata(sys('I', {'Pout', 'Efd_swing', 'Vabs', 'Vfd' 'u_avr',  'u_governor'}));
            [~, Bw, ~, Dw] = ssdata(sys('I', {'delta', 'delta_m', 'delta_agc', 'omega_agc', 'E', 'E_m', 'Vfd'}));
            
            L = Br;
            
            obj.A = A;
            obj.Bv = L;
            obj.Bw = [sum(Bw(:, [1:3]), 2), Bw(:, 4), sum(Bw(:, [5, 6]), 2), Bw(:, 7:end)];
            
            Q_ = zeros(size(A));
            Q_(1:size(Q, 1), 1:size(Q, 2)) = Q;
            if isinf(R)
                obj.K = zeros(1, size(A, 1));
            else
                obj.K = lqr(A, B(:, 1), Q_, R);
            end
            obj.nx = size(A, 1);
            obj.Xdp = net.a_bus{idx}.component.parameter{:, 'Xd_prime'};
            obj.Xd = net.a_bus{idx}.component.parameter{:, 'Xd'};
            obj.x0 = net.a_bus{idx}.component.x_equilibrium;
            obj.V0 = tools.complex2vec(net.a_bus{idx}.component.V_equilibrium);
            obj.I0 = tools.complex2vec(net.a_bus{idx}.component.I_equilibrium);
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
        
        
        function [dx, u] = get_dx_u(obj, t, x, X, V, I, U)
            u = zeros(2, 1);
            x1 = x(1:numel(obj.x0));
            x2 = x(numel(obj.x0)+1:end);
            u(1) = -obj.K*[(X{1}-obj.x0-x1); -x2];
            
            P = I'*V - obj.I0'*obj.V0;
            Xd = obj.Xd;
            Xdp = obj.Xdp;
            E = X{1}(3);
            delta = X{1}(1);
            omega = X{1}(2);
            x_pss = obj.x_pss(X{1});
            x_avr = obj.x_avr(X{1});
            
            Vabs = norm(V);
            
            Vabscos = V(1)*cos(delta)+V(2)*sin(delta);
            Efd = Xd*E/Xdp - (Xd/Xdp-1)*Vabscos;
            
            [~, v] = obj.pss.get_u(x_pss, omega);
            [~, Vfd, Vap] = obj.avr.get_Vfd(x_avr, Vabs, Efd, u(1) + U{1}(1)-v);
            
            dx = obj.A*x + obj.Bv*[P; Efd-obj.Efd0; Vabs-obj.Vabs0; Vfd-obj.Vfd0; U{1}] ...
                - obj.Bw*[delta-obj.delta0; omega; E-obj.E0; Vap-obj.Vfd0];
        end
    end
end
