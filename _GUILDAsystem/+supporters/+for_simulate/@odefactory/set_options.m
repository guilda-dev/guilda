function set_options(obj,t,uidx,u,varargin)

    net = obj.network;
    

    %% データの整理
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        p = inputParser;
        p.CaseSensitive = false;
        % linear/nolinear simulation
            addParameter(p, 'linear'           , false);

        % fault setting
            addParameter(p, 'fault'            , []);

        % Set input signal 
            addParameter(p, 'input'            , []);
            addParameter(p, 'method'           , 'zoh');

        % Set the condition for parallel on/off
            ftrue = @(d) true(numel(d),1);
            addParameter(p, 'init_parallel_sys'       , ftrue(net.a_bus)              );
            addParameter(p, 'init_parallel_branch'    , ftrue(net.a_branch)           );
            addParameter(p, 'init_parallel_con_local' , ftrue(net.a_controller_local) );
            addParameter(p, 'init_parallel_con_global', ftrue(net.a_controller_global));
            
            addParameter(p, 'parallel_sys'       , []);
            addParameter(p, 'parallel_branch'    , []);
            addParameter(p, 'parallel_con_local' , []);
            addParameter(p, 'parallel_con_global', []);
            addParameter(p, 'simulate_when_disconnect', false);

        % Set initial state value
            %addParameter(p, 'V0'               , net.V_equilibrium);
            %addParameter(p, 'I0'               , net.I_equilibrium);
            addParameter(p, 'x0_sys'           , net.x_equilibrium);
            addParameter(p, 'x0_con_local'     , tools.vcellfun(@(c) c.get_x0(), net.a_controller_local ));
            addParameter(p, 'x0_con_global'    , tools.vcellfun(@(c) c.get_x0(), net.a_controller_global));

        % Simulation setup (basically no need to tinker with it)
            addParameter(p, 'tools_readme'     , false   , @(val) islogical(val) );

        % Whether to consider grid codes in simulations
            addParameter(p, 'gridcode'         , 'ignore', @(method) ismember(method, {'ignore', 'interruption', 'monitor', 'control'}));
            addParameter(p, 'gridcode_viewer'  , {'component','branch'}  , @(method) islogical(method));

        % Specify state responses to be plotted in real time
            addParameter(p, 'OutputFcn'  ,  [] ); %状態変数名を指定

        % Whether the progress is live or not
            addParameter(p, 'report'           , 'disp', @(method) ismember(method, {'none', 'disp', 'dialog'}));
  
        % when simulation take a long time, whether continue or not 
            addParameter(p, 'time_limit'       , inf     , @(val) isnumeric(val) );
            addParameter(p, 'do_retry'         , true    , @(val) islogical(val) );

        % option for ode solver 
            addParameter(p, 'AbsTol'           , 1e-8);
            addParameter(p, 'RelTol'           , 1e-8);
            addParameter(p, 'MaxOrder'         , 5   );    % 1~5
            
        % set ssampling time
            addParameter(p, 'sampling_time'    , 'auto');

        parse(p, varargin{:});
        op = p.Results;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



    % 各クラスのparallel状態を初期化する
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fconnect = @(a_class, l) arrayfun(@(i) connect(a_class{i}, l(i)), 1:numel(l));
    a_component = tools.cellfun(@(b) b.component, net.a_bus);
    fconnect(a_component , op.init_parallel_sys   )
    fconnect(net.a_branch, op.init_parallel_branch)
    fconnect(net.a_controller_local , op.init_parallel_con_local )
    fconnect(net.a_controller_global, op.init_parallel_con_global)

    function connect(c,flag)
        if flag; c.connect;
        else;    c.disconnect;
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



    % 整理したデータを元にデータのセット及びクラスの構築を行う
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        
        xidx   = tools.dcellfun(@(b) true(b.component.get_nx,1), net.a_bus);
        x0_sys = tools.arrayfun(@(i) op.x0_sys(xidx(:,i)), 1:numel(net.a_bus));

        xclidx = tools.dcellfun(@(c) true(c.get_nx,1), net.a_controller_local);
        x0_con_local = tools.arrayfun(@(i) op.x0_con_local(xclidx(:,i)), 1:numel(net.a_controller_local));

        xcgidx = tools.dcellfun(@(c) true(c.get_nx,1), net.a_controller_global);
        x0_con_global = tools.arrayfun(@(i) op.x0_con_global(xcgidx(:,i)), 1:numel(net.a_controller_global));

        V0vec = tools.complex2vec(net.V_equilibrium);
        V0 = num2cell(reshape(V0vec,2,[]),1);
        a_nan = tools.cellfun(@(b) nan(2,1), net.a_bus);

        if isnumeric(op.sampling_time) && numel(op.sampling_time)
            obj.sampling_time = t(1):op.sampling_time:t(end);
        elseif strcmp(op.sampling_time,'auto')
            obj.sampling_time = 'auto';
        else
            error('sampling_timeの設定値が正しくありません。')
        end

        % 状態・代数の初期値を格納しておく
        obj.initial.x   = x0_sys;
        obj.initial.xcl = x0_con_local;
        obj.initial.xcg = x0_con_global;
        obj.initial.V   = V0(:);
        obj.initial.I0const = a_nan;
        obj.initial.V0const = a_nan;


        % オプションを管理するクラス群を生成
        obj.fault     = supporters.for_simulate.options.fault(     obj, op.fault );
        obj.parallel  = supporters.for_simulate.options.parallel(  obj, op );
        obj.input     = supporters.for_simulate.options.input(     obj, t, uidx, u, op.input, op.method);
        obj.gridcode  = supporters.for_simulate.reporter.gridcode( obj, t, [], op.gridcode, op.gridcode_viewer);
        obj.response  = supporters.for_simulate.reporter.response( obj, t, op.OutputFcn );
        obj.progress  = supporters.for_simulate.reporter.progress( obj, op.report, op.time_limit); 


        % その他のインデックス
        obj.LastTime     = t(1);                % シミュレーションの最終時間を表示するプロパティに開始時刻をセット
        net.linear       = op.linear;           % power_networkクラスのlinearプロパティを更新 >> netクラスのsetメソッドが実行
        obj.readme       = op.tools_readme;     
        obj.do_retry     = op.do_retry;     
        obj.odeoptions = odeset(...             % odeオプションの静的なデータのみ予めセットしておく
                'RelTol'      , op.RelTol  , ...
                'AbsTol'      , op.AbsTol  , ...
                'MaxOrder'    , op.MaxOrder, ...
                'MassSingular','yes'       );
        obj.isCalculated_disconnected_mac = op.simulate_when_disconnect;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end
