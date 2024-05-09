classdef broadcast_PI_AGC < controller
% モデル  ：AGCコントローラ
% 親クラス：controllerクラス
% 実行方法：obj =　controller.broadcast_PI_AGC(net, y_idx, u_idx, Kp, Ki)
% 　引数　：・y_idx : double配列。観測元の機器の番号
% 　　　　　・u_idx : double配列。入力先の機器の番号
% 　　　　　・　Kp  ： double値。Pゲイン(ネガティブフィードバックの場合負の値に)
% 　　　　　・　Ki  ： double値。Iゲイン(ネガティブフィードバックの場合負の値に)
% 　出力　：controllerクラスのインスタンス
    
    properties(SetAccess=protected)
        type = 'global';
        port_input   = 'Pmech';
        port_observe = 'omega';
    end

    properties(SetAccess = protected)
        Kp
        Ki
        default_K_input
        default_K_observe
        K_input     %並列機器の制御対象
        K_observe   %並列機器の制御対象
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
            k = obj.default_K_input(ismember(obj.index_input, obj.connected_index_input));
            obj.K_input = k./sum(k);
            o = obj.default_K_observe(ismember(obj.index_observe, obj.connected_index_observe));
            obj.K_observe   = o/sum(o);
        end
        
        function nx = get_nx(~)
            nx = 1;
        end
        
        function [dx, u] = get_dx_u(obj, t, x, X, V, I, u_global)%#ok
            dx = obj.K_observe(:).'* vertcat(X{:});
            u     = cell(size(obj.idx_port));
            for i = 1:numel(obj.connected_index_input)
                u{i} = obj.K_input(i)*(obj.Ki*x + obj.Kp*dx);
            end
        end
        
        function [A, BX, BV, BI,  Bu, C, DX, DV, DI, Du] = get_linear_matrix(obj)
            n_observe = numel(obj.connected_index_observe);
            n_input   = numel(obj.connected_index_input);
            nu = sum(tools.hcellfun(@(a) size(a,1),obj.idx_port));
        
            A  = 0;            
            BX = obj.K_observe(:).';
            BV = zeros( 1, 2*n_observe);
            BI = zeros( 1, 2*n_observe);
            Bu = zeros( 1, nu);
            
            C  = obj.K_input(:) * obj.Ki;
            DX = obj.K_input(:) * obj.Kp;
            DV = zeros( n_input, 2*n_observe);
            DI = zeros( n_input, 2*n_observe);
            Du = zeros( n_input, sum(nu) );
        end
        
        function out = get_signals(obj, X, V)%#ok
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
            if numel(K_input) == numel(obj.connected_index_input)
                obj.default_K_input = K_input;
            else
                error('The number of elements in K_input must match the number of elements in index_input.')
            end
        end
        function set_K_observe(obj,K_observe)
            if numel(K_observe) == numel(obj.connected_index_observe)
                obj.default_K_observe = K_observe;
            else
                error('The number of elements in K_input must match the number of elements in index_observe.')
            end
        end
    end
end
