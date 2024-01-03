classdef odefactory < handle
   

%% properties
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ユーザは見ることができるが編集はできない %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(SetAccess=protected)
        time            % 開始時間/終了時間を格納
        LastTime
        network         % << power_networkクラス
        sampling_time   % シミュレーション結果のサンプリング時間
        odeoptions      % odeソルバーで使用するオプション
        DataStorage = struct('t',[],'X',[],'Xcl',[],'Xcg',[],'V',[],'I',[],'sol',[],'uin',[],'ucl',[],'ucg',[],'uall',[],...
                             'simulated_bus',[],'fault_bus',[],'Ymat_reproduce',[],'linear',[]);
    end

    

    %%%%%%%%%%%%%%%%%%
    %　補助クラスを格納 %
    %%%%%%%%%%%%%%%%%%
    properties(SetAccess=protected)
        % options
        fault           % << supporters.for_simulate.options.fault         ・・・地絡の条件設定を司る
        input           % << supporters.for_simulate.options.input         ・・・入力データの条件設定を司る
        parallel        % << supporters.for_simulate.options.parallel      ・・・解列の条件設定を司る
        
        % reporter
        gridcode        % << supporters.for_simulate.reporter.GridCode     ・・・グリッドコードの判定及びレポートを表示
        response        % << supporters.for_simulate.reporter.StateResponse・・・状態の応答のリアルタイムプロットを表示
        progress        % << supporters.for_simulate.reporter.progress     ・・・進行状況の表示を司る
    end


    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % シミュレーション中に使用するフラッグ変数（タームごとに更新・使用）%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        StopTime = []       % シミュレーションを停止させる時間を指定(シミュレーション上の時間)
        ToBeStop = false;   % このプロパティがtrueになるとシミュレーション中止
    end
    properties(Access=protected)
        readme              % シミュレーション結果出力時にREADMEを出力する
        GoNext   = false;   % このプロパティがtrueになると現在の最終値を初期値として再シミュレーション
        do_retry            % odeソルバーが警告により途中停止した場合に再施行するかどうかを指定
    end
    

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % シミュレーション中に使用するインデックス変数(微分方程式の計算で使用) %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access=protected)
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

        % 全母線・機器・制御器のインデックスの管理
        all_Mass            % 各機器・制御器の状態数・制約変数の個数に応じて質量行列を定義しておく
        all_Uzeros          % 各機器の入力ポート数に従った零行列のcell配列を定義しておく

        % シミュレーション中の地絡・解列等を加味したインデックスの管理
        logimat = struct('x',[],'xcl',[],'xcg',[],'V',[],'I0const',[],'V0const',[]);

        % 初期値を格納
        initial = struct('x',[],'xcl',[],'xcg',[],'V',[],'I0const',[],'V0const',[]);
    end


        
    %%%%%%%%%%%%%%%%
    % オプション設定 %
    %%%%%%%%%%%%%%%%
    properties
        % 解列機器の状態を計算する(=true)　or 計算しない(=false)
        isCalculated_disconnected_mac 

        % 外部からシミュレーション条件を割り込みで入れる際に使用
        additional_V0bus  = [];     % << double(1xn) ・・・母線番号を追加すると対応する母線電圧が0(地絡状態)
        additional_I0bus  = [];     % << double(1xn) ・・・母線番号を追加すると対応する母線電流が0(機器の解列状態)
    end



