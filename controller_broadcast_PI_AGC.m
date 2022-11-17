classdef controller_broadcast_PI_AGC < controller
% モデル  ：AGCコントローラ
% 親クラス：controllerクラス
% 実行方法：obj =　controller_broadcast_PI_AGC(net, y_idx, u_idx, Kp, Ki)
% 　引数　：・ net  : power_networkクラスのインスタンス。付加する対象の系統モデル
% 　　　　　・y_idx : double配列。観測元の機器の番号
% 　　　　　・u_idx : double配列。入力先の機器の番号
% 　　　　　・　Kp  ： double値。Pゲイン(ネガティブフィードバックの場合負の値に)
% 　　　　　・　Ki  ： double値。Iゲイン(ネガティブフィードバックの場合負の値に)
% 　出力　：controllerクラスのインスタンス
    
    properties(Access = private)
       net 
    end
    
    properties(SetAccess = private)
        Kp
        Ki
        K_input
        K_observe
    end
    
    methods
        function obj = controller_broadcast_PI_AGC(net, y_idx, u_idx, Kp, Ki)
            obj@controller(u_idx, y_idx);
            obj.Ki = Ki;
            obj.Kp = Kp;
            obj.K_input   = ones(numel(obj.index_input)  , 1)/numel(obj.index_input);
            obj.K_observe = ones(numel(obj.index_observe), 1)/numel(obj.index_observe);
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
            omega_mean = sum(omega.*obj.K_observe(:));
            dx = omega_mean;
            u = blkdiag(zeros(0, 1), obj.K_input(:)*(obj.Ki*x + obj.Kp*omega_mean))';
            u = u(:);
        end
        
        function [dx, u] = get_dx_u_linear(obj, varargin)
            [dx, u] = obj.get_dx_u(varargin{:});
        end
        
        function [A, BX, BV, BI,  Bu, C, DX, DV, DI, Du] = get_linear_matrix(obj)
            A = 0;
            nx = tools.vcellfun(@(b) b.component.get_nx(), obj.net.a_bus(obj.index_observe));
            nu = tools.vcellfun(@(b) b.component.get_nu(), obj.net.a_bus(obj.index_observe));
            
            BX = tools.harrayfun(@(i) [0, obj.K_observe(i), zeros(1,nx(i)-2)], 1:numel(nx));
            DX = zeros(numel(obj.K_input)*2, size(BX, 2));
            DX(2:2:end, :) = obj.K_input * BX * obj.Kp;
            
            C = zeros(numel(obj.K_input)*2, 1);
            C(2:2:end, :) = obj.K_input * obj.Ki;
            
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

        function set_Kp(obj,Kp)
            if numel(Kp)==1
                obj.Kp = Kp;
            else
                error('The number of elements in Kp must be 1.')
            end
        end
        function set_Ki(obj,Ki)
            if numel(Ki)==1
                obj.Ki = Ki;
            else
                error('The number of elements in Ki must be 1')
            end
        end
        function set_K_input(obj,K_input)
            if numel(K_input) == numel(obj.index_input)
                obj.K_input = K_input;
            else
                error('The number of elements in K_input must match the number of elements in index_input.')
            end
        end
        function set_K_observe(obj,K_observe)
            if numel(K_observe) == numel(obj.index_observe)
                obj.K_observe = K_observe;
            else
                error('The number of elements in K_input must match the number of elements in index_observe.')
            end
        end
    end
end
