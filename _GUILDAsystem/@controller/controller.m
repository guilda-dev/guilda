classdef controller < handle & base_class.HasStateInput & base_class.HasGridCode & base_class.HasCostFunction
% コントローラを定義するスーパークラス
% GUILDA上に制御器モデルを実装するために必要なmethodが定義されている。
% 新しい制御器モデルを実装する場合はこのcontrollerクラスを継承すること。
    
    properties
        parameter = array2table(zeros(1,0))
        type = 'local';
    end

    properties(SetAccess = private, Abstract)
        port_input
        port_observe
    end

    properties(SetAccess=protected)
        index_input            %制御出力先
        index_observe          %制御観測先
    end

    properties(Access=protected,Dependent)
        default_index_input    %userの出力先の指定値(indexのdouble配列)
        default_index_observe  %userの観測先の指定値(indexのdouble配列)
    end

    properties(Access=protected)
        default_component_input     %userの出力先の指定値(componentクラスのcell配列)
        default_component_observe   %userの観測先の指定値(componentクラスのcell配列)
        idx_state                   %port_observeのindexを取得(何列目にport_observeで指定された状態量があるか)
        idx_port                    %port_inputのindexを取得(何列目にport_inputで指定された状態量があるか)
        zero_cell 
    end

    properties(Dependent)
        index_all
        network
    end
    
    methods(Abstract)
        [dx, u] = get_dx_u(obj, t, x, X, V, I, U_global);
        nx = get_nx(obj);
        initialize(obj)          
    end
    
    properties
        get_dx_u_func
    end
    
    methods

    %% コンストラクターメソッド
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = controller(net, index_input, index_observe)
            obj.default_component_input   = tools.arrayfun(@(i) net.a_bus{i}.component, index_input);
            obj.default_component_observe = tools.arrayfun(@(i) net.a_bus{i}.component, index_observe);
        end
        



        %% simulateの際に使用するメソッド
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            % 初期値を定義するメソッド >> デフォルトでは状態数分の零行列として定義する仕様
            function out = get_x0(obj)
                out = zeros(obj.get_nx(), 1);
            end

            % 機器母線に関する時系列データから入力の時系列データを返す関数
            function uout = get_input_vectorized(obj, t, x, X, V, I, U)
                Xi = @(i) tools.cellfun(@(x) x(:,i)', X);
                Vi = @(i) tools.cellfun(@(v) v(:,i)', V);
                Ii = @(j) tools.cellfun(@(i) i(:,j)', I);
                Ui = @(i) tools.cellfun(@(u) u(:,i)', U);
                
                is = ismember( obj.default_index_input, obj.index_input);
                zero = tools.cellfun(@(c) zeros(c.get_nu,1), obj.default_component_input(:));
                u_ = repmat(zero,1,numel(t));    
                for ti = 1:numel(t)
                    [~, u_(is,ti)] = obj.get_dx_u_func(t(ti),x(:,ti),Xi(ti),Vi(ti),Ii(ti),Ui(ti));
                end
                uout = tools.arrayfun(@(i) horzcat(u_{i,:}), (1:size(u_,1))');
            end

            % 機器の解列状況に応じてインデックスを更新させる
            function update_idx(obj)
                net = obj.network;
    
                % port_〇〇のindexを取得
                obj.idx_state = tools.cellfun(@(b) find(strcmp(get_state_name(b.component),obj.port_observe)), net.a_bus);
                obj.idx_port  = tools.cellfun(@(b) find(strcmp(get_port_name( b.component),obj.port_input)), net.a_bus);
    
                % 並列機器を観測・制御対象とする
                idx_connect = find(tools.vcellfun(@(b) strcmp(b.component.parallel, "on"), net.a_bus));
                index_input_   = intersect(idx_connect, obj.default_index_input);
                index_observe_ = intersect(idx_connect, obj.default_index_observe);
    
                % 指定されたポート名を持たない機器番号を除外する
                obj.index_input   = index_input_(  tools.harrayfun(@(i) ~isempty(obj.idx_port{i} ), index_input_  ));
                obj.index_observe = index_observe_(tools.harrayfun(@(i) ~isempty(obj.idx_state{i}), index_observe_));
                
    
                % 接続機器の各入力ポート数に合わせたゼロ行列をcell配列で定義しておく
                fz = @(i) zeros(net.a_bus{i}.component.get_nu,1);
                obj.zero_cell = tools.arrayfun(@(i) fz(i), obj.index_input(:));
    
                obj.initialize;
    
                % 除外された機器番号に関するメッセージの表示
                cls = class(obj);
                func( obj.default_index_input,  index_input_,  'Input'  ,cls,'it has been disconnected.')
                func( obj.default_index_observe,index_observe_,'Observe',cls,'it has been disconnected.')
                func( index_input_,   obj.index_input,   'Input',   cls, ['it does not have a state called "',obj.port_input,'".'])
                func( index_observe_, obj.index_observe, 'Observe', cls, ['it does not have a port called "',obj.port_observe,'".'])
    
                    function func( idx1,idx2,type, cls, cause)
                        diff_idx = setdiff(idx1,idx2);
                        if ~isempty(diff_idx)
                            warning([type,'@',cls,' : Component ',mat2str(diff_idx),' was removed because ',cause])
                        end
                    end
            end

            % linearが書き換えられた際に実行される
            function set_function(obj,linear)
                if linear
                    obj.get_dx_u_func = @obj.get_dx_u_linear;
                else
                    obj.get_dx_u_func = @obj.get_dx_u;
                end
            end



    %% この制御器が入力する機器のポート名の配列を返す
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function name = get_port_name(obj)
            name = tools.hcellfun(@(c) porti(c), obj.default_component_input); 
            function out = porti(comp)
                num = ['_',num2str(comp.index)];
                out = tools.cellfun(@(c) [c,num], comp.get_port_name);
                out = out(:)';
            end
        end
        


    %% 各種プロパティのGetメソッド
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function out = get.index_all(obj)
            out = unique([obj.index_observe; obj.index_input]);
        end

        function n = get.network(obj)
            n = obj.parents{1};
        end

        function out = get.default_index_input(obj)
            out = tools.hcellfun(@(c) c.index, obj.default_component_input);
        end
        function out = get.default_index_observe(obj)
            out = tools.hcellfun(@(c) c.index, obj.default_component_observe);
        end
    
    

    %% get_dx_uの関数の型をチェックするためのメソッド
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function val = check_CostFunction(obj,func)
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

