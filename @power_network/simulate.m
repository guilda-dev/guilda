function out = simulate(obj, t, varargin)

% option設定の整理
    if nargin < 3 || isstruct(varargin{1}) || ischar(varargin{1})
        options = obj.simulate_options(t,[],[],varargin{:});
    else
        u = varargin{1};
        idx_u = varargin{2};
        options = obj.simulate_options(t,u,idx_u,varargin{3:end});
    end

%シミュレーションの準備

    % シミュレーションの時間区間を整理する
    ftime = tools.structfun(@(x) x.time(:)', options.fault(:)');
    utime = tools.structfun(@(x) x.time(:)', options.u(:)');
    timelist = sort(unique([t(:)',ftime,utime]));
    timelist = timelist(timelist>=t(1)&timelist<=t(end));

    % 状態の初期値の取得
    xmac = options.x0_sys(:);
    xcl  = options.x0_con_local(:);
    xcg  = options.x0_con_global(:);
    V    = options.V0(:);
    I    = options.I0(:);
    Vvir = nan(2*numel(obj.a_bus),1);
    if ~isreal(V); V = tools.complex2vec(V); end
    if ~isreal(I); I = tools.complex2vec(I); end

    % odeソルバーに代入する「微分代数方程式」「OutpuFcn」「EventFcn」を定義するために必要なクラスの定義
    uidx    = tools.structfun(@(x) x.bus(:)',options.u(:)');
    holder  = tools.for_simulate.state_holder(obj);
    odefunc = tools.for_simulate.odefunc_factory(obj,options.linear,holder);
    checker = tools.for_simulate.GridCode_checker(obj,t,holder,options.grid_code,options.OutputFcn.Gridcode);
    
    % Outputfunctionについて整理する
    OutputFcn = [];
    if ~isempty(options.OutputFcn.Gridcode)
        OutputFcn = [OutputFcn,{@checker.live}];
        options.do_report = false;
    end
    if ~isempty(options.OutputFcn.Response)
        res = tools.for_simulate.Response_reporter(t,obj,holder,options.OutputFcn.Response);
        OutputFcn = [OutputFcn,{@res.plotFcn}];
        options.do_report = false;
    end
    if ~isempty(options.OutputFcn.other)
        OutputFcn = [OutputFcn,options.OutputFcn.other];
    end
    reporter= tools.for_simulate.Reporter(timelist(1),timelist(end), options.do_report, OutputFcn);

    % シミュレーションの実行
    odeout = struct;
    for tidx  = 1:numel(timelist)-1 % 各時間区間ごとに区切りfor文で回す
        t0    = timelist(tidx);     % 対象の時間区間の開始時刻
        tend  = timelist(tidx+1);   % 対象の時間区間の終了時間
        retry = true;               % 下のwhile文に使用するタグの定義：ode solverがtendまで求解できるとretry=falseとなり次のforループに進む
        while retry                 % １つの時間区間中に機器の解列などでsolverが中断された場合，システムを構築し直しサイドodeを実行する
            u0 = get_u(t0,options.u,options.method);                            % 対象の時間区間の開始時における入力の値を計算
            switch options.method
                case 'zoh'
                    func = @(t,x) odefunc.fx(t,x,u0);                           % zoh(0次ホールド)の場合，対象の時間区間ではu0で一定となる
                case 'foh'
                    u1 = get_u(tend,options.u,options.method);                  % 対象の時間区間の終了時における入力の値を計算
                    dudt = (u1-u0)/(tend-t0);
                    func = @(t,x) odefunc.fx(t,x,u0+dudt*(t-t0));   % foh(1次ホールド)の場合，対象の時間区間ではtに応じたu0とu1の内分点となる．
            end
    
            fbus = get_faultbus(timelist(tidx), options.fault);                 % 対象の時間区間において地絡が起きている母線番号を取得
            Mf   = odefunc.SimulationSetting(fbus,uidx);                        % odefuncクラスの初期設定を行う．出力としてodeソルバーで扱う微分代数方程式の微分方程式部分と代数方程式の部分を指定する質量行列を取得する
            r    = @(t, y, flag) reporter.report(t, y, flag, options.reset_time, datetime); %reporterクラスからodeソルバーに投げるOutputFcnを取得する．command window上の進行度の表示やシミュレーション時間の制限時間などを司る
            [Y,Yrep] = odefunc.get_Ymat_reproduce;
            holder.Ymat = Y;
            holder.Yreproduced = Yrep;
            E    = @(t, y, flag) checker.EventFcn(t);
            odeoptions = odeset('Mass',Mf, 'RelTol', options.RelTol, 'AbsTol', options.AbsTol, 'OutputFcn', r, 'Events',E);  % ode15sに適したoption型に整形する
    
            [x0,const0] = odefunc.reshape_allX2initX(xmac(:,end), xcl(:,end), xcg(:,end), V(:,end), I(:,end), Vvir(:,end)); % 初期値を取得する
            try
                sol  = ode15s(func, [t0,tend], [x0;const0], odeoptions);                                                            % odeソルバーの実行 
            catch
                constfunc = @(var) get_const(func,t0,x0,var,~any(Mf,2));
                msg = 'Recalculate consistent initial values due to an error in the ode solver.';
                disp([repmat('#',1,length(msg)+4),newline,'  ',msg,newline,repmat('#',1,length(msg)+4)])
                option = optimoptions('fsolve', 'MaxFunEvals', inf, 'MaxIterations', 100, 'Display','iter-detailed');
                const0 = fsolve(constfunc, const0, option);
                sol  = ode15s(func, [t0,tend], [x0;const0], odeoptions);
            end
            while (sol.x(end)<tend) && options.do_retry && ~reporter.reset && ~checker.is_changed                            %　上の行のode15sでtendまで求解が終わらなかった際にretryする
                r   = @(t, y, flag) reporter.report(t, y, flag, options.reset_time, datetime);
                odeoptions = odeset(odeoptions, 'OutputFcn', r);
                sol = odextend(sol, [], tend, sol.y(:,end),odeoptions);
            end

            % 求解出来たデータを整形しデータを格納しておく
            outi = numel(odeout)+1;
            [xmac, xcl, xcg, V, I, Vvir] = odefunc.reshape_odeX2allX(sol.y);
            odeout(outi).Xmac    = xmac;
            odeout(outi).Xcl     = xcl;
            odeout(outi).Xcg     = xcg;
            odeout(outi).Vall    = V;
            odeout(outi).Iall    = I;
            odeout(outi).Vvirtual= Vvir;
            odeout(outi).time    = sol.x(:)';
    
            t0 = sol.x(end);
            retry = t0<tend && checker.is_changed && ~reporter.reset;
        end
    end

    % 全ての時間区間での求解が終わった後，それぞれのデータを結合する．
    Xmac = tools.hcellfun(@(x) x, {odeout.Xmac});
    Xcl  = tools.hcellfun(@(x) x, {odeout.Xcl });
    Xcg  = tools.hcellfun(@(x) x, {odeout.Xcg });
    V    = tools.hcellfun(@(x) x, {odeout.Vall});
    I    = tools.hcellfun(@(x) x, {odeout.Iall});
    t    = tools.hcellfun(@(x) x, {odeout.time});

    nbus = numel(obj.a_bus);
    [lx,lxcl,lxcg,lu] = odefunc.get_state_idx;
    
    % 結合したデータを出力"out"に構造体として格納していく
    out = struct();
    out.linear= options.linear;
    out.fault = options.fault;
    out.input = struct;
    out.input.list = options.u;
    out.t = t(:);
    out.V = tools.arrayfun(@(i) V(2*i+[-1,0],:).', (1:nbus)');
    out.I = tools.arrayfun(@(i) I(2*i+[-1,0],:).', (1:nbus)');
    out.X = tools.arrayfun(@(i) Xmac(lx(:,i),:).', (1:nbus)');
    out.Xcon = struct;
    out.Xcon.local  = tools.arrayfun(@(i) Xcl(lxcl(:,i),:).', (1:numel(obj.a_controller_local ))');
    out.Xcon.global = tools.arrayfun(@(i) Xcg(lxcg(:,i),:).', (1:numel(obj.a_controller_global))');
    out.Ucon = struct;
    out.Ucon.local     = cell(numel(obj.a_controller_local), 1);
    out.Ucon.global    = cell(numel(obj.a_controller_global), 1);
    out.CostFcn = struct;
    out.CostFcn.bus       = cell(nbus,1);
    out.CostFcn.component = cell(nbus,1);
    out.CostFcn.branch    = cell(numel(obj.a_branch),1);
    out.CostFcn.controller_local  = cell(numel(obj.a_controller_local), 1);
    out.CostFcn.controller_global = cell(numel(obj.a_controller_global), 1);

    U_bus  = tools.arrayfun(@(i) zeros(numel(out.t), obj.a_bus{i}.component.get_nu()), (1:nbus)');
    U_bus0 = tools.arrayfun(@(i) zeros(numel(out.t), obj.a_bus{i}.component.get_nu()), (1:nbus)');
    for i = 1:numel(obj.a_controller_global)
        c = obj.a_controller_global{i};
        out.Ucon.global{i}  = c.get_input_vectorized(out.t, out.Xcon.global{i}, out.X(c.index_observe), out.V(c.index_observe),out.I(c.index_observe), U_bus0(c.index_observe));
        out.CostFcn.controller_global{i}= c.get_cost_vectorized(out.t, out.Xcon.global{i}, out.X(c.index_observe), out.V(c.index_observe),out.I(c.index_observe), U_bus0(c.index_observe));

        idx = 0;
        for j = 1:numel(c.index_input)
            nu = size(U_bus{j}, 2);
            U_bus{j} = U_bus{j} + out.Ucon.global{i}(:, idx+(1:nu));
            idx = idx + nu;
        end
    end

    for i = 1:numel(obj.a_controller_local)
        c = obj.a_controller_local{i};
        out.Ucon.local{i}   = c.get_input_vectorized(out.t, out.Xcon.local{i}, out.X(c.index_observe), out.V(c.index_observe),out.I(c.index_observe), U_bus(c.index_observe));
        out.CostFcn.controller_local{i}= c.get_cost_vectorized(out.t, out.Xcon.local{i}, out.X(c.index_observe), out.V(c.index_observe),out.I(c.index_observe), U_bus(c.index_observe));

        idx = 0;
        for j = 1:numel(c.index_input)
            nu = size(U_bus{j}, 2);
            U_bus{j} = U_bus{j} + out.Ucon.global{i}(:, idx+(1:nu));
            idx = idx + nu;
        end
    end
    out.input.data.from_controller = U_bus;
    uall = tools.varrayfun(@(t) reshape(get_u(t,options.u,options.method),1,[]), out.t);
    for i = 1:numel(uidx)
        U_bus0{uidx(i)} = U_bus0{uidx(i)} + uall(:,lu(:,i));
        U_bus{uidx(i)}  = U_bus{uidx(i)}  + uall(:,lu(:,i));
    end
    out.input.data.from_User = U_bus0;
    out.input.data.Total     = U_bus;


    for i = 1:nbus
        b = obj.a_bus{i};
        c = b.component;
        out.CostFcn.bus{i}      = b.get_cost_vectorized(out.t,out.V{i},out.I{i});
        out.CostFcn.component{i}= c.get_cost_vectorized(out.t,out.X{i},out.V{i},out.I{i},U_bus{i});
    end

    for i = 1:numel(obj.a_branch)
        b = obj.a_branch{i};
        out.CostFcn.branch{i}    = b.get_cost_vectorized(out.t,out.V{b.from},out.V{b.to});
    end

    if options.tools
        out = tools.for_simulate.simulationResult(out,obj,false);
    end
    
end


function uout = get_u(t,u,method)
    if isempty(u)
        uout = [];
    else
        switch method
            case 'zoh'
                fu = @(t,tlim,udata) udata(:,1);
            case 'foh'
                fu = @(t,tlim,udata) udata(:,1) + diff(udata,1,2)/diff(tlim)*(t-tlim(1));
        end
        udata = cell(numel(u),1);
        for i=1:numel(u)
            tlist = u(i).time;
            s = find(tlist<=t,1,'last' );
            e = find(tlist>=t,1,'first');
            if s==e
                udata{i} = u(i).u(:,s);
            else
                udata{i} = fu(t, [tlist(s),tlist(e)],[u(i).u(:,s),u(i).u(:,e)]);
            end
        end
        uout = vertcat(udata{:});
    end
end

function fault_bus = get_faultbus(t,fault)
    is_fault  = tools.structfun(@(x) t>=x.time(1) && t<x.time(end) , fault);
    fault_bus = tools.harrayfun(@(i) fault(i).bus(:)', find(is_fault));
    fault_bus = unique(fault_bus);
end

function dconst = get_const(f,t,x0,const,idx)
    dx = f(t,[x0;const]);
    dconst = dx(idx);
end