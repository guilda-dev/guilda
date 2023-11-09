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
            addParameter(p, 'parallel_component' , []);
            addParameter(p, 'parallel_branch'    , []);
            addParameter(p, 'parallel_con_local' , []);
            addParameter(p, 'parallel_con_global', []);
            addParameter(p, 'simulate_disconncted_mac', true);

        % Set initial state value
            addParameter(p, 'V0'               , net.V_equilibrium);
            addParameter(p, 'I0'               , net.I_equilibrium);
            addParameter(p, 'x0_sys'           , net.x_equilibrium);
            addParameter(p, 'x0_con_local'     , tools.vcellfun(@(c) c.get_x0(), net.a_controller_local ));
            addParameter(p, 'x0_con_global'    , tools.vcellfun(@(c) c.get_x0(), net.a_controller_global));

        % Simulation setup (basically no need to tinker with it)
            addParameter(p, 'tools_readme'     , false   , @(val) islogical(val) );

        % Whether to consider grid codes in simulations
            addParameter(p, 'gridcode'         , 'ignore', @(method) ismember(method, {'ignore', 'interruption', 'monitor', 'control'}));
            addParameter(p, 'gridcode_viewer'  , false   , @(method) islogical(method));

        % Specify state responses to be plotted in real time
            addParameter(p, 'OutputFcn'  ,  {} ); %状態変数名を指定

        % Whether the progress is live or not
            addParameter(p, 'report'           , 'dialog', @(method) ismember(method, {'none', 'cmd', 'dialog'}));
  
        % when simulation take a long time, whether continue or not 
            addParameter(p, 'reset_time'       , inf     , @(val) isnumeric(val) );
            addParameter(p, 'do_retry'         , true    , @(val) islogical(val) );

        % option for ode solver 
            addParameter(p, 'AbsTol'           , 1e-8);
            addParameter(p, 'RelTol'           , 1e-8);
            addParameter(p, 'MaxOrder'         , 5   );    % 1~5

        parse(p, varargin{:});
        op = p.Results;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    


    % 整理したデータを元にデータのセット及びクラスの構築を行う
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        obj.current_time = t(1);                % シミュレーションの最終時間を表示するプロパティに開始時刻をセット
        net.linear       = op.linear;           % power_networkクラスのlinearプロパティを更新 >> netクラスのsetメソッドが実行
        obj.readme       = op.tools_readme;     
        obj.do_retry     = op.do_retry;         
        obj.time_limit   = op.reset_time;       
        obj.odeoptions = odeset(...             % odeオプションの静的なデータのみ予めセットしておく
                'RelTol'      , op.RelTol  , ...
                'AbsTol'      , op.AbsTol  , ...
                'MaxOrder'    , op.MaxOrder, ...
                'MassSingular','yes'       );
        obj.initial = struct(...                % 状態・代数の初期値を格納しておく
                'sys', op.x0_sys        ,...
                'cl' , op.x0_con_local  ,...
                'cg' , op.x0_con_global ,...
                'V0' , op.V0            ,...
                'I0' , op.I0            );
    
        obj.fault     = supporters.for_simulate.options.fault(     obj, t, op.fault );
        obj.parallel  = supporters.for_simulate.options.parallel(  obj, t, op );
        obj.input     = supporters.for_simulate.options.input(     obj, t, uidx, u, op );
        obj.gridcode  = supporters.for_simulate.reporter.gridcode( obj, op.gridcode, op.gridcode_viewer);
        obj.response  = supporters.for_simulate.reporter.response( obj, op.OutputFcn );
        obj.progress  = supporters.for_simulate.reporter.progress( obj, op.report    ); 

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end
