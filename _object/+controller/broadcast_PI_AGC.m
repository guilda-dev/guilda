classdef broadcast_PI_AGC < controller
% モデル  ：AGCコントローラ
% 親クラス：controllerクラス
% 実行方法：obj =　controller.broadcast_PI_AGC(net, y_idx, u_idx, Kp, Ki)
% 　引数　：・y_idx : double配列。観測元の機器の番号
% 　　　　　・u_idx : double配列。入力先の機器の番号
% 　　　　　・　Kp  ： double値。Pゲイン(ネガティブフィードバックの場合負の値に)
% 　　　　　・　Ki  ： double値。Iゲイン(ネガティブフィードバックの場合負の値に)
% 　出力　：controllerクラスのインスタンス
    
    
    properties(SetAccess = private)
        Kp
        Ki
        default_K_input
        default_K_observe
        K_input     %並列機器の制御対象
        K_observe   %並列機器の制御対象
        port_input   = 'Pmech'
        port_observe = 'omega'
    end
    
    methods
        function obj = broadcast_PI_AGC(net, y_idx, u_idx, Kp, Ki)
            obj@controller(net, u_idx, y_idx);
            obj.Ki = Ki;
            obj.Kp = Kp;
            obj.default_K_input   = ones(numel(u_idx),1);
            obj.default_K_observe = ones(numel(u_idx),1);
            obj.initialize;
        end


        function initialize(obj)          
            % 制御値の振り分け(元々broadcast_PI_AGCに書かれていたものを並列を考慮して書き直した)
            k = obj.default_K_input(ismember(obj.default_index_input, obj.index_input));
            obj.K_input = k./sum(k);
            o = obj.default_K_observe(ismember(obj.default_index_observe, obj.index_observe));
            obj.K_observe   = o/sum(o);
        end
        
        function nx = get_nx(~)
            nx = 1;
        end
        
        function [dx, u] = get_dx_u(obj, t, x, X, V, I, u_global)
            omega = zeros(numel(X), 1);
            for i = 1:numel(X)
                idx_state_ = obj.idx_state{i};
                if ~isempty(X{i})
                    omega(i) = X{i}(idx_state_);
                end
            end
            %omega = omega(ismember(obj.default_K_observe, obj.index_observe));
            %omega = omega(obj.index_observe);
            omega_mean = obj.K_observe(:).'*omega;
            dx = omega_mean;
            
            K_ipt = obj.K_input;
            u     = obj.zero_cell;
            for i = 1:numel(obj.index_input)
                idx_comp_ = obj.index_input(i);
                idx_port_ = obj.idx_port{idx_comp_};
                u{i}(idx_port_) = K_ipt(i)*(obj.Ki*x + obj.Kp*omega_mean);
            end
        end
        
        function [dx, u] = get_dx_u_linear(obj, varargin)
            [dx, u] = obj.get_dx_u(varargin{:});
        end
        
        function [A, BX, BV, BI,  Bu, C, DX, DV, DI, Du] = get_linear_matrix(obj)
            A = 0;
            nx = tools.vcellfun(@(b) b.component.get_nx(), obj.network.a_bus(obj.index_observe));
            nu = tools.vcellfun(@(b) b.component.get_nu(), obj.network.a_bus(obj.index_observe));
            
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
            if isscalar(Kp)
                obj.Kp = Kp;
            else
                error('The number of elements in Kp must be 1.')
            end
        end
        function set_Ki(obj,Ki)
            if isscalar(Ki)
                obj.Ki = Ki;
            else
                error('The number of elements in Ki must be 1')
            end
        end
        function set_K_input(obj,K_input)
            if numel(K_input) == numel(obj.index_input)
                obj.default_K_input = K_input;
            else
                error('The number of elements in K_input must match the number of elements in index_input.')
            end
        end
        function set_K_observe(obj,K_observe)
            if numel(K_observe) == numel(obj.index_observe)
                obj.default_K_observe = K_observe;
            else
                error('The number of elements in K_input must match the number of elements in index_observe.')
            end
        end
    end
end