%% method
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
    %%%%%%%%%%%%%%%%%%
    % コンストラクター %
    %%%%%%%%%%%%%%%%%%
    methods
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
            obj.all_Uzeros = tools.cellfun(@(b) zeros(b.component.get_nu,1), obj.network.a_bus);
        end
    end
    
    methods(Access=protected)
        % optionデータを振り分けてセットする
        set_options(obj,uidx,u,option,varargin);
    end



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ユーザーによって外部から呼び出される想定のメソッド %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
    %fault,parallel,input条件を後から追加したい場合のメソッド
        function add_fault(obj,varargin)
            obj.fault.add(varargin{:})
        end

        function add_parallel(obj,varargin)
            obj.parallel.add(varargin{:})
        end
        
        function add_input(obj,varargin)
            obj.input.add(varargin{:})
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

    % simulation終了のflagとして扱われるプロパティのメソッド
        function set.ToBeStop(obj,val)
            if val; obj.GoNext =  true; end %#ok
            obj.ToBeStop = val;
        end

    % オプション設定を構造体として出力させるメソッド
        option    = export_option(obj) 
    end


    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % シミュレーション実行の際に使用されるメソッド %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    methods
    % シミュレーションを実行するメソッド
        [out,obj] = run(obj)
        
    % タームの更新ごとに最終時刻を更新　>> fault,input,parallelのset.current_timeメソッドを実行し条件設定を更新
        function set.LastTime(obj,t)
            obj.fault.current_time    = t; %#ok
            obj.input.current_time    = t; %#ok
            obj.parallel.current_time = t; %#ok
            obj.LastTime = t;
        end
    end

    methods(Access=protected)
    % 微分方程式fxの計算で使用するパラメータのセット
        set_parameter(obj);                         

    % 状態の初期値を取得するためのメソッド
        [x0,const0] = get_initial(obj);

    % 現状のシミュレーション結果をoutとして出力
        [out,obj] = export_out(obj)    
    end



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % odeソルバーで使用する状態ベクトルを各機器の状態等に分割するメソッド %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access=protected)
    % odeソルバーで解析される機器・制御器のみの状態を取得 << 各itrationで実行されるため最低限の処理で構成
        [X,Xcl,Xcg,V,I] = organize_Xode(obj,xsys);

    % idxで指定された機器全ての状態へ拡張させるためのメソッド
        [x, xcl, xcg, V, I, Vvirtual] = expand_Xode(obj,xsys,idx_mac,idx_cl,idx_cg)
    end



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ODEソルバーのEvents/OutputFcnに代入する関数 %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access=protected)
        function [value,isterminal,direction] = Fcn_Event(obj,~,~)
            isterminal = 1;
            direction  = 0;
            value = ~obj.GoNext;
        end

        function out = Fcn_Output(obj,t,x,flag)
            obj.progress.OutputFcn(t,x,flag);
            obj.response.OutputFcn(t,x,flag);
            out = [];
        end
    end



    %%%%%%%%%%%%%%%%%%%%%%%%
    % 微分方程式を司るメソッド %
    %%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access=protected)
    % 微分方程式を定義する本体。odeソルバーの引数としてこのメソッドが使用される
        function dx = fx(obj, t, x)
            % odeソルバー用の状態xから機器/制御器ごとに状態を分割
            [X,Xcl,Xcg,V,I] = obj.organize_Xode(x);
            % 外部入力を取得
            Uinput = obj.input.get_u(t);            
            % 制御器の微分方程式
            [dxcl,Utemp] = obj.fx_controller( obj.simulated_cg, t, X, Xcg, V, I, Uinput);
            [dxcg,U    ] = obj.fx_controller( obj.simulated_cl, t, X, Xcl, V, I, Utemp );
            % 各機器の微分方程式を計算
            dxmac = obj.fx_component( obj.simulated_bus, t, X, V, I, U);
            % 返り値を作成
            dx = [vertcat(dxmac{:}) ; vertcat(dxcl{:}) ; vertcat(dxcg{:})];
        end

    % 各制御器の微分方程式を計算するメソッド
        function [dxcon,U] = fx_controller(obj, index, t, Xcomponent, Xcon, V, I, Ucon)
            dxcon = cell(numel(Xcon),1);
            U = Ucon;
            for i = index
                c = obj.network.a_controller_global{i};
                in = c.index_input;
                ob = c.index_observe;
                [dxcon{i},ucon] = c.get_dx_u_func( t, Xcon{i}, Xcomponent(ob), num2cell(V(:,ob),1), num2cell(I(:,ob),1), Ucon(ob));
                for j = 1:numel(in)
                    U{in(j)} = U{in(j)} + ucon{j};
                end
            end
        end
        
    % 各機器の微分方程式を計算するメソッド
        function dxmac = fx_component(obj, index, t, X, V, I, U)
            dxmac = cell(numel(X),1);
            for i = index
                c = obj.network.a_bus{i}.component;
                Ui = c.u_func(c,U{i});
                [dx, con] = c.get_dx_con_func( t, X{i}, V(:,i), I(:,i), Ui);
                dxmac{i} = [dx;con];
            end
        end
    end
end


