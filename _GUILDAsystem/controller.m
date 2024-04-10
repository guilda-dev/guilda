classdef controller < base_class.HasStateInput & base_class.HasGridCode & base_class.HasCostFunction
% コントローラを定義するスーパークラス
% GUILDA上に制御器モデルを実装するために必要なmethodが定義されている。
% 新しい制御器モデルを実装する場合はこのcontrollerクラスを継承すること。
    
    properties
        parameter = array2table(zeros(1,0))
        type = 'local';
    end

    properties(SetAccess = protected)
        port_input   = 'all';
        port_observe = 'all';
        index_input            %制御出力先
        index_observe          %制御観測先
        system_matrix   
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
            obj.register_parent(net,'overwrite')
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
    
                % port_〇〇のindexを取得
                if isempty(obj.port_observe)|| strcmp(obj.port_observe,'all')
                    obj.idx_state = tools.cellfun(@(c) 1:c.get_nx, obj.default_component_observe);
                else
                    obj.idx_state = tools.cellfun(@(c) find(strcmp(c.get_state_name,obj.port_observe)), obj.default_component_observe);
                end
                if isempty(obj.port_input)|| strcmp(obj.port_input,'all')
                    obj.idx_port  = tools.cellfun(@(c) 1:c.get_nu, obj.default_component_input);
                else
                    obj.idx_port  = tools.cellfun(@(c) find(strcmp(c.get_port_name,obj.port_input)), obj.default_component_input);
                end

                % portが空でない観測・制御対象のlogical
                logi_has_in = tools.vcellfun(@(c) ~isempty(c), obj.idx_port);
                logi_has_ob = tools.vcellfun(@(c) ~isempty(c), obj.idx_state);
    
                % 並列機器を観測・制御対象とする
                logi_connect_in = tools.vcellfun(@(b) strcmp(b.parallel, "on"), obj.default_component_input);
                logi_connect_ob = tools.vcellfun(@(b) strcmp(b.parallel, "on"), obj.default_component_observe);
    
                % 指定されたポート名を持たない機器番号を除外する
                obj.index_input   = obj.default_index_input(   logi_has_in & logi_connect_in);
                obj.index_observe = obj.default_index_observe( logi_has_ob & logi_connect_ob);
                
    
                % 接続機器の各入力ポート数に合わせたゼロ行列をcell配列で定義しておく
                component = obj.default_component_input( logi_has_in & logi_connect_in );
                obj.zero_cell = tools.cellfun(@(c) zeros(c.get_nu,1), component);
    
                obj.initialize;
                obj.set_linear_matrix;
    
                % 除外された機器番号に関するメッセージの表示
                cls = class(obj);
                func( obj.default_index_input(~logi_connect_in)  ,  'Input' ,cls,'it has been disconnected.')
                func( obj.default_index_observe(~logi_connect_ob), 'Observe',cls,'it has been disconnected.')
                func( obj.default_index_input(~logi_has_in)      ,  'Input' ,cls, ['it does not have a state called "',obj.port_input,'".'])
                func( obj.default_index_observe(~logi_has_ob)    , 'Observe',cls, ['it does not have a port called "',obj.port_observe,'".'])
    
                    function func( diff_idx,type, cls, cause)
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



    %% 線形化関連のメソッド
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function set_linear_matrix(obj)
            sys = struct();
            [ sys.A , sys.BX, sys.BV, sys.BI, sys.Bu, ...
              sys.C , sys.DX, sys.DV, sys.DI, sys.Du] = obj.get_linear_matrix();
            obj.system_matrix = sys;
        end

        function [dx, u] = get_dx_u_linear(obj, ~, x, X, V, I, U_global)
            %%% (要デバッグ) %%%
            ss = obj.system_matrix;
            
            X = vertcat(X{:});
            V = vertcat(V{:});
            I = vertcat(I{:});
            u = vertcat(U_global{:});

            dx = ss.A*x + ss.BX*X + ss.BV*V + ss.BI*I + ss.Bu*u;
             u = ss.C*x + ss.DX*X + ss.DV*V + ss.DI*I + ss.Du*u;
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

