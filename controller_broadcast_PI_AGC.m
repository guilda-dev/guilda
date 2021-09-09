classdef controller_broadcast_PI_AGC < controller
    
    properties(Access = private)
       net 
    end
    
    properties
        Kp
        Ki
        K_broadcast
    end
    
    methods
        function obj = controller_broadcast_PI_AGC(net, y_idx, u_idx, Kp, Ki)
            obj@controller(u_idx, y_idx);
            obj.Ki = Ki;
            obj.Kp = Kp;
            obj.K_broadcast = ones(numel(obj.index_input), 1);
            obj.net = net;
        end
        
        function nx = get_nx(obj)
            nx = 1;
        end
        
        function [dx, u] = get_dx_u(obj, t, x, X, V, I, u_global)
            omega = zeros(numel(X), 1);
            for i = 1:numel(X)
                omega(i) = X{i}(2);
            end
            omega_mean = mean(omega);
            dx = omega_mean;
            u = blkdiag(zeros(0, 1), obj.K_broadcast*(obj.Ki*x + obj.Kp*omega_mean))';
            u = u(:);
        end
        
        function [dx, u] = get_dx_u_linear(obj, varargin)
            [dx, u] = obj.get_dx_u(varargin{:});
        end
        
        function [A, BX, BV, BI,  Bu, C, DX, DV, DI, Du] = get_linear_matrix(obj)
            A = 0;
            nx = tools.vcellfun(@(b) b.component.get_nx(), obj.net.a_bus(obj.index_observe));
            nu = tools.vcellfun(@(b) b.component.get_nu(), obj.net.a_bus(obj.index_observe));
            
            BX = tools.harrayfun(@(n) [0, 1, zeros(1, n-2)], nx)/numel(nx);
            DX = zeros(numel(obj.K_broadcast)*2, size(BX, 2));
            DX(2:2:end, :) = obj.K_broadcast * BX * obj.Kp;
            
            C = zeros(numel(obj.K_broadcast)*2, 1);
            C(2:2:end, :) = obj.K_broadcast * obj.Ki;
            
            BV = zeros(1, 2*numel(obj.index_observe));
            BI = zeros(1, 2*numel(obj.index_observe));
            DV = zeros(size(C, 1), 2*numel(obj.index_observe));
            DI = zeros(size(C, 1), 2*numel(obj.index_observe));
            
            Bu = zeros(1, sum(nu));
            Du = zeros(size(C, 1), sum(nu));
        end
        
        function out = get_signals(obj, X, V)
            out = [];
        end
    end
end

