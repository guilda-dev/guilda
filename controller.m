classdef controller < handle
% コントローラを定義するスーパークラス
% GUILDA上に制御器モデルを実装するために必要なmethodが定義されている。
% 新しい制御器モデルを実装する場合はこのcontrollerクラスを継承すること。
    
    properties(SetAccess=private)
        index_input
        index_observe
    end
    
    properties(Dependent)
        index_all
    end
    
    methods(Abstract)
        [dx, u] = get_dx_u(obj, t, x, X, V, I, U_global);
        nx = get_nx(obj);
    end
    
    properties
        get_dx_u_func
    end
    
    methods
        function obj = controller(index_input, index_observe)
            obj.index_input = index_input;
            obj.index_observe = index_observe;
        end
        
        function out = get_x0(obj)
            out = zeros(obj.get_nx(), 1);
        end
        
        function out = get.index_all(obj)
            out = unique([obj.index_observe; obj.index_input]);
        end
        
        function uout = get_input_vectorized(obj, t, x, X, V, I, U)
            Xi = @(i) tools.cellfun(@(x) x(i, :)', X);
            Vi = @(i) tools.hcellfun(@(v) v(i, :)', V);
            Ii = @(j) tools.hcellfun(@(i) i(j, :)', I);
            Ui = @(i) tools.cellfun(@(u) u(i, :)', U);
            
            [~, u] = obj.get_dx_u_func(t(1), x(1, :)',  Xi(1), Vi(1), Ii(1), Ui(1));
            
            uout = zeros(numel(t), numel(u));
            uout(1, :) = u';
            
            for i = 2:numel(t)
                [~, u] = obj.get_dx_u_func(t(i), x(i, :)',  Xi(i), Vi(i), Ii(i), Ui(i));
                uout(i, :) = u';
            end
        end

        function x_name = get_state_name(obj)
            x_name = tools.arrayfun(@(i) ['x',num2str(i)],1:obj.get_nx);
        end
        
    end
    
    
end

