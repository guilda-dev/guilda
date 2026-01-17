
classdef odefactory < handle
    properties(SetAccess=protected)
        Network
        Buses
        Components
        Controllers
    end
    
    methods
        function obj = odefactory(Network)
            arguments
                Network (1,1) power_network
            end
            obj.Network = Network;
            obj.Buses = net.Buses;
            obj.Components  = [net.Branches;net.Buses];
            obj.Controllers = [net.LocalControllers;net.GlobalControllers];
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% シミュレーション中に使用する一時的な変数群 %%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(SetAccess=private)
        Solt             (1,:) table
        SolX             (:,:) table
        SolU             (:,:) table
        SolY             (:,:) table
        SolV             (:,:) table
        SolW             (:,:) table
        SolConstraint    (:,:) table
        SolParallel      (1,:) table
    end 
    properties(Access=private)
        IndexData        (1,1) double  % サンプリング数のカウント

        CashSolTime      (1,:) double  %  =
        CashSolX         (:,:) double  %  |
        CashSolU         (:,:) double  %  |
        CashSolY         (:,:) double  %  | 
        CashSolV         (:,:) double  % 各ターム毎に応答結果データを保存しておくキャッシュ
        CashSolW         (:,:) double  % 保存データを下のCashName~の変数名をセットにtableに変換
        CashSolUcon      (:,:) double  % tableに変換したデータ上のSol~に追加ていく
        CashSolUusr      (:,:) logical %  | 
        CashSolConst     (:,:) logical %  |
        CashParallel     (1,:) logical %  =

        CashNameX       (1,:) string  %  =
        CashNameU       (1,:) string  %  |
        CashNameY       (1,:) string  % 各タームの終了時にCash~のデータをtable型に変換する際に使用
        CashNameV       (1,:) string  %  |
        CashNameW       (1,:) string  %  |
        CashNameConst   (1,:) string  %  =

        InitX            (:,1) double  % シミュレーション開始時の初期値
        IndexX           (:,1) double  % 系統全体の状態が代入された際に自身の機器の状態Xのみを抜き出す際に使用
        IndexU           (:,1) double  % 系統全体の状態が代入された際に自身の機器の入力Uのみを抜き出す際に使用
        IndexY           (:,1) double  % 系統全体の状態が代入された際に自身の機器の入力Vのみを抜き出す際に使用
        IndexV           (:,1) double  % 系統全体の状態が代入された際に自身の機器の入力Vのみを抜き出す際に使用
        IndexW           (:,1) double  % 系統全体の状態が代入された際に自身の機器の入力Vのみを抜き出す際に使用

    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% シミュレーション中に使用する関数 %%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        OdeSet
        Reporter       = supporters.for_simulate.reporter;
        Dialog         (1,1) string 
        SimulationTime (1,2) double = [0,inf];
        DisplayCondition
    end

    methods
        function set.SimulationTime(obj,time)
            tspan = [time(1),time(2)];
            assert(diff(tspan)>0, config.lang('シミュレーション時間の終了時間は開始時間より大きい必要があります。','The end time of the simulation time must be bigger than the start time.'))
            obj.SimulationTime = tspan;
            obj.Reporter.SimulationTime = tspan;%#ok
        end
        % クラス生成時に実行。さらにシミュレーション開始時にも再実行
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function initialize(obj,time,OdeSet,Display,Dialog,TimeLimit)
            obj.Solt = [];
            obj.SolX = [];
            obj.SolU = [];
            obj.SolY = [];
            obj.SolV = [];
            obj.SolW = [];
            obj.SolConstraint = [];
            obj.SolParallel   = [];

            obj.SimulationTime = time;
            obj.DisplayCondition = Display;

            rep = obj.Reporter;
            obj.OdeSet = odeset(OdeSet,"OutputFcn",@(t) rep.OutputFcn(t) );
            rep.initilize( TimeLimit, Dialog);
        end

        % シミュレーションのターム毎の開始時に実行
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [x0,te,Numel] = initialize_term(obj,net,t0)
            Index = struct('x',0,'u',0,'y',0,'v',0,'w',0);
            
            cellfun(@(cls) cls.initialize_ode(t0,), obj.Buses);

            % 関数を取得
            cls.initialize_ode
            % 変数名を保存
            obj.CashNameX = cls.get_name("x");
            obj.CashNameU = cls.get_name("u");
            obj.CashNameY = cls.get_name("y");
            obj.CashNameV = cls.get_name("v");
            obj.CashNameW = cls.get_name("w");
            obj.CashNameConst = cls.get_name("odeConst");
            % 引数Nameから要素数を抽出
            Numel.x = numel(obj.CashNameX);
            Numel.u = numel(obj.CashNameU);
            Numel.y = numel(obj.CashNameY);
            Numel.v = numel(obj.CashNameV);
            Numel.w = numel(obj.CashNameW);
            % 引数のIndexからインデックスを作成
            obj.IndexX = Index.x + (1:Numel.x);
            obj.IndexU = Index.u + (1:Numel.u);
            obj.IndexY = Index.y + (1:Numel.y);
            obj.IndexV = Index.v + (1:Numel.v);
            obj.IndexW = Index.w + (1:Numel.w);
            % 解軌道を格納しておくためのプロパティをリセット
            obj.IndexData   = 1;
            obj.CashSolTime = zeros(1,0);
            obj.CashSolX    = zeros(Numel.x,0);
            obj.CashSolU    = zeros(Numel.u,0);
            obj.CashSolY    = zeros(Numel.y,0);
            obj.CashSolV    = zeros(Numel.v,0);
            obj.CashSolW    = zeros(Numel.w,0);
            obj.CashSolUcon = zeros(Numel.u,0);
            obj.CashSolUusr = zeros(Numel.u,0);
            obj.CashSolConst= zeros(numel(obj.CashNameConst),0);
            % 次のターム終了時の時刻を返す
            x0 = obj.InitX;
            te = inf;
            zoh   = zeros(Numel.u,1);
            foh0  = zeros(Numel.u,1);
            fohd  = zeros(Numel.u,1);
            Fcn   = {};
            for i = numel(obj.SettingInput)
                Inputi = obj.SettingInput(i);
                time = Inputi.time;
                idxu = Inputi.index;
                valu = Inputi.u;
                idx0 = find(time> t0, 1,"first");
                idxe = find(time<=t0, 1,"last");
                if ~isempty([idx0,idxe])
                    switch Inputi.method
                    case "zoh"
                        zoh = zoh + idxu * valu(:,idx0);
                        te = min(te,time(idxe));
                    case "foh"
                        t0i = time(idx0);
                        tei = time(idxe);
                        foh0 = foh0 + idxu * valu(:,idx0);
                        fohd = fohd + idxu *(valu(:,idxe)-valu(:,idx0))/(tei-t0i);
                        te = min(te,tei);
                    otherwise
                        Fcni = @(t) idxu * spline(time,valu,t);
                        Fcn  = [Fcn,{Fcni}];%#ok
                    end                    
                end
            end
            ust = obj.ManagedClass.u_equilibrium;
            switch obj.FlagInput+"_"+isempty(Fcn)
                case "value_false"
                    obj.FcnInput = @(t)  zoh + foh0+(t-t0)*fohd + sum(tools.hcellfun(@(f) f(t),Fcn),2);
                case "add_false"
                    obj.FcnInput = @(t)  zoh + foh0+(t-t0)*fohd + sum(tools.hcellfun(@(f) f(t),Fcn),2) + ust;
                case "rate_false"
                    obj.FcnInput = @(t)  zoh + foh0+(t-t0)*fohd + sum(tools.hcellfun(@(f) f(t),Fcn),2)*ust + ust;
                case "value_true"
                    obj.FcnInput = @(t)  zoh + foh0+(t-t0)*fohd;
                case "add_true"
                    obj.FcnInput = @(t)  zoh + foh0+(t-t0)*fohd + ust;
                case "rate_true"
                    obj.FcnInput = @(t) (zoh + foh0+(t-t0)*fohd)*ust + ust;
            end
        end

        % シミュレション中のOutputFcnオプション中に実行する関数
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function outputFcn(obj,t, x, u, y, v, w)
            const    = obj.FcnConstraint(t,x,u,y,v,w);
            parallel = obj.ManagedClass.isParallel=="on";
            % 1000サンプリング毎にキャッシュを確保
            i = obj.IndexData;
            if mod(i,1000)==1 
                expand = @(mat) [mat,nan(size(mat,1),1000)];
                obj.CashSolTime  = expand( obj.CashSolTime );
                obj.CashSolX     = expand( obj.CashSolX    );
                obj.CashSolU     = expand( obj.CashSolU    );
                obj.CashSolY     = expand( obj.CashSolY    );
                obj.CashSolV     = expand( obj.CashSolV    );
                obj.CashSolW     = expand( obj.CashSolW    );
                obj.CashSolConst = expand( obj.CashSolConst);
                obj.CashParallel = expand( obj.CashParallel);
            end
            % データをキャッシュ用のプロパティに格納
            obj.CashSolTime(:,i) = t;
            obj.CashSolX(:,i)    = x;
            obj.CashSolU(:,i)    = usum;
            obj.CashSolY(:,i)    = y;
            obj.CashSolV(:,i)    = v;
            obj.CashSolW(:,i)    = w;
            obj.CashSolUcon(:,i) = ucon;
            obj.CashSolUusr(:,i) = uusr;
            obj.CashSolConst(:,i)= const;
            obj.CashParallel(:,i)= parallel;
        end

        % タームの終了毎に実行される関数
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
        function terminate_term(obj)
            % キャッシュ内のデータを変数名とともにtable型に変換し
            Solt_term = array2table( obj.CashSolTime(:,1:obj.IndexData),      "RowNames","Time");
            SolX_term = array2table( obj.CashSolX(:,1:obj.IndexData),         "RowNames",obj.CashNameX);
            SolU_term = array2table( obj.CashSolU(:,1:obj.IndexData),         "RowNames",obj.CashNameU);
            SolY_term = array2table( obj.CashSolY(:,1:obj.IndexData),         "RowNames",obj.CashNameY);
            SolV_term = array2table( obj.CashSolV(:,1:obj.IndexData),         "RowNames",obj.CashNameV);
            SolW_term = array2table( obj.CashSolW(:,1:obj.IndexData),         "RowNames",obj.CashNameW);
            SolConst_term = array2table( obj.CashSolConst(:,1:obj.IndexData), "RowNames",obj.CashNameConst);
            Parallel_term = array2table( obj.CashParallel(:,1:obj.IndexData), "RowNames","Parallel");
            % Sol~プロパティに追加する
            obj.Solt     = add(obj.Solt, Solt_term);
            obj.SolX     = add(obj.SolX, SolX_term);
            obj.SolU     = add(obj.SolU, SolU_term);
            obj.SolY     = add(obj.SolY, SolY_term);
            obj.SolV     = add(obj.SolV, SolV_term);
            obj.SolW     = add(obj.SolW, SolW_term);
            obj.SolConstraint = add(obj.SolConstraint,SolConst_term);
            obj.SolParallel   = add(obj.SolParallel,  Parallel_term);
            function tab = add(tab0,tab)
                if  ~isempty(tab0)
                    tab = outerjoin(tab0,tab);
                end
            end
            obj.InitX = obj.CashSolX(:,end);
        end

        %シミュレーション終了時に実行される関数
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
        function [X,U,Y,V,W,Constraint,Parallel] = export(obj)
            % データの出力
            X = tabtrans(obj.SolX);
            U = tabtrans(obj.SolU);
            Y = tabtrans(obj.SolY);
            V = tabtrans(obj.SolV);
            W = tabtrans(obj.SolW);
            Constraint = tabtrans(obj.SolConstraint);
            Parallel   = tabtrans(obj.SolParallel);
            % 入力データの内，”1time”のものはシミュレーション終了時に削除する
            remidx = tools.varrayfun(@(i) obj.IndexData(i).lifetime=="1time", 1:numel(obj.IndexData));
            obj.IndexData(remidx) = [];

            function out = tabtrans(tab)
                var = tab.Properties.RowNames;
                out = array2table( tab.Variables.', "VariableNames",var);
            end
        end
    end

end