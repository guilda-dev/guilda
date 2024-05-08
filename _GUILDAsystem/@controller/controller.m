classdef controller < handle & base_class.HasStateInput & base_class.HasGridCode & base_class.HasCostFunction
% コントローラを定義するスーパークラス
% GUILDA上に制御器モデルを実装するために必要なmethodが定義されている。
% 新しい制御器モデルを実装する場合はこのcontrollerクラスを継承すること。
    
    properties
        parameter = array2table(zeros(1,0))
    end

    properties(SetAccess=protected, Abstract)
        type {mustBeMember(type,{'local','global'})}
        port_input  
        port_observe
    end

    properties(SetAccess = protected)
        connected_index_input    %制御出力先
        connected_index_observe  %制御観測先
        system_matrix   
    end

    properties(Dependent)
        index_all
        network
    end

    properties(SetAccess=protected,Dependent)
        index_input           %userの出力先の指定値(indexのdouble配列)
        index_observe         %userの観測先の指定値(indexのdouble配列)
    end
    %   ↓
    %   ↓ index_〇〇を決めると、以下のプロパティが自動でセット
    %   ↓
    properties(SetAccess = protected)
        a_component_input     %userの出力先の指定値(componentクラスのcell配列)
        a_component_observe   %userの観測先の指定値(componentクラスのcell配列)
    end

    properties(Access=protected)
        idx_state             %port_observeのindexを取得(何列目にport_observeで指定された状態量があるか)
        idx_port              %port_inputのindexを取得(何列目にport_inputで指定された状態量があるか)
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
            obj.index_input  = index_input;
            obj.index_observe= index_observe;
        end

        function set_glocal(obj,gl)
            switch gl
                case 'local' ; obj.type = 'local';
                case 'global'; obj.type = 'global';
                otherwise; error('type must be "local" or "global"')
            end
        end
        

    %% simulateの際に使用するメソッド
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            % 初期値を定義するメソッド >> デフォルトでは状態数分の零行列として定義する仕様
            function out = get_x0(obj)
                out = zeros(obj.get_nx(), 1);
            end

            % 機器母線に関する時系列データから入力の時系列データを返す関数
            function uout = get_input_vectorized(obj, t, x, X, V, I, U)
                Xi = @(i) tools.cellfun(@(x) x(:,i), X);
                Vi = @(i) tools.cellfun(@(v) v(:,i), V);
                Ii = @(j) tools.cellfun(@(i) i(:,j), I);
                Ui = @(i) tools.cellfun(@(u) u(:,i), U);
                is = ismember( obj.index_input, obj.connected_index_input);
                zero = tools.cellfun(@(c) zeros(c.get_nu,1), obj.a_component_input(:));
                u_ = repmat(zero,1,numel(t));  
                for ti = 1:numel(t)
                    [~, u_(is,ti)] = obj.get_dx_u_func(t(ti),x(:,ti),Xi(ti),Vi(ti),Ii(ti),Ui(ti));
                end
                uout = tools.arrayfun(@(i) horzcat(u_{i,:}), (1:size(u_,1))');
            end

            % 機器の解列状況に応じてインデックスを更新させる
            function update_idx(obj)
                if isempty(obj.port_input  ); obj.port_input  ='all'; end
                if isempty(obj.port_observe); obj.port_observe='all'; end
    
                % setメソッドを起動し各種プロパティの再設定を行う
                obj.index_input  = obj.index_input;
                obj.index_observe= obj.index_observe;
    
                % 並列機器を観測・制御対象とする
                logi_connect_in = tools.vcellfun(@(b) strcmp(b.parallel, "on"), obj.a_component_input);
                logi_connect_ob = tools.vcellfun(@(b) strcmp(b.parallel, "on"), obj.a_component_observe);
    
                obj.connected_index_input   = obj.index_input(   logi_connect_in);
                obj.connected_index_observe = obj.index_observe( logi_connect_ob);
                obj.idx_state = obj.idx_state(logi_connect_ob);
                obj.idx_port  = obj.idx_port( logi_connect_in);
    
                % controllerの子クラスでupdate_idxのタイミングで実装する内容を設定
                obj.initialize;

                % 近似線形化モデルの再定義
                obj.set_linear_matrix;
    
                % 除外された機器番号に関するメッセージの表示
                cls = class(obj);
                func( obj.index_input(  ~logi_connect_in), 'Input'  , cls, 'it has been disconnected.')
                func( obj.index_observe(~logi_connect_ob), 'Observe', cls, 'it has been disconnected.')
            end

            % linearが書き換えられた際に実行される
            function set_function(obj,linear)
                if linear
                    obj.get_dx_u_func = @obj.get_dx_u_linear;
                else
                    if strcmp(obj.port_input,'all') && strcmp(obj.port_observe,'all')
                        obj.get_dx_u_func = @obj.get_dx_u;
                    else
                        obj.get_dx_u_func = @obj.get_dx_u_nolinear;
                    end
                end
            end



    %% この制御器が入力する機器のポート名の配列を返す
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function name = get_port_name(obj)
            name = tools.hcellfun(@(c) porti(c), obj.a_component_input); 
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
            [A,BX,BV,BI,Bu,C,DX,DV,DI,Du] = obj.get_linear_matrix();

            sys.A  = A;
            sys.BX = BX * blkdiag(obj.idx_state{:});
            sys.BV = BV;
            sys.BI = BI;
            sys.Bu = Bu;

            udiag = blkdiag(obj.idx_port{:});
            sys.C  = udiag * C;
            sys.DX = udiag * DX;
            sys.DV = udiag * DV;
            sys.DI = udiag * DI;
            sys.Du = udiag * Du;

            obj.system_matrix = sys;
        end

        function [dx, u] = get_dx_u_nolinear(obj, t, x, X, V, I, U_global)
            X = tools.arrayfun(@(i) obj.idx_state{i}* X{i}, (1:numel(X))' );
            [dx, u] = obj.get_dx_u(t, x, X, V, I, U_global);
            u = tools.arrayfun(@(i) obj.idx_port{i} * u{i}, (1:numel(u))' );
        end

        function [dx, u] = get_dx_u_linear(obj, ~, x, X, V, I, U_global)
            ss = obj.system_matrix;
            X = tools.varrayfun(@(i) obj.idx_state{i}*X{i}, 1:numel(X));
            V = vertcat(V{:});
            I = vertcat(I{:});
            u = vertcat(U_global{:});

            dx = ss.A*x + ss.BX*X + ss.BV*V + ss.BI*I + ss.Bu*u;
            u_ = ss.C*x + ss.DX*X + ss.DV*V + ss.DI*I + ss.Du*u;

            uout = cell(numel(obj.connected_index_input),1);
            cnt = 0;
            for i = 1:numel(obj.connected_index_input)
                nu = obj.net.a_bus{obj.connected_index_input(i)}.component.get_nu;
                uout{i} = u_(cnt+(1:nu),:);
                cnt = cnt + nu;
            end
        end        


    %% Getメソッド
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function out = get.index_all(obj);     out = unique([obj.connected_index_observe; obj.connected_index_input]); end
        function out = get.network(obj);       out = obj.parents{1};                                                   end
        function out = get.index_input(obj);   out = tools.hcellfun(@(c) c.index, obj.a_component_input);              end
        function out = get.index_observe(obj); out = tools.hcellfun(@(c) c.index, obj.a_component_observe);            end


    %% Setメソッド
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function set.index_input(obj,index_input)
            [obj.idx_port, obj.a_component_input] = func4set_index(obj, obj.port_input, index_input, 'u');
        end
        function set.index_observe(obj,index_observe)
            [obj.idx_state, obj.a_component_observe] = func4set_index(obj, obj.port_observe, index_observe, 'x');
        end


    %% get_dx_uの関数の型をチェックするためのメソッド
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function val = check_CostFunction(obj,func)
            bus = obj.network.a_bus;
            x = obj.get_x0;
            X = tools.arrayfun(@(i) bus{i}.component.x_equilibrium, obj.connected_index_observe(:));
            V = tools.arrayfun(@(i) tools.complex2vec(bus{i}.component.V_equilibrium), obj.connected_index_observe(:));
            I = tools.arrayfun(@(i) tools.complex2vec(bus{i}.component.I_equilibrium), obj.connected_index_observe(:));
            u = tools.arrayfun(@(i) zeros(bus{i}.component.get_nu,1), obj.connected_index_input(:));
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



function func( diff_idx,type, cls, cause)
    if ~isempty(diff_idx)
        disp([' ▶︎ ',type,'@',cls,' : Component ',mat2str(diff_idx),' was removed because ',cause])
    end
end

function [idx_port,a_comp] = func4set_index(obj,port_name,index, mode)
    switch mode
        case 'x'
            freport = @(idx, str_port) func( idx, 'Observe', class(obj), ['it does not have a port ',str_port,'.']);
            fname   = @(idx) obj.network.a_bus{idx}.component.get_state_name;
            fmat    = @(idx) tools.darrayfun(@(i) ones(i,1),idx);
        case 'u'
            freport = @(idx, str_port) func( idx, 'Input', class(obj), ['it does not have a state ',str_port,'.']);
            fname   = @(idx) obj.network.a_bus{idx}.component.get_port_name;
            fmat    = @(idx) tools.darrayfun(@(i) ones(1,i),idx);
    end

    if isempty(port_name) || strcmp(port_name,'all')
        idx = tools.arrayfun(@(i) fmat(true(size(fname(i)))), index);
        str_port = '';
        has_port = tools.hcellfun(@(c) ~isempty(c), idx);
    else
        idx = tools.arrayfun(@(i) fmat(strcmp(fname(i),port_name)), index);
        switch class(port_name)
            case 'cell'
            str_port = ['called',tools.hcellfun(@(s) [' "',char(s),'"'], port_name)];
            port_num = numel(port_name);
            case 'string'
            str_port = ['called',tools.harrayfun(@(i) [' "',char(port_name(i)),'"'], 1:numel(port_name))];
            port_num = numel(port_name);
            otherwise
            str_port = ['called "',char(port_name),'"'];
            port_num = 1;
        end
        has_port = tools.hcellfun(@(c) sum(c,'all')==port_num, idx);
    end
    freport(index(~has_port), str_port)

    % 出力変数の定義
    idx_port = idx(has_port);
    a_comp   = tools.cellfun(@(b)b.component, obj.network.a_bus(index(has_port)));
end

