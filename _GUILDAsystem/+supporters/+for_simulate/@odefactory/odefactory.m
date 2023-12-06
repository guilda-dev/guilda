classdef odefactory < handle
    

%%%%%%%%%%%%%%%%%
%  properties   %
%%%%%%%%%%%%%%%%%
    properties
        time                % 開始時間/終了時間を格納
        StopTime = []       % シミュレーションを停止させる時間を指定(シミュレーション上の時間)
        ToBeStop = false;   % このプロパティがtrueになるとシミュレーション中止

        isCalculated_disconnected_mac % 解列機器の状態を計算する(=true)　or 計算しない(=false)

        % 外部からシミュレーション条件を割り込みで入れる際に使用
        additional_V0bus  = [];     % << double(1xn) ・・・母線番号を追加すると対応する母線電圧が0(地絡状態)
        additional_I0bus  = [];     % << double(1xn) ・・・母線番号を追加すると対応する母線電流が0(機器の解列状態)
    end

    % ユーザは見ることができるが編集はできない
    properties(SetAccess=protected)
        LastTime
        DataStorage = struct('t',[],'X',[],'Xcl',[],'Xcg',[],'V',[],'I',[],'sol',[],'u',[]);
        network                % << power_networkクラス

        sampling_time   % シミュレーション結果のサンプリング時間
    end


    %　各オプションを管理するクラスを格納
    properties(SetAccess=protected)
        fault           % << supporters.for_simulate.options.fault         ・・・地絡の条件設定を司る
        input           % << supporters.for_simulate.options.input         ・・・入力データの条件設定を司る
        parallel        % << supporters.for_simulate.options.parallel      ・・・解列の条件設定を司る
        gridcode        % << supporters.for_simulate.reporter.GridCode     ・・・グリッドコードの判定及びレポートを表示
        response        % << supporters.for_simulate.reporter.StateResponse・・・状態の応答のリアルタイムプロットを表示
        progress        % << supporters.for_simulate.reporter.progress     ・・・進行状況の表示を司る
    end




    % シミュレーション中に使用する各種変数（タームごとに更新・使用）
    properties(Access=protected)
        readme              % シミュレーション結果出力時にREADMEを出力する
        
        GoNext   = false;   % このプロパティがtrueになると現在の最終値を初期値として再シミュレーション

        do_retry            % odeソルバーが警告により途中停止した場合に再施行するかどうかを指定

        start_time          % シミュレーション開始時に現実時間を記録
        time_limit          % シミュレーションを停止させる時間を指定(現実時間)

        odeoptions          % odeソルバーで使用するオプション

        % 全母線・機器・制御器のインデックスの管理
        all_Mass            % 各機器・制御器の状態数・制約変数の個数に応じて質量行列を定義しておく
        all_Uzeros          % 各機器の入力ポート数に従った零行列のcell配列を定義しておく
    end

    % シミュレーション中に使用する各種変数(微分方程式の計算で使用)
    properties(Access=protected)
        ufunc           % 入力信号のデータを格納する構造体　<< obj.inputのget_ufuncメソッドで取得

        Ymat            % non-unit busを縮約したアドミタンス行列
        Ymat_all        % 縮約していないアドミタンス行列
        Vmat_reproduce  % クロン縮約された電圧フェーザを元のサイズに戻す際に使用
        Imat_reproduce  % クロン縮約された電流フェーザを元のサイズに戻す際に使用

        simulated_bus   % 状態の計算を行う機器のインデックス
        simulated_cl    % 状態の計算を行う機器のインデックス
        simulated_cg    % 状態の計算を行う機器のインデックス
        noreduced_bus   % アドミタンス行列において縮約されていない母線番号
        I0const_bus     % 電圧=0の母線インデックス(地絡状態)
        V0const_bus     % 電流=0の母線インデックス(機器解列状態)

        % シミュレーション中の地絡・解列等を加味したインデックスの管理
        logimat = struct('x',[],'xcl',[],'xcg',[],'V',[],'I0const',[],'V0const',[]);

        % 初期値を格納
        initial = struct('x',[],'xcl',[],'xcg',[],'V',[],'I0const',[],'V0const',[]);
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
                obj.set_options(t,[],[],varargin{:});
            else
                obj.set_options(t,varargin{:});
            end
            obj.all_Mass.x   = tools.cellfun(@(b) b.component.Mass, net.a_bus);
            obj.all_Mass.xcl = tools.cellfun(@(c) eye(c.get_nx), net.a_controller_local);
            obj.all_Mass.xcg = tools.cellfun(@(c) eye(c.get_nx), net.a_controller_global);
            obj.all_Uzeros    = tools.cellfun(@(b) zeros(b.component.get_nu,1), net.a_bus);
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


        option    = export_option(obj) % オプション設定を出力するためのメソッド
        [out,obj] = export_out(obj)    % 現状のシミュレーション結果をoutとして出力


        % タームの更新ごとに最終時刻を更新　>> fault,input,parallelのset.current_timeメソッドを実行し条件設定を更新
        function set.LastTime(obj,t)
            obj.fault.current_time    = t; %#ok
            obj.input.current_time    = t; %#ok
            obj.parallel.current_time = t; %#ok
            obj.LastTime = t;
        end


        % 追加のV0const/I0constをセットされた際の処理
        function set.additional_V0bus(obj,index)
            obj.additional_V0bus = index;
            obj.GoNext = true; %#ok
        end

        function set.additional_I0bus(obj,index)
            obj.additional_I0bus = index;
            obj.GoNext = true; %#ok
        end


        % シミュレーションを実行するメソッド
        [out,obj] = run(obj)

        function set.ToBeStop(obj,val)
            if val; obj.GoNext =  true; end %#ok
            obj.ToBeStop = val;
        end

    end

    methods(Access=protected)

        dx  = fx(obj, t, x)             % 微分代数方程式を定義
        
        [f,t,d] = Fcn_Event(obj,varargin)    % ODEソルバーのEventsに代入する関数を定義
        f       = Fcn_Output(obj,varargin)   % ODEソルバーのOutputFcnに代入する関数を定義

        set_options(obj,uidx,u,option,varargin)  % optionデータを振り分けてセットする
        set_parameter(obj)                       % 微分方程式fxの計算で使用するパラメータのセット

        [x0,const0] = get_initial(obj)
        out         = get_next_tend(obj)

        [X,Xcl,Xcg,V,I] = organize_Xode(obj,xsys)
        [X,Xcl,Xcg,V,I,Vvirtual] = expand_Xode(obj,xsys,idx_mac,idx_cl,idx_cg)

    end

end


