classdef odefactory < handle
    

%%%%%%%%%%%%%%%%%
%  properties   %
%%%%%%%%%%%%%%%%%
    properties
        time                % 開始時間/終了時間を格納
        StopTime = []       % シミュレーションを停止させる時間を指定(シミュレーション上の時間)

        isCalculated_disconnected_mac % 解列機器の状態を計算する(=true)　or 計算しない(=false)

        % 外部からシミュレーション条件を割り込みで入れる際に使用
        additional_V0bus  = [];     % << double(1xn) ・・・母線番号を追加すると対応する母線電圧が0(地絡状態)
        additional_I0bus  = [];     % << double(1xn) ・・・母線番号を追加すると対応する母線電流が0(機器の解列状態)
    end


    %　各オプションを管理するクラスを格納
    properties(SetAccess=protected)
        fault           % << supporters.for_simulate.options.fault         ・・・地絡の条件設定を司る
        input           % << supporters.for_simulate.options.input         ・・・入力データの条件設定を司る
        parallel        % << supporters.for_simulate.options.parallel      ・・・閉解列の条件設定を司る
        gridcode        % << supporters.for_simulate.reporter.GridCode     ・・・グリッドコードの判定及びレポートを表示
        response        % << supporters.for_simulate.reporter.StateResponse・・・状態の応答のリアルタイムプロットを表示
        progress        % << supporters.for_simulate.reporter.progress     ・・・進行状況の表示を司る
    end


    % シミュレーションに解を順次格納していくためのクラス(ユーザは見ることができるが編集はできない)
    properties(SetAccess=protected)
        ResponseStorage
    end


    % シミュレーション中に使用する各種変数（タームごとに更新・使用）
    properties(Access=protected)
        network             % networkクラスを格納
        readme              % シミュレーション結果出力時にREADMEを出力する
        
        GoNext   = false;   % このプロパティがtrueになると現在の最終値を初期値として再シミュレーション
        ToBeStop = false;   % このプロパティがtrueになるとシミュレーション中止

        do_retry            % odeソルバーが警告により途中停止した場合に再施行するかどうかを指定

        start_time          % シミュレーション開始時に現実時間を記録
        time_limit          % シミュレーションを停止させる時間を指定(現実時間)

        % ode関連
        initial             % 状態の初期値を格納
        odeoptions          % odeソルバーで使用するオプション

        % 全母線・機器・制御器のインデックスの管理
        all_logivec = struct('x',[],'xcl',[],'xcg',[]);
        all_logimat = struct('x',[],'xcl',[],'xcg',[]);
        all_Mass
    end

    % シミュレーション中に使用する各種変数(微分方程式の計算で使用)
    properties(Access=protected)

        Ymat            % non-unit busを縮約したアドミタンス行列
        Ymat_reproduce  % クロン縮約されたデータを元に戻す際に使用
        Ymat_all        % 縮約していないアドミタンス行列

        simulated_bus   % 状態の計算を行う機器のインデックス
        noreduced_bus   % アドミタンス行列において縮約されていない母線番号
        I0const_bus     % 電圧=0の母線インデックス(地絡状態)
        V0const_bus     % 電流=0の母線インデックス(機器解列状態)

        % シミュレーション中の地絡・解列等を加味したインデックスの管理
        logical = struct('x',[],'xcl',[],'xcg',[],'V',[],'I0const',[],'V0const',[]);
        logivec = struct('x',[],'xcl',[],'xcg',[],'V',[],'I0const',[],'V0const',[]);
        logimat = struct('x',[],'xcl',[],'xcg',[],'V',[],'I0const',[],'V0const',[]);
    end


%%%%%%%%%%%%%%%%%
%    method     %
%%%%%%%%%%%%%%%%%

    methods
        
        % コンストラクター
        function obj = odefactory(net, t, varargin)
            obj.time = [t(1),t(end)];
            obj.network  = net;

            if nargin < 3 || isstruct(varargin{1}) || ischar(varargin{1})
                obj.options = supporters.for_simulate.OptionFactory(obj,t,net,[],[],varargin{:});
            else
                obj.options = supporters.for_simulate.OptionFactory(obj,t,net,varargin{:});
            end
            obj.StateProcessor = supporters.for_simulate.StateProcessor(net,t, obj.options.initial);
            
        end


        % fault,parallel,input条件を後から追加したい場合のメソッド
        function add_fault(obj,varargin)
            obj.fault.add(varargin{:})
        end

        function add_parallel(obj,varargin)
            obj.parallel.add(varargin{:})
        end
        
        function add_input(obj,varargin)
            obj.input.add(varargin{:})
        end


        % オプション設定を出力するためのメソッド
        function option = export_option(obj)
            option = struct(...
                'linear', obj.network.linear           ,...
                'fault' , obj.fault.export_option      ,...
                'input' , obj.input.export_option      ,...
                ...% 'V0'    , obj.initial.V0               ,...
                ...% 'I0'    , obj.initial.I0               ,...
                ...% 'x0_sys', obj.initial.sys              ,...
                ...% 'x0_con_local' , obj.initial.con_local ,...
                ...% 'x0_con_global', obj.initial.con_global,...
                ...% 'parallel_component' , popt.mac        ,...
                ...% 'parallel_branch'    , popt.baranch    ,...
                ...% 'parallel_con_local' , popt.con_local  ,...
                ...% 'parallel_con_global', popt.con_global ,...
                'grid_code'   , obj.gridcode.mode      ,...
                'report'      , obj.progress.mode      ,...
                'OutputFcn'   , obj.response.mode      ,...
                'tools_readme', obj.readme             ,...
                'reset_time'  , obj.time_limit         ,...
                'do_retry'    , obj.do_retry           ,...
                'AbsTol'      , obj.odeoptions.AbsTol  ,...
                'RelTol'      , obj.odeoptions.RelTol  ,...
                'MaxOrder'    , obj.odeoptions.MaxOrder ...
                );
        end

    end

    methods(Access=protected)
        
        dx  = fx(obj, t, x)             % 微分代数方程式を定義
        out = run(obj)                  % シミュレーションを実行するメソッド

        f   = Fcn_Event(obj,varargin)    % ODEソルバーのEventFcnに代入する関数を定義
        f   = Fcn_Output(obj,varargin)   % ODEソルバーのOutputFcnに代入する関数を定義

        set_options(obj,uidx,u,option)  % optionデータを振り分けてセットする
        set_parameter(obj)              % 微分方程式fxの計算で使用するパラメータのセット
        set_last_time(obj,t)            % タームの更新ごとに最終時刻を更新
        
        [x0,const0] = get_initial(obj)
        out         = get_next_tend(obj)

        [x,xcl,xcg,V,I] = organize_x(obj,xsys)

    end

end


