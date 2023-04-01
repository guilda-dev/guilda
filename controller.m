classdef controller < handle
% コントローラを定義するスーパークラス
% GUILDA上に制御器モデルを実装するために必要なmethodが定義されている。
% 新しい制御器モデルを実装する場合はこのcontrollerクラスを継承すること。
    
    properties(SetAccess=protected)
        index_input
        index_observe
        CostFunction = @(obj, t, x, X, V, I, U_global) 0;
    end
    
    properties(Dependent)
        index_all
    end
    
    properties
        parameter
    end
    
    methods(Abstract)
        [dx, u] = get_dx_u(obj, t, x, X, V, I, U_global);
        nx = get_nx(obj);
    end

    properties(Access = protected)
        network
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

        function set_CostFunction(obj,func)
            obj.CostFunction = func;
        end
        function set.CostFunction(obj,func)
            obj.check_function(func, 'double');
            obj.CostFunction = func;
        end

        function check_function(obj, f, val_type)
            try
                X = tools.arrayfun(@(i)   obj.network.a_bus{i}.component.x_equilibrium,obj.index_input(:));
                V = tools.arrayfun(@(i)   obj.network.a_bus{i}.component.V_equilibrium,obj.index_input(:));
                I = tools.arrayfun(@(i)   obj.network.a_bus{i}.component.I_equilibrium,obj.index_input(:));
                U = tools.arrayfun(@(i) zeros(obj.network.a_bus{i}.component.get_nu,1),obj.index_observe(:));
                val = f(obj, 0, x, X, V, I, U);
                if ~isa(val,val_type); error_code =1; 
                else; error_code =0; end
            catch
                error_code = 2;
            end
            switch error_code
                case 1; error(['The return type of the function should be ',val_type])
                case 2; error('The function must be in the form of f(obj,t,x,V,I,u)')
            end
        end
        
        function register_net(obj,net)
            obj.network = net;
        end
        
    end
    
    
end

