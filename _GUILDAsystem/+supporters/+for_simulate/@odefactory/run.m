function [out,obj] = run(obj)
    % タグのリセット >> ToBeStopがtrueになったらシミュレーションを中断する。
        obj.ToBeStop = false;
        obj.start_time = datetime;          % シミュレーション開始時刻（現実時間）を記録

    % 解析中にfsolveで初期値を再評価する必要が出た場合に用いるオプション
        optimoption = optimoptions('fsolve', 'MaxFunEvals', inf, 'MaxIterations', 100, 'Display','none');%'iter-detailed');
            
        obj.progress.set_OutputFcn;

    % シミュレーションが最終時刻に到達するか、ToBeStopがtrueになるまで繰り返す >> while内の１ループをフェーズと呼ぶこととする。
    while obj.LastTime < obj.time(end) && ~obj.ToBeStop

        % タグのリセット　>> GoNextがtrueになった場合次のフェーズに進む。
            obj.GoNext = false;


        % 本フェーズで計算する時間区間[t0,te]を定義
            % 前回の最終時刻を本フェーズの開始時刻とする
                t0 = obj.LastTime;
            % 本フェーズの終了時刻を取得
                te = obj.get_next_tend; 


        % 微分方程式内で使用する各パラメータの計算 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % fxメソッド内で使用する各パラメータを再定義
                obj.set_parameter;                  
            % 入力データをinputメソッド内のクラスから生成
                obj.ufunc = obj.input.get_ufunc(t0);


        % ソルバーのオプションの設定 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            Mass = blkdiag(obj.all_Mass.x{obj.simulated_bus}  ,...
                           obj.all_Mass.xcl{obj.simulated_cl} ,...
                           obj.all_Mass.xcg{obj.simulated_cg} );
            odeopt = odeset(obj.odeoptions,....
                            'OutputFcn', @obj.Fcn_Output,...
                            'Events'   , @obj.Fcn_Event ,...
                            'Mass'     , Mass);


        % solve DAE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % シミュレーションの初期値を取得
                [x0,nanidx] = obj.get_initial;
                if any(nanidx) % 初期値に欠損値があった場合にfsolveで適切な初期値を評価する
                    nan0 = x0(nanidx);
                    x0(nanidx) = fsolve(@(var) fconst(var, @obj.fx, t0, x0, nanidx), nan0, optimoption);
                end
            % odeソルバーの起動
                try
                    sol = ode15s(@obj.fx, [t0,te], x0, odeopt);
                catch
                    % 初期値に関するエラーが発生した場合の措置 >> 制約条件の代数変数の初期値をfsolveで再評価する
                    const_idx = ~diag(Mass);
                    const0 = x0(const_idx);
                    x0(const_idx) = fsolve(@(var) fconst(var, @obj.fx, t0, x0, const_idx), const0, optimoption);
                    sol = ode15s(@obj.fx, [t0,te], x0, odeopt);
                end
            % 警告でodeソルバーが途中で停止した場合にソルバーを再開させる。
                while sol.x(end)<te && obj.do_retry && ~obj.GoNext
                    sol = odextend(sol,[],te);
                end


        % 微分方程式の解をDataStorageに格納 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            net = obj.network;
            [X,Xcl,Xcg,V,I,Vvir] = obj.expand_Xode(sol.y, 1:numel(net.a_bus), 1:numel(net.a_controller_local), 1:numel(net.a_controller_global));
            obj.DataStorage.t   = [obj.DataStorage.t  , sol.x(:)'   ];
            obj.DataStorage.X   = [obj.DataStorage.X  , X(:)        ];
            obj.DataStorage.Xcl = [obj.DataStorage.Xcl, Xcl(:)      ];
            obj.DataStorage.Xcg = [obj.DataStorage.Xcg, Xcg(:)      ];
            obj.DataStorage.V   = [obj.DataStorage.V  , V(:)        ];
            obj.DataStorage.I   = [obj.DataStorage.I  , I(:)        ];
            obj.DataStorage.sol = [obj.DataStorage.sol, {sol}       ];
            obj.DataStorage.u   = [obj.DataStorage.u  , {obj.ufunc} ];


        % 次のフェーズの初期値をセット
            obj.initial.x   = tools.cellfun(@(c) c(:,end), X  );
            obj.initial.xcl = tools.cellfun(@(c) c(:,end), Xcl);
            obj.initial.xcg = tools.cellfun(@(c) c(:,end), Xcg);
            obj.initial.V   = tools.cellfun(@(c) c(:,end), V  );
            obj.initial.I0const(obj.I0const_bus) = tools.arrayfun(@(i) Vvir{i}(:,end), obj.I0const_bus);
            obj.initial.V0const(obj.V0const_bus) = tools.arrayfun(@(i)    I{i}(:,end), obj.V0const_bus);


        % このフェーズのシミュレーションの最終時間を記録 %%%%%%%%%%%%%%%%%%%%%%%%%%
            obj.LastTime = sol.x(end);

    end

    out = obj.export_out;
end


function con = fconst(var, func, t, xall, const_idx)
    xall(const_idx) = var;
    dx_all = func(t,xall);
    con  = dx_all(const_idx);
end
