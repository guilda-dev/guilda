classdef controller < base_class.HasStateInput & base_class.HasGridCode & base_class.HasCostFunction
% コントローラを定義するスーパークラス
% GUILDA上に制御器モデルを実装するために必要なmethodが定義されている。
% 新しい制御器モデルを実装する場合はこのcontrollerクラスを継承すること。
    
    properties(SetAccess=protected)
        index_input
        index_observe
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
            
            [~, u(:)] = tools.arrayfun(@(i) obj.get_dx_u_func(t(i),x(i,:)',Xi(i),Vi(i),Ii(i),Ui(i)), 1:numel(t) );
            if iscell(u{1})
                uout = tools.vcellfun(@(c) tools.hcellfun(@(ci) ci(:).', c), u);
            else
                uout = tools.vcellfun(@(c) c(:).', u);
            end
            
        end
        
        function register_net(obj,net)
            obj.network = net;
        end

        function val = usage_function(obj,func)
            bus = obj.network.a_bus;
            x = obj.get_x0;
            X = tools.arrayfun(@(i) bus{i}.component.x_equilibrium, obj.index_observe(:));
            V = tools.arrayfun(@(i) tools.complex2vec(bus{i}.component.V_equilibrium), obj.index_observe(:));
            I = tools.arrayfun(@(i) tools.complex2vec(bus{i}.component.I_equilibrium), obj.index_observe(:));
            u = tools.arrayfun(@(i) zeros(bus{i}.component.get_nu,1), obj.index_input(:));
            try 
                val = func(obj,0,x,X,V,I,u);
            catch
                error(['The function handle seems to be in the wrong format.',newline,...
                       'It must be in the following format',newline,...
                       'func = @(obj,t,x,V,I,u) ~',newline,...
                       '・obj : own class object',newline,...
                       '・t = time(scalar)',newline,...
                       '・x = vector of controller states',newline,...
                       '・X = cell array of the state vector of each component to be observed',newline,...
                       '・V = cell array of the [real(V);imag(V)] of each component to be observed',newline,...
                       '・I = cell array of the [real(I);imag(I)] of each component to be observed',newline,...
                       '・u = cell array of the input vector of each component to be observed',newline])
            end
        end
        
    end
    
    methods(Access=protected)
        function PropEditor_Set(obj,prop,val)
            obj.(prop) = val;
        end
        function val = PropEditor_Get(obj,prop)
            val = obj.(prop);
        end
    end
end

