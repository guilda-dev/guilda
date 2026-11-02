% net.simulate の挙動と性能の実測スクリプト (結果: notes/simulate-review-measurements.md)
%
% ファイル名に "-" を含むので run() では実行できない。リポジトリのルートで、
% 有効な名前に複製してから実行する (リポジトリには何も書き込まない):
%
%   matlab -batch "copyfile('notes/simulate-review-measurements.m', fullfile(tempdir,'simreview.m')); addpath(tempdir); simreview"
%
% 環境変数 SIMREVIEW_SECTIONS で節を選べる (例: "3,4"。既定は全節 1〜6)。
% 全節で 30〜60 分かかる。結果は標準出力に "|" 区切りで表示する。
%
%   1 性能 / 2 ボトルネック / 3 編集検知 / 4 再現性と副作用 / 5 引数と境界 / 6 精度の整合

warning("off", "backtrace");
evalc("try; GUILDA; catch; end");
str_sec = getenv("SIMREVIEW_SECTIONS");
if strlength(str_sec) == 0
    str_sec = "1,2,3,4,5,6";
end
rv_sec = str2double(split(string(str_sec), ","));

fprintf("# MATLAB %s / %s\n", version, computer);
fprintf("# 測定日 %s, CPU論理数 %d\n", string(datetime("today")), feature("numcores"));
print_load("開始時");

if ismember(1, rv_sec), section_performance(); end
if ismember(2, rv_sec), section_bottleneck();  end
if ismember(3, rv_sec), section_edit();        end
if ismember(4, rv_sec), section_side_effects(); end
if ismember(5, rv_sec), section_arguments();   end
if ismember(6, rv_sec), section_accuracy();    end


%% 共通
function print_load(str)
    [~, txt] = system("uptime");
    fprintf("# 負荷 (%s): %s\n", str, strip(string(regexp(txt, "load averages?:.*", "match", "once"))));
end

function net = build(str_net, opt)
    arguments
        str_net (1,1) string
        opt.LC  (1,1) logical = true
        opt.AGC (1,1) logical = false
        opt.Init (1,1) logical = true
    end
    if str_net == "IEEE14bus"      % IEEE14bus は制御器なしで、LocalController オプションを持たない
        net = network.IEEE14bus();
        if opt.LC
            add_avr_pss(net);
        end
    else
        net = network.(str_net)(LocalController=opt.LC);
    end
    net.solver_ODE.Progress = "none";
    net.solver_ODE.TimeLimit = Inf;
    if opt.AGC
        net.add_global_controller(controller.agc.broadcast_PI_AGC(net, "agc", "SG1B001", "SG1B002"));
    end
    if opt.Init
        init(net);
    end
end

function add_avr_pss(net)
    % 全発電機に既定値の AVR_ST1 と PSS1 を付ける
    for i = 1:numel(net.a_Bus)
        cm = net.a_Bus{i}.a_Component;
        for j = 1:numel(cm)
            if isa(cm{j}, "component.generator.abstract")
                cm{j}.add_local_controller(controller.avr.AVR_ST1("avr"+i), controller.pss.PSS1("pss"+i));
            end
        end
    end
end

function init(net)
    evalc("net.initialize()");
end

function ev = fault(net, str_bus, tspan)
    arguments
        net
        str_bus (1,1) string = string(net.a_Bus{1})
        tspan = [1, 1.05]
    end
    ev = odeEventSet("fault", net, "TimeSpan", tspan, "FaultBus", str_bus);
end

function t = median_time(fcn, n)
    rv = zeros(n,1);
    for k = 1:n
        t0 = tic;
        fcn();
        rv(k) = toc(t0);
    end
    t = median(rv);
end

function c = kv(varargin)
    c = varargin;
end

function [n_rhs, n_jac, n_out, p] = profile_counts(fcn)
    profile("clear");
    profile("on");
    fcn();
    profile("off");
    p = profile("info");
    names = string({p.FunctionTable.FunctionName});
    % 無名関数のラッパー (@(t,x)...) も名前に含むので除く
    lv_real = ~contains(names, "@(");
    n_rhs = sum([p.FunctionTable(lv_real & contains(names, "getODEFunction")).NumCalls]);
    n_jac = sum([p.FunctionTable(lv_real & contains(names, "getODEJacobian")).NumCalls]);
    n_out = sum([p.FunctionTable(lv_real & contains(names, "time_keeper")).NumCalls]);
end


%% 1 性能
function section_performance()
    fprintf("\n## 1 性能\n");
    fprintf("条件: time=[0,10] (Case 14-long のみ [0,100]), fault は FaultBus=先頭母線, TimeSpan=[1,1.05], Tolerance/AbsoluteTolerance は既定, Progress=none\n");
    fprintf("solver 列: ode15s と ode23t は Solver= のみ指定。ode23t* は Solver=ode23t と SolverOptions=ODE23t の両方を指定 (5-4 参照)\n");
    % net, LC, AGC, 事象, Solver, 反復数, TimeLimit
    c_case = { ...
        "IEEE9bus",  true,  false, true,  "ode15s", 5, Inf; ...
        "IEEE9bus",  true,  false, false, "ode15s", 5, Inf; ...
        "IEEE9bus",  true,  false, true,  "ode23t", 5, Inf; ...
        "IEEE9bus",  true,  false, false, "ode23t", 5, Inf; ...
        "IEEE9bus",  true,  false, true,  "ode23t*", 5, Inf; ...
        "IEEE9bus",  true,  false, false, "ode23t*", 5, Inf; ...
        "IEEE9bus",  false, false, true,  "ode15s", 5, Inf; ...
        "IEEE14bus", true,  false, true,  "ode15s", 5, Inf; ...
        "IEEE14bus", true,  false, false, "ode15s", 5, Inf; ...
        "IEEE14bus", true,  false, true,  "ode23t", 5, Inf; ...
        "IEEE14bus", true,  false, true,  "ode23t*", 5, Inf; ...
        "IEEE14bus", false, false, true,  "ode15s", 5, Inf; ...
        "IEEE14bus", true,  true,  true,  "ode15s", 5, Inf; ...
        "IEEE68bus", true,  false, true,  "ode15s", 3, Inf; ...
        "IEEE68bus", true,  false, false, "ode15s", 3, Inf; ...
        "IEEE68bus", true,  false, true,  "ode23t", 3, Inf; ...
        "IEEE68bus", true,  false, true,  "ode23t*", 3, Inf; ...
        "IEEE68bus", false, false, true,  "ode15s", 3, 120};
    fprintf("net|LC|AGC|fault|solver|n_var|init中央値[s]|sim初回[s]|sim中央値[s]|sim最小[s]|sim最大[s]|flag|tEnd|n_t|nRHS|nJac|nOutFcn|ms/RHS換算|rm_variable+rm_I+rv_t[MB]|byteStream[MB]|odeResults表示[s]\n");
    for i = 1:size(c_case,1)
        [str_net, l_lc, l_agc, l_ev, str_sol, n, r_tl] = c_case{i,:};
        try
            t_init = median_time(@() build(str_net, LC=l_lc, AGC=l_agc), n) ...
                   - median_time(@() build(str_net, LC=l_lc, AGC=l_agc, Init=false), n);
            net = build(str_net, LC=l_lc, AGC=l_agc);
            if l_ev
                c_ev = {fault(net)};
            else
                c_ev = {};
            end
            c_sol = kv("Solver", str_sol);
            if str_sol == "ode23t*"
                c_sol = kv("Solver", "ode23t", "SolverOptions", matlab.ode.options.ODE23t);
            end
            run = @() net.simulate([0,10], c_ev{:}, c_sol{:}, TimeLimit=r_tl);
            t0 = tic; run(); t_first = toc(t0);
            rv = zeros(n,1);
            for k = 1:n
                t0 = tic;
                [sol, flag, output] = run();
                rv(k) = toc(t0);
            end
            [n_rhs, n_jac, n_out] = profile_counts(run);
            mb = 8*(numel(sol.rm_variable)+numel(sol.rm_I)+numel(sol.rv_t))/1e6;
            bs = numel(getByteStreamFromArray(sol))/1e6;
            t0 = tic; r = sol.odeResults; t_view = toc(t0); %#ok
            fprintf("%s|%d|%d|%d|%s|%d|%.3f|%.3f|%.3f|%.3f|%.3f|%d|%g|%d|%d|%d|%d|%.3f|%.3f|%.2f|%.3f\n", ...
                str_net, l_lc, l_agc, l_ev, str_sol, size(sol.rm_variable,2), t_init, t_first, median(rv), min(rv), max(rv), ...
                flag, output.tEnd, numel(sol.rv_t), n_rhs, n_jac, n_out, 1e3*median(rv)/max(n_rhs,1), mb, bs, t_view);
        catch me
            fprintf("%s|%d|%d|%d|%s|ERROR %s: %s\n", str_net, l_lc, l_agc, l_ev, str_sol, me.identifier, first_line(me.message));
        end
    end

    % 他プロセスの負荷の影響を受けにくい条件: 計算スレッド 1
    print_load("1 スレッド測定の前");
    n0 = maxNumCompThreads(1);
    for str_net = ["IEEE14bus","IEEE68bus"]
        net = build(str_net);
        ev  = fault(net);
        run = @() net.simulate([0,10], ev);
        run();
        rv = zeros(5,1);
        for k = 1:5
            t0 = tic; run(); rv(k) = toc(t0);
        end
        fprintf("1スレッド %s fault ode15s: 中央値 %.3f s, 最小 %.3f, 最大 %.3f (5回)\n", str_net, median(rv), min(rv), max(rv));
    end
    maxNumCompThreads(n0);
    print_load("1 スレッド測定の後");

    % 模擬時間を伸ばしたとき
    net = build("IEEE14bus");
    run = @() net.simulate([0,100], fault(net), Solver="ode15s");
    run();
    t = median_time(run, 5);
    [sol, ~, ~] = run();
    fprintf("14-long time=[0,100]: 中央値 %.3f s, n_t=%d, 結果 %.3f MB\n", t, numel(sol.rv_t), 8*(numel(sol.rm_variable)+numel(sol.rm_I)+numel(sol.rv_t))/1e6);

    % 既定の TimeLimit=10 s が大規模系統で効くか
    net = network.IEEE68bus();
    net.solver_ODE.Progress = "none";
    init(net);
    fprintf("既定 TimeLimit = %g s (IEEE68, 新規ネットワーク)\n", net.solver_ODE.TimeLimit);
    for r_end = [10, 30]
        [txt, sol, flag, output] = capture_sim(@() net.simulate([0,r_end], fault(net)));
        fprintf("  time=[0,%g]: flag=%d tEnd=%g 表示出力=%d文字 message=%s\n", r_end, flag, output.tEnd, strlength(strtrim(txt)), output.message);
        clear sol
    end

    % Jacobian の疎性 (odeSimulator は密行列を返す)
    for str_net = ["IEEE9bus","IEEE14bus","IEEE68bus"]
        net = build(str_net);
        res = net.linearize();
        J = [res.rm_Axx, res.rm_Axv; res.rm_Avx, res.rm_Avv];
        fprintf("疎性 %s: 線形化ブロック [Axx Axv;Avx Avv] %dx%d, 非零率 %.1f%%\n", str_net, size(J,1), size(J,2), 100*nnz(J)/numel(J));
    end
end

function [txt, sol, flag, output] = capture_sim(fcn)
    sol = []; flag = NaN; output = struct();
    txt = evalc("[sol, flag, output] = fcn();");
end


%% 2 ボトルネック
function section_bottleneck()
    fprintf("\n## 2 ボトルネック\n");
    fprintf("条件: time=[0,10], fault 先頭母線 [1,1.05], ode15s, 既定 Tolerance, profile は1回 (ウォームアップ1回の後)\n");
    for str_net = ["IEEE14bus","IEEE68bus"]
        net = build(str_net);
        ev  = fault(net);
        run = @() net.simulate([0,10], ev);
        run();
        t0 = tic; sol = run(); t_plain = toc(t0);
        [n_rhs, n_jac, ~, p] = profile_counts(run);
        ft = p.FunctionTable;
        names = string({ft.FunctionName});
        total = [ft.TotalTime];
        selft = zeros(size(total));
        for k = 1:numel(ft)
            ch = ft(k).Children;
            selft(k) = total(k) - sum([ch.TotalTime]);
        end
        [~, iv_root] = max(total);
        t_all = total(iv_root);
        fprintf("### %s: プロファイラなし %.3f s, プロファイラあり %.3f s (root=%s), nRHS=%d, nJac=%d, r_elapsed=%.3f\n", ...
            str_net, t_plain, t_all, names(iv_root), n_rhs, n_jac, sol.r_elapsed);
        fprintf("self順位|関数|呼出数|self[s]|self[%%]|total[s]\n");
        [~, iv] = sort(selft, "descend");
        for k = 1:min(25, numel(iv))
            m = iv(k);
            fprintf("%d|%s|%d|%.3f|%.1f|%.3f\n", k, names(m), ft(m).NumCalls, selft(m), 100*selft(m)/t_all, total(m));
        end
        fprintf("主要処理(total)|呼出数|total[s]|total[%%]\n");
        for str_pat = ["require_equilibrium","check_edit","get_admittance_matrix","initialize_index","odeEventSet.table", ...
                       "makeODE","CalculateInitialCondition","setEventCondition","getInitialCondition","getNextPhase","Event2State", ...
                       "odeSimulationResult.odeSimulationResult","ode.solve","getODEFunction","getODEJacobian","get_dx_algebraic","time_keeper"]
            for m = find(contains(names, str_pat))
                fprintf("%s|%d|%.3f|%.1f\n", names(m), ft(m).NumCalls, total(m), 100*total(m)/t_all);
            end
        end
    end

    % プロファイラなしの個別計測 (呼び出しあたり)
    fprintf("### 呼び出しあたり (プロファイラなし, 各 20000 回の平均)\n");
    fprintf("net|対象|us/呼出|RHS1回あたりの呼出数|RHS1回あたり[ms]換算\n");
    for str_net = ["IEEE14bus","IEEE68bus"]
        net = build(str_net);
        net.simulate([0,0.01]);
        c_comp = {};
        for i = 1:numel(net.a_Bus)
            c_comp = [c_comp; net.a_Bus{i}.a_Component]; %#ok
        end
        gen = net.a_Bus{1}.a_Component{1};
        x = gen.rv_Xequilibrium;  u = gen.rv_Uequilibrium;
        V = [real(gen.c_Vequilibrium); imag(gen.c_Vequilibrium)];
        I = [real(gen.a_Bus.c_Iequilibrium); imag(gen.a_Bus.c_Iequilibrium)];
        nc = numel(c_comp);  nb = numel(net.a_Bus);
        c_ben = { ...
            "gen.f_dx",        @() gen.f_dx(0,x,V,I,u), nc; ...
            "gen.f_I",         @() gen.f_I(0,x,V,I,u),  nc; ...
            "gen.f_Y",         @() gen.f_Y(0,x,V,I,u),  nc; ...
            "gen.rv_Uoffset",  @() gen.rv_Uoffset(0),   nc; ...
            "gen.iv_odeX 読取", @() gen.iv_odeX,         3*nc; ...
            "net.a_Bus 読取",   @() net.a_Bus,           1; ...
            "bus.a_Component 読取", @() net.a_Bus{1}.a_Component, nb};
        for k = 1:size(c_ben,1)
            f = c_ben{k,2};
            t0 = tic;
            for it = 1:20000
                f();
            end
            us = toc(t0)/20000*1e6;
            fprintf("%s|%s|%.2f|%d|%.3f\n", str_net, c_ben{k,1}, us, c_ben{k,3}, us*c_ben{k,3}/1e3);
        end
        Y = tools.complex2matrix(net.get_admittance_matrix.Variables);
        v = ones(size(Y,1),1);
        f = @() Y*v;
        t0 = tic;
        for it = 1:20000
            f();
        end
        fprintf("%s|Y*V (%dx%d 密, 比較用)|%.2f|1|%.3f\n", str_net, size(Y,1), size(Y,2), toc(t0)/20000*1e6, toc(t0)/20000*1e3);
    end
end


%% 3 編集検知
function section_edit()
    fprintf("\n## 3 編集検知\n");
    fprintf("条件: IEEE9bus (AVR+PSS あり, case によりなし), fault B007 [1,1.05], time=[0,3], Tolerance=1e-6, AbsoluteTolerance=1e-8\n");
    fprintf("d_old: 編集前の応答との差, d_new: 編集後に initialize した応答との差 (機器 x と母線 V の最大差, 共通の変数のみ)\n");
    fprintf("drift: 事故前 t<0.9 の状態の最大変化。判定は d<1e-5 を一致とする\n");
    fprintf("編集|結果|flag|d_old|d_new|drift|stale後|詳細\n");

    gen = @(n) n.a_Bus{2}.a_Component{1};
    lod = @(n) n.a_Bus{5}.a_Component{1};
    c = { ...
      "発電機 D: tab_parameter.dynamics.D",         "lc", @(n) set_tab(gen(n), "dynamics", "D", 5); ...
      "発電機 M: tab_parameter.dynamics.M",         "lc", @(n) set_tab(gen(n), "dynamics", "M", 50); ...
      "発電機 D: tab_parameter 全体の代入",           "lc", @(n) assign_whole(gen(n), "dynamics", "D", 5); ...
      "発電機 D: para_dynamics.D 直接",             "lc", @(n) set_para(gen(n), "para_dynamics", "D", 5); ...
      "発電機 D: 複製の表を変更 (代入なし)",           "lc", @(n) copy_only(gen(n)); ...
      "発電機 D: 変更して元の値へ戻す",               "lc", @(n) edit_and_back(gen(n)); ...
      "ブランチ X: tab_parameter.dynamics.X",       "lc", @(n) set_tab(n.a_Branch{4}, "dynamics", "X", 0.17); ...
      "ブランチ tap: tab_parameter.dynamics.tap",    "lc", @(n) set_tab(n.a_Branch{1}, "dynamics", "tap", 1.05); ...
      "ブランチ X: para_dynamics.X 直接",            "lc", @(n) set_para(n.a_Branch{4}, "para_dynamics", "X", 0.17); ...
      "PV→PQ: 発電機 Q=NaN→値",                     "lc", @(n) set_tab(gen(n), "powerflow", "Q", 0.1); ...
      "PQ→PV: 負荷 Q→NaN",                          "lc", @(n) set_tab(lod(n), "powerflow", "Q", nan); ...
      "潮流 P: 負荷 P",                              "lc", @(n) set_tab(lod(n), "powerflow", "P", -1.1); ...
      "潮流 V: 母線 V",                              "lc", @(n) set_tab(n.a_Bus{2}, "powerflow", "V", 1.0); ...
      "スラック変更: l_isSlack",                      "lc", @(n) set_slack(n, 2); ...
      "Hz: 60→50",                                  "lc", @(n) set_tab(n, "base", "Hz", 50); ...
      "baseMVA: 100→200",                           "lc", @(n) set_tab(n, "base", "baseMVA", 200); ...
      "AVR パラメータ",                               "lc", @(n) set_lc_first(gen(n).a_LocalController{1}); ...
      "PSS パラメータ",                               "lc", @(n) set_lc_first(gen(n).a_LocalController{1}.a_LocalController{1}); ...
      "AVR 追加",                                    "no", @(n) gen(n).add_local_controller(controller.avr.AVR_ST1("avrX")); ...
      "AVR 差し替え",                                 "lc", @(n) gen(n).add_local_controller(controller.avr.AVR_ST1("avrX")); ...
      "LQR 追加 (AVR を置換)",                        "lc", @(n) gen(n).add_local_controller(controller.local_LQR("lqrX", Input="Vfield")); ...
      "大域制御器 追加",                               "lc", @(n) n.add_global_controller(controller.agc.broadcast_PI_AGC(n, "agc", "SG1B001", "SG1B002")); ...
      "大域制御器 削除",                               "gc", @(n) n.remove_global_controller("agc"); ...
      "大域制御器 パラメータ kI",                       "gc", @(n) set_gc(n.a_GlobalController{1}); ...
      "機器 削除 (負荷)",                              "lc", @(n) n.a_Bus{6}.remove_component(string(n.a_Bus{6}.a_Component{1})); ...
      "ブランチ 削除",                                 "lc", @(n) n.remove_branch(string(n.a_Branch{9})); ...
      "operation の編集 (母線 Vmax)",                  "lc", @(n) set_tab(n.a_Bus{2}, "operation", "Vmax", 1.4)};

    for i = 1:size(c,1)
        [str_name, str_base, f_edit] = c{i,:};
        base = @() edit_net(str_base);
        probe_edit(str_name, base, f_edit);
    end

    % 直接は書けないはずのもの
    fprintf("### 直接の書き込み\n");
    net = build("IEEE9bus");
    g = net.a_Bus{2}.a_Component{1};
    avr = g.a_LocalController{1};
    probe_set("avr.tab_parameter.dynamics.X = ...", @() set_tab(avr, "dynamics", string(avr.tab_parameter.dynamics.Properties.VariableNames(1)), 1));
    probe_set("gen.rv_Xequilibrium = ...", @() set_prop(g, "rv_Xequilibrium", g.rv_Xequilibrium*0));
    probe_set("gen.f_dx = ...",            @() set_prop(g, "f_dx", @(varargin) 0));
    probe_set("net.a_Bus = ...",           @() set_prop(net, "a_Bus", net.a_Bus));
    probe_set("net.solver_ODE = ...",      @() set_prop(net, "solver_ODE", []));
    probe_set("bus.c_Vequilibrium = ...",  @() set_prop(net.a_Bus{2}, "c_Vequilibrium", 1));
    probe_set("gen.rv_Xoffset = ... (Hidden, public)", @() set_prop(g, "rv_Xoffset", g.rv_Xoffset));
end

function n = edit_net(str_base)
    switch str_base
        case "lc"
            n = network.IEEE9bus();
        case "no"
            n = network.IEEE9bus(LocalController=false);
        case "gc"
            n = network.IEEE9bus();
            n.add_global_controller(controller.agc.broadcast_PI_AGC(n, "agc", "SG1B001", "SG1B002"));
    end
    n.solver_ODE.Progress = "none";
    n.solver_ODE.TimeLimit = Inf;
end

function probe_edit(str_name, base, f_edit)
    c_nv = kv("Tolerance", 1e-6, "AbsoluteTolerance", 1e-8);
    tspan = [0,3];
    try
        net = base();
        init(net);
        s_old = net.simulate(tspan, fault(net,"B007"), c_nv{:});

        evalc("f_edit(net)");
        l_stale = net.l_staleEquilibrium;

        ref = base();
        init(ref);
        evalc("f_edit(ref)");
        try
            init(ref);
            s_new = ref.simulate(tspan, fault(ref,"B007"), c_nv{:});
        catch me
            s_new = [];
            str_ref = "基準計算不可 " + me.identifier;
        end

        [sol, flag, str_err, str_id] = try_sim(@() net.simulate(tspan, fault(net,"B007"), c_nv{:}));
        if isempty(sol)
            str_detail = str_id + ": " + str_err;
            fprintf("%s|停止|-|-|-|-|%d|%s\n", str_name, l_stale, str_detail);
            return
        end
        d_old = sim_diff(sol, s_old);
        d_new = NaN;
        if ~isempty(s_new)
            d_new = sim_diff(sol, s_new);
        end
        str_out = classify(d_old, d_new);
        drift = pre_drift(sol, 0.9);
        str_detail = "";
        if isempty(s_new), str_detail = str_ref; end
        fprintf("%s|%s|%d|%.3e|%.3e|%.3e|%d|%s\n", str_name, str_out, flag, d_old, d_new, drift, l_stale, str_detail);
    catch me
        fprintf("%s|測定失敗|-|-|-|-|-|%s: %s\n", str_name, me.identifier, first_line(me.message));
    end
end

function s = classify(d_old, d_new)
    l_old = d_old < 1e-5;
    l_new = d_new < 1e-5;
    if l_old && l_new,  s = "新旧とも同じ(応答に影響なし)";
    elseif l_new,       s = "新しい値";
    elseif l_old,       s = "古い値";
    else,               s = "どちらとも異なる";
    end
end

function [sol, flag, str_err, str_id] = try_sim(fcn)
    sol = []; flag = NaN; str_err = ""; str_id = "";
    try
        [~, sol, flag] = evalc_sim(fcn);
    catch me
        str_err = first_line(me.message);
        str_id  = string(me.identifier);
        sol = [];
    end
end

function [txt, sol, flag] = evalc_sim(fcn)
    txt = evalc("[sol, flag] = fcn();");
end

function d = sim_diff(a, b)
    % a, b の共通の機器状態と母線電圧を共通の時刻で比較する
    tg = linspace(0.1, min(a.rv_t(end), b.rv_t(end)) - 0.1, 120)';
    lv_a = sim_columns(a.tab_variable);
    key_a = a.tab_variable.Owner(lv_a) + "/" + a.tab_variable.Name(lv_a) + "/" + a.tab_variable.Kind(lv_a);
    lv_b = sim_columns(b.tab_variable);
    key_b = b.tab_variable.Owner(lv_b) + "/" + b.tab_variable.Name(lv_b) + "/" + b.tab_variable.Kind(lv_b);
    [~, ia, ib] = intersect(key_a, key_b, "stable");
    ma = sample(a, find(lv_a), ia, tg);
    mb = sample(b, find(lv_b), ib, tg);
    d = max(abs(ma - mb), [], "all");
end

function lv = sim_columns(tab)
    lv = tab.Kind == "x" | tab.Kind == "Vre" | tab.Kind == "Vim";
end

function m = sample(sol, iv_col, ia, tg)
    [tu, iu] = unique(sol.rv_t, "last");
    m = interp1(tu, sol.rm_variable(iu, iv_col(ia)), tg);
end

function d = pre_drift(sol, t_end)
    tab = sol.tab_variable;
    lv = sim_columns(tab);
    lt = sol.rv_t < t_end;
    m = sol.rm_variable(lt, lv);
    d = max(abs(m - m(1,:)), [], "all");
end

function set_tab(obj, str_tab, str_col, val)
    obj.tab_parameter.(str_tab).(str_col) = val;
end
function assign_whole(obj, str_tab, str_col, val)
    tp = obj.tab_parameter;
    tp.(str_tab).(str_col) = val;
    obj.tab_parameter = tp;
end
function set_para(obj, str_para, str_col, val)
    obj.(str_para).(str_col) = val;
end
function copy_only(obj)
    tp = obj.tab_parameter;
    tp.dynamics.D = 5;   %#ok 代入し直さない
end
function edit_and_back(obj)
    d0 = obj.tab_parameter.dynamics.D;
    obj.tab_parameter.dynamics.D = 5;
    obj.tab_parameter.dynamics.D = d0;
end
function set_slack(net, i)
    net.a_Bus{i}.l_isSlack = true;
end
function set_lc_first(lc)
    % LocalController.tab_parameter には set メソッドがないので para_dynamics で編集する
    str = string(lc.tab_parameter.dynamics.Properties.VariableNames(1));
    v = lc.tab_parameter.dynamics.(str);
    lc.para_dynamics.(str) = v*2 + 0.1;
end
function set_gc(gc)
    gc.para_dynamics.kI = gc.para_dynamics.kI * 2;
end
function set_prop(obj, str, val)
    obj.(str) = val;
end
function probe_set(str_name, fcn)
    try
        fcn();
        fprintf("%s|書き込めた\n", str_name);
    catch me
        fprintf("%s|エラー %s: %s\n", str_name, me.identifier, first_line(me.message));
    end
end


%% 4 再現性と副作用
function section_side_effects()
    fprintf("\n## 4 再現性と副作用\n");
    fprintf("条件: IEEE14bus (全発電機に AVR+PSS) + AGC(SG1B001,SG1B002), time=[0,3], 既定 Tolerance, Progress=none, TimeLimit=Inf\n");
    fprintf("「発電機 trip」は AVR 付きだと落ちる (4-8) ので、制御器なし + AGC の IEEE14bus で測る\n");
    mk  = @() build("IEEE14bus", AGC=true);
    mk2 = @() build("IEEE14bus", LC=false, AGC=true);
    mk_for = @(str) pick_net(str, mk, mk2);

    % 4-1 同じ呼び出しを2回
    fprintf("### 4-1 同じ呼び出しの一致\n");
    c_ev = { ...
        "外乱なし",  @(n) {}; ...
        "fault",     @(n) {fault(n,"B008")}; ...
        "発電機 trip 途中まで", @(n) {odeEventSet("trip", n, "TimeSpan", [1,2], "TripUnit", "SG1B002")}; ...
        "発電機 trip 最後まで", @(n) {odeEventSet("trip", n, "TimeSpan", [1,5], "TripUnit", "SG1B002")}; ...
        "AGC trip",  @(n) {odeEventSet("trip", n, "TimeSpan", [1,2], "TripUnit", "agc")}; ...
        "offset",    @(n) {odeEventSet("offset", n, "TimeSpan", 0, "OffsetUnit", "SG1B001", "OffsetState", "delta", "OffsetValue", 0.01)}; ...
        "input",     @(n) {odeEventSet("input", n, "TimeSpan", [1,2], "InputUnit", "SG1B002", "InputName", "Pmech", "InputValue", 0.01)}};
    fprintf("事象|完全一致(isequaln)|最大差|n_t 1回目|n_t 2回目|flag|tEnd\n");
    for i = 1:size(c_ev,1)
        try
            net = mk_for(c_ev{i,1});
            ev = c_ev{i,2}(net);
            a = net.simulate([0,3], ev{:});
            b = net.simulate([0,3], ev{:});
            same = isequaln(a.rm_variable, b.rm_variable) && isequaln(a.rv_t, b.rv_t);
            d = NaN;
            if isequal(size(a.rm_variable), size(b.rm_variable))
                d = max(abs(a.rm_variable - b.rm_variable), [], "all", "omitnan");
            end
            fprintf("%s|%d|%.3e|%d|%d|%d|%g\n", c_ev{i,1}, same, d, numel(a.rv_t), numel(b.rv_t), a.flag, a.rv_t(end));
        catch me
            fprintf("%s|ERROR %s: %s\n", c_ev{i,1}, me.identifier, first_line(me.message));
        end
    end
    % 別の事象を間に挟んだ後と、新規ネットワークとの一致
    net = mk();
    for k = [2,6,7]
        ev = c_ev{k,2}(net);
        net.simulate([0,3], ev{:});
    end
    base = mk();
    a = base.simulate([0,3], fault(base,"B008"));
    b = net.simulate([0,3], fault(net,"B008"));
    fprintf("種々の実行の後 vs 新規ネットワーク: 完全一致=%d, 最大差=%.3e\n", isequaln(a.rm_variable,b.rm_variable), mat_diff(a,b));

    % 4-2 実行前後のプロパティ
    fprintf("### 4-2 実行前後のプロパティ差分 (全アクセス範囲, 値で比較)\n");
    fprintf("場面|変化したプロパティ(クラス.名前 [アクセス] 個数)\n");
    c_snap = { ...
        "1回目の simulate (外乱なし)",   @(n) {}; ...
        "fault (途中で復旧)",            @(n) {fault(n,"B008")}; ...
        "fault (最後まで継続)",          @(n) {fault(n,"B008",[1,5])}; ...
        "発電機 trip (最後まで継続)",    @(n) {odeEventSet("trip", n, "TimeSpan", [1,5], "TripUnit", "SG1B002")}; ...
        "AGC trip (最後まで継続)",       @(n) {odeEventSet("trip", n, "TimeSpan", [1,5], "TripUnit", "agc")}; ...
        "offset (t0 から最後まで)",      @(n) {odeEventSet("offset", n, "TimeSpan", [0,5], "OffsetUnit", "SG1B001", "OffsetState", "delta", "OffsetValue", 0.01)}; ...
        "input (最後まで継続)",          @(n) {odeEventSet("input", n, "TimeSpan", [1,5], "InputUnit", "SG1B002", "InputName", "Pmech", "InputValue", 0.01)}};
    for i = 1:size(c_snap,1)
        try
            net = mk_for(c_snap{i,1});
            s0 = snapshot(net);
            ev = c_snap{i,2}(net);
            net.simulate([0,3], ev{:});
            fprintf("%s|%s\n", c_snap{i,1}, snap_diff(s0, snapshot(net)));
        catch me
            fprintf("%s|ERROR %s: %s\n", c_snap{i,1}, me.identifier, first_line(me.message));
        end
    end

    % 4-3 持ち越しの影響: 実行後に他の解析と外乱なし simulate が元と一致するか
    fprintf("### 4-3 事象が最後まで続いた後の解析 (元の値との差)\n");
    fprintf("直前の事象|linearize 行列差|get_sys A差|潮流 V差|外乱なし sim drift|外乱なし sim と基準の差\n");
    for i = 2:size(c_snap,1)
        try
            net0 = mk_for(c_snap{i,1});
            lin0 = net0.linearize();
            sys0 = net0.get_sys();
            pf0  = quiet_pf(net0);
            s0   = net0.simulate([0,3]);
            net = mk_for(c_snap{i,1});
            ev = c_snap{i,2}(net);
            net.simulate([0,3], ev{:});
            lin = net.linearize();
            sys = net.get_sys();
            pf  = quiet_pf(net);
            s   = net.simulate([0,3]);
            dl  = max(abs([lin.rm_Axx,lin.rm_Axv;lin.rm_Avx,lin.rm_Avv] - [lin0.rm_Axx,lin0.rm_Axv;lin0.rm_Avx,lin0.rm_Avv]), [], "all");
            fprintf("%s|%.3e|%.3e|%.3e|%.3e|%.3e\n", c_snap{i,1}, dl, max(abs(sys.A - sys0.A), [], "all"), max(abs(pf-pf0)), pre_drift(s, 3.1), mat_diff(s,s0));
        catch me
            fprintf("%s|ERROR %s: %s\n", c_snap{i,1}, me.identifier, first_line(me.message));
        end
    end

    % 4-4 エラーと TimeLimit の後
    fprintf("### 4-4 エラー / TimeLimit 停止の後の再実行\n");
    net = mk();
    ref = net.simulate([0,3], fault(net,"B008"));
    s0  = snapshot(net);

    ev_err = odeEventSet("bad", net, "TimeSpan", [0.5,2], "InputUnit", "SG1B002", "InputName", "Pmech", ...
                         "InputValue", {@(t) bad_input(t)});
    try
        net.simulate([0,3], ev_err);
        fprintf("エラー誘発: エラーにならなかった\n");
    catch me
        fprintf("エラー誘発 (t>0.5 の入力関数): %s: %s\n", me.identifier, first_line(me.message));
    end
    fprintf("  エラー後の差分: %s\n", snap_diff(s0, snapshot(net)));
    rerun = net.simulate([0,3], fault(net,"B008"));
    fprintf("  再実行: flag=%d, 基準と完全一致=%d, 最大差=%.3e\n", rerun.flag, isequaln(rerun.rm_variable, ref.rm_variable), mat_diff(rerun,ref));

    % 事故中のエラー: 事故母線 / trip が残るか
    net = mk2();
    ref = net.simulate([0,3], fault(net,"B008"));
    ev_f = fault(net,"B008",[0.4,0.6]);
    ev_t = odeEventSet("trip", net, "TimeSpan", [0.4,0.6], "TripUnit", ["SG1B003";"agc"]);
    try
        net.simulate([0,3], ev_f, ev_t, ev_err_for(net));
        fprintf("事故+trip 中のエラー: エラーにならなかった\n");
    catch me
        fprintf("事故+trip 中のエラー: %s\n", me.identifier);
    end
    gc = net.a_GlobalController{1};
    fprintf("  エラー直後: bus B008 l_isFault=%d, SG1B003 l_isConnect=%d, agc l_isConnect=%d\n", ...
        get_private(net.a_Bus{8},"l_isFault"), get_private(net.a_Bus{3}.a_Component{1},"l_isConnect"), get_private(gc,"l_isConnect"));
    rerun = net.simulate([0,3], fault(net,"B008"));
    fprintf("  再実行: flag=%d, 基準と完全一致=%d, 最大差=%.3e\n", rerun.flag, isequaln(rerun.rm_variable, ref.rm_variable), mat_diff(rerun,ref));

    % TimeLimit
    net = mk();
    ref = net.simulate([0,3], fault(net,"B008"));
    lastwarn("");
    [txt, sol, flag, output] = capture_sim(@() net.simulate([0,3], fault(net,"B008"), TimeLimit=1e-3));
    fprintf("TimeLimit=1e-3: flag=%d, tEnd=%g, nPhasesDone=%d/%d, n_t=%d, 表示=%d文字, lastwarn='%s'\n  message: %s\n", ...
        flag, output.tEnd, output.nPhasesDone, output.nPhases, numel(sol.rv_t), strlength(strtrim(txt)), lastwarn, output.message);
    rerun = net.simulate([0,3], fault(net,"B008"));
    fprintf("  再実行: flag=%d, 基準と完全一致=%d, 最大差=%.3e\n", rerun.flag, isequaln(rerun.rm_variable, ref.rm_variable), mat_diff(rerun,ref));
    % TimeLimit は「1フェーズあたり」: 合計はフェーズ数倍まで延びうる (事象数を増やして確認)
    c_many = cell(1,8);
    for k = 1:8
        c_many{k} = odeEventSet("f"+k, net, "TimeSpan", [k*0.3, k*0.3+0.02], "FaultBus", "B008");
    end
    t0 = tic;
    [~, sol, flag, output] = capture_sim(@() net.simulate([0,3], c_many{:}, TimeLimit=0.3));
    fprintf("TimeLimit=0.3 s, %d フェーズ: 実行時間 %.2f s, flag=%d, tEnd=%g, r_elapsed=%.2f\n", output.nPhases, toc(t0), flag, output.tEnd, sol.r_elapsed);

    % 4-5 solver_ODE
    fprintf("### 4-5 net.solver_ODE の不変\n");
    net = mk();
    so = net.solver_ODE;
    s0 = solver_state(so);
    net.simulate([0,1], fault(net,"B008",[0.2,0.3]), Solver="ode23t", Tolerance=1e-6, AbsoluteTolerance=1e-8, TimeLimit=60, Verbose=false);
    fprintf("オプション指定実行の後: 変化なし=%d, 同じハンドル=%d\n", isequal(s0, solver_state(net.solver_ODE)), so == net.solver_ODE);
    opts = so.SolverOptions;
    fprintf("SolverOptions: クラス=%s, handle=%d, OutputFcn 空=%d, EventDefinition なし\n", class(opts), isa(opts,"handle"), isempty(opts.OutputFcn));
    so2 = matlab.ode.options.ODE15s(MaxStep=0.01);
    a = net.simulate([0,1], SolverOptions=so2);
    fprintf("SolverOptions=MaxStep 0.01 を渡した後: 渡した OutputFcn 空=%d, solver_ODE.SolverOptions.MaxStep 空=%d, n_t=%d\n", isempty(so2.OutputFcn), isempty(net.solver_ODE.SolverOptions.MaxStep), numel(a.rv_t));

    % 4-6 制御器の内部状態
    fprintf("### 4-6 制御器の内部状態の持ち越し\n");
    net = mk();
    s_fault = net.simulate([0,3], fault(net,"B008"));
    tab = s_fault.tab_variable;
    lv_c = ismember(tab.Owner, ["agc", string(net.a_Bus{1}.a_Component{1}.a_LocalController{1}.str_tag)]);
    fprintf("fault 実行の末尾での制御器状態の平衡点からの最大ずれ: %.3e\n", max(abs(s_fault.rm_variable(end,lv_c) - s_fault.rm_variable(1,lv_c))));
    s_after = net.simulate([0,3]);
    fprintf("次の外乱なし実行: 初期値の差(1回目初期値比)=%.3e, 全体の drift=%.3e, 制御器 drift=%.3e\n", ...
        max(abs(s_after.rm_variable(1,:) - s_fault.rm_variable(1,:))), pre_drift(s_after,3.1), max(abs(s_after.rm_variable(:,lv_c) - s_after.rm_variable(1,lv_c)), [], "all"));
    net = mk();
    net.simulate([0,3], odeEventSet("trip", net, "TimeSpan", [1,5], "TripUnit", "agc"));
    fprintf("AGC を最後まで trip した直後の l_isConnect=%d (onCleanup で戻す設計)\n", get_private(net.a_GlobalController{1},"l_isConnect"));
    net = mk2();
    net.simulate([0,3], odeEventSet("trip", net, "TimeSpan", [1,5], "TripUnit", "SG1B002"));
    fprintf("SG1B002 を最後まで trip した直後の l_isConnect=%d\n", get_private(net.a_Bus{2}.a_Component{1},"l_isConnect"));
    net = mk();
    net.simulate([0,3], fault(net,"B008",[1,5]));
    fprintf("B008 を最後まで fault した直後の l_isFault=%d\n", get_private(net.a_Bus{8},"l_isFault"));

    % 4-7 事象オブジェクトの使い回し
    fprintf("### 4-7 事象オブジェクトの使い回しと別ネットワーク\n");
    probe_stale_event();

    fprintf("### 4-9 AGC が制御する発電機の trip (制御器なし IEEE14bus + AGC(SG1B001,SG1B002))\n");
    for str_unit = ["SG1B002","SG1B003"]
        for l_agc = [true,false]
            net = build("IEEE14bus", LC=false, AGC=l_agc);
            [~, sol, flag, output] = capture_sim(@() net.simulate([0,3], odeEventSet("trip", net, "TimeSpan", [1,2], "TripUnit", str_unit)));
            fprintf("trip %s, AGC=%d: flag=%d tEnd=%g n_t=%d\n", str_unit, l_agc, flag, output.tEnd, numel(sol.rv_t));
        end
    end

    % 4-8 発電機 trip と制御器の組み合わせ
    fprintf("### 4-8 発電機 trip × 制御器 (SG1B002 を trip)\n");
    fprintf("net|制御器|TimeSpan|結果\n");
    c_lc = { ...
        "なし",      @(g) []; ...
        "AVR",       @(g) g.add_local_controller(controller.avr.AVR_ST1("avrT")); ...
        "AVR+PSS",   @(g) g.add_local_controller(controller.avr.AVR_ST1("avrT"), controller.pss.PSS1("pssT")); ...
        "LQR",       @(g) g.add_local_controller(controller.local_LQR("lqrT", Input="Vfield"))};
    for str_net = ["IEEE9bus","IEEE14bus"]
        for i = 1:size(c_lc,1)
            for c_ts = {[1,1.5],[1,5]}
                probe_trip(str_net, c_lc{i,1}, c_lc{i,2}, c_ts{1});
            end
        end
    end
    % 同梱ネットワークの既定 (AVR+PSS つき) での trip
    for str_net = ["IEEE9bus","IEEE68bus"]
        net = build(str_net);
        try
            [~, sol, flag] = evalc_sim(@() net.simulate([0,2], odeEventSet("trip", net, "TimeSpan", [0.5,1], "TripUnit", "SG1B002")));
            fprintf("%s 既定|AVR+PSS|[0.5,1]|OK flag=%d n_t=%d message=%s\n", str_net, flag, numel(sol.rv_t), first_line(sol.output.message));
        catch me
            fprintf("%s 既定|AVR+PSS|[0.5,1]|ERROR id='%s' %s (スタック先頭 %s:%d)\n", str_net, me.identifier, first_line(me.message), me.stack(1).name, me.stack(1).line);
            g = net.a_Bus{2}.a_Component{1};
            fprintf("  エラー直後 l_isConnect=%d; 外乱なしの再実行 flag=", get_private(g,"l_isConnect"));
            [~, s2, f2] = evalc_sim(@() net.simulate([0,2]));
            fprintf("%d drift=%.3e\n", f2, pre_drift(s2,2.1));
        end
    end
end

function net = pick_net(str, mk, mk2)
    if contains(str, "発電機 trip")
        net = mk2();
    else
        net = mk();
    end
end

function probe_trip(str_net, str_lc, f_lc, ts)
    net = build(str_net, LC=false, Init=false);
    f_lc(net.a_Bus{2}.a_Component{1});
    init(net);
    try
        [~, sol, flag] = evalc_sim(@() net.simulate([0,3], odeEventSet("trip", net, "TimeSpan", ts, "TripUnit", "SG1B002")));
        fprintf("%s|%s|%s|OK flag=%d tEnd=%g n_t=%d\n", str_net, str_lc, mat2str(ts), flag, sol.rv_t(end), numel(sol.rv_t));
    catch me
        fprintf("%s|%s|%s|ERROR id='%s' %s (スタック先頭 %s:%d)\n", str_net, str_lc, mat2str(ts), me.identifier, first_line(me.message), me.stack(1).name, me.stack(1).line);
    end
end

function ev = ev_err_for(net)
    ev = odeEventSet("bad", net, "TimeSpan", [0.5,0.55], "InputUnit", "SG1B001", "InputName", "Pmech", ...
                     "InputValue", {@(t) bad_input(t)});
end

function v = bad_input(t)
    if t > 0.01
        error("simreview:Injected", "injected error in the input function");
    end
    v = 0;
end

function d = mat_diff(a, b)
    if isequal(size(a.rm_variable), size(b.rm_variable))
        d = max(abs(a.rm_variable - b.rm_variable), [], "all", "omitnan");
    else
        d = sim_diff(a, b);
    end
end

function v = quiet_pf(net)
    evalc("res = net.calculate_powerflow();");
    v = abs(net.cv_Vequilibrium); %#ok 既存の平衡点 (潮流計算は平衡点を書き換えない前提の確認も兼ねる)
    v = [v; res.tab_bus{:, vartype("numeric")}(:)];
end

function s = solver_state(so)
    mc = metaclass(so);
    s = struct();
    for p = mc.PropertyList'
        if ~p.Constant && ~p.Dependent && strcmp(p.GetAccess, "public")
            val = so.(p.Name);
            if isa(val, "matlab.ode.Options")
                val = evalc("disp(val)");
            end
            s.(p.Name) = val;
        end
    end
end

function v = get_private(obj, str)
    w = warning("off", "MATLAB:structOnObject");
    c = onCleanup(@() warning(w));
    s = builtin("struct", obj);      % struct はオーバーロードされている
    v = s.(str);
end

function S = snapshot(net)
    w = warning("off", "MATLAB:structOnObject");
    c = onCleanup(@() warning(w));
    objs = [{net; net.solver_ODE}; net.a_Bus; net.a_Branch; net.a_GlobalController];
    for i = 1:numel(net.a_Bus)
        cm = net.a_Bus{i}.a_Component;
        objs = [objs; cm]; %#ok
        for j = 1:numel(cm)
            lc = cm{j}.a_LocalController;
            objs = [objs; lc(:)]; %#ok
            if ~isempty(lc)
                objs = [objs; lc{1}.a_LocalController(:)]; %#ok
            end
        end
    end
    S = struct("key", {}, "cls", {}, "prop", {}, "acc", {}, "val", {});
    for i = 1:numel(objs)
        o = objs{i};
        cls = string(class(o));
        s = builtin("struct", o);
        for f = string(fieldnames(s))'
            mp = findprop(o, f);
            acc = "?";
            if ~isempty(mp)
                acc = "限定";
                if ischar(mp.GetAccess) || isstring(mp.GetAccess)
                    acc = string(mp.GetAccess);
                end
                if mp.Hidden, acc = acc + "/Hidden"; end
                if mp.Dependent, continue; end
            end
            S(end+1).key = cls + "#" + i + "." + f; %#ok
            S(end).cls  = cls;
            S(end).prop = f;
            S(end).acc  = acc;
            S(end).val  = norm_val(s.(f));
        end
        if isprop(o, "rv_Uoffset") && isa(o.rv_Uoffset, "function_handle")
            S(end+1).key = cls + "#" + i + ".rv_Uoffset(0)"; %#ok
            S(end).cls  = cls;
            S(end).prop = "rv_Uoffset(0)の値";
            S(end).acc  = "public/Hidden";
            S(end).val  = o.rv_Uoffset(0);
        end
    end
end

function v = norm_val(x)
    if isa(x, "function_handle")
        v = func2str(x);
    elseif isa(x, "Parameter")
        v = x.tab_parameter;
    elseif isa(x, "handle")
        v = "<handle " + class(x) + ">";
    elseif iscell(x)
        v = cellfun(@norm_val, x, "UniformOutput", false);
    elseif isstruct(x)
        v = "<struct>";
        try
            v = structfun(@norm_val, x, "UniformOutput", false);
        catch
        end
    else
        v = x;
    end
end

function str = snap_diff(a, b)
    % key で対応を取る (rv_Uoffset(0) は最初の実行の後にだけある)
    ka = string({a.key});
    kb = string({b.key});
    labels = strings(0,1);
    for i = 1:numel(b)
        k = find(ka == kb(i), 1);
        if isempty(k) || ~isequaln(a(k).val, b(i).val)
            labels(end+1,1) = b(i).cls + "." + b(i).prop + " [" + b(i).acc + "]"; %#ok
        end
    end
    if isempty(labels)
        str = "なし";
        return
    end
    [u, ~, ic] = unique(labels);
    n = accumarray(ic(:), 1);
    str = join(u(:) + " x" + n(:), "; ");
end

function probe_stale_event()
    c_nv = kv("Tolerance", 1e-6, "AbsoluteTolerance", 1e-8);
    % (a) 構成変更の前に作った事象 (大域制御器を追加, initialize は実行)
    net = build("IEEE9bus", LC=false);
    ev_old = odeEventSet("trip", net, "TimeSpan", [1,1.5], "TripUnit", "SG1B002");
    net.add_global_controller(controller.agc.broadcast_PI_AGC(net, "agc", "SG1B001", "SG1B003"));
    init(net);
    ev_new = odeEventSet("trip", net, "TimeSpan", [1,1.5], "TripUnit", "SG1B002");
    report_event("(a) 大域制御器を追加した後に古い trip 事象", net, ev_old, ev_new, c_nv);

    % (b) AVR を追加
    net = build("IEEE9bus", LC=false);
    ev_old = odeEventSet("trip", net, "TimeSpan", [1,1.5], "TripUnit", "SG1B002");
    net.a_Bus{1}.a_Component{1}.add_local_controller(controller.avr.AVR_ST1("avrX"));
    init(net);
    ev_new = odeEventSet("trip", net, "TimeSpan", [1,1.5], "TripUnit", "SG1B002");
    report_event("(b) 先頭の発電機に AVR を追加した後に古い trip 事象", net, ev_old, ev_new, c_nv);

    % (c) AVR を追加, fault のみ (trip なし)
    net = build("IEEE9bus", LC=false);
    ev_old = fault(net,"B007");
    net.a_Bus{1}.a_Component{1}.add_local_controller(controller.avr.AVR_ST1("avrX"));
    init(net);
    report_event("(c) AVR を追加した後に古い fault 事象", net, ev_old, fault(net,"B007"), c_nv);

    % (d) 機器を削除
    net = build("IEEE9bus", LC=false);
    ev_old = odeEventSet("trip", net, "TimeSpan", [1,1.5], "TripUnit", "SG1B002");
    net.a_Bus{6}.remove_component(string(net.a_Bus{6}.a_Component{1}));
    init(net);
    report_event("(d) 負荷を削除した後に古い trip 事象", net, ev_old, odeEventSet("trip", net, "TimeSpan", [1,1.5], "TripUnit", "SG1B002"), c_nv);

    % (e) 別のネットワークの事象 (同じ構成で D が違う)
    netA = build("IEEE9bus");
    netB = network.IEEE9bus();
    netB.solver_ODE.Progress = "none";  netB.solver_ODE.TimeLimit = Inf;
    netB.a_Bus{2}.a_Component{1}.tab_parameter.dynamics.D = 20;
    init(netB);
    sA = netA.simulate([0,3], fault(netA,"B007"), c_nv{:});
    sB = netB.simulate([0,3], fault(netB,"B007"), c_nv{:});
    try
        evalc("[sX, flagX] = netB.simulate([0,3], fault(netA,""B007""), c_nv{:});");
        fprintf("(e) netB.simulate(netA の事象): エラーなし flag=%d, str_network=%s, 自分の応答との差=%.3e, 事象側 netA の応答との差=%.3e\n", ...
            flagX, sX.str_network, sim_diff(sX,sB), sim_diff(sX,sA));
    catch me
        fprintf("(e) netB.simulate(netA の事象): エラー %s: %s\n", me.identifier, first_line(me.message));
    end

    % (e2) 別のネットワークの事象 (同じ構成で負荷が違い平衡点も違う)。netC は simulate 未実行
    netA = build("IEEE9bus");
    netC = network.IEEE9bus();
    netC.solver_ODE.Progress = "none";  netC.solver_ODE.TimeLimit = Inf;
    netC.a_Bus{5}.a_Component{1}.tab_parameter.powerflow.P = -1.5;
    init(netC);
    sC = netC.simulate([0,3], fault(netC,"B007"), c_nv{:});
    sA = netA.simulate([0,3], fault(netA,"B007"), c_nv{:});
    netD = network.IEEE9bus();
    netD.solver_ODE.Progress = "none";  netD.solver_ODE.TimeLimit = Inf;
    netD.a_Bus{5}.a_Component{1}.tab_parameter.powerflow.P = -1.5;
    init(netD);
    try
        evalc("[sX, flagX] = netD.simulate([0,3], fault(netA,""B007""), c_nv{:});");
        fprintf("(e2) netD(負荷違い, simulate 未実行).simulate(netA の事象): エラーなし flag=%d, t=0 の値と netD 平衡点の差=%.3e, t=0 の値と netA 平衡点の差=%.3e, 自分の応答との差=%.3e, netA の応答との差=%.3e\n", ...
            flagX, max(abs(sX.rm_variable(1,:) - sC.rm_variable(1,:))), max(abs(sX.rm_variable(1,:) - sA.rm_variable(1,:))), sim_diff(sX,sC), sim_diff(sX,sA));
    catch me
        fprintf("(e2) netD.simulate(netA の事象): エラー %s: %s\n", me.identifier, first_line(me.message));
    end

    % (f) 別サイズのネットワークの事象
    net14 = build("IEEE14bus");
    netA2 = build("IEEE9bus");
    try
        evalc("[sX, flagX] = netA2.simulate([0,3], fault(net14,""B008""), c_nv{:});");
        fprintf("(f) IEEE9.simulate(IEEE14 の事象): エラーなし flag=%d, 変数数=%d (IEEE9 は %d), 地絡 B008 で変化=%.3e\n", flagX, size(sX.rm_variable,2), height(netA2.get_variable_map()), max(abs(sX.rm_variable(end,:)-sX.rm_variable(1,:))));
    catch me
        fprintf("(f) IEEE9.simulate(IEEE14 の事象): エラー %s: %s\n", me.identifier, first_line(me.message));
    end

    % (g) 同じ事象オブジェクトで2回 (setEventCondition が事象に書き込む)
    net = build("IEEE9bus");
    ev = fault(net,"B007");
    a = net.simulate([0,3], ev, c_nv{:});
    b = net.simulate([0,3], ev, c_nv{:});
    fprintf("(g) 同じ事象オブジェクトで2回: 完全一致=%d\n", isequaln(a.rm_variable, b.rm_variable));

    % (h) 事象を作った後に Hz を変えても事象は有効
    % (i) simulate 中に変更されるモデルのフィールドが他のネットワークへ波及しないこと
    netP = build("IEEE9bus");
    netQ = build("IEEE9bus");
    s0 = snapshot(netQ);
    netP.simulate([0,1], fault(netP,"B007",[0.2,0.3]));
    fprintf("(i) 別ネットワークの実行で netQ が変化: %s\n", snap_diff(s0, snapshot(netQ)));
end

function report_event(str, net, ev_old, ev_new, c_nv)
    s_new = net.simulate([0,3], ev_new, c_nv{:});
    try
        [txt, s_old, flag] = evalc_sim(@() net.simulate([0,3], ev_old, c_nv{:}));
        fprintf("%s: エラーなし flag=%d tEnd=%g, 新しい事象との差=%.3e, 表示=%d文字\n", str, flag, s_old.rv_t(end), sim_diff(s_old, s_new), strlength(strtrim(txt)));
    catch me
        fprintf("%s: エラー %s: %s\n", str, me.identifier, first_line(me.message));
    end
end


%% 5 引数と境界
function section_arguments()
    fprintf("\n## 5 引数と境界ケース\n");
    fprintf("条件: IEEE14bus (AVR+PSS), 既定 Tolerance, Progress=none, 各ケース TimeLimit=30 s (指定のあるものを除く), ケースごとに新規ネットワーク\n");
    fprintf("group|ケース|結果|flag|tEnd|nPhases|n_t|警告ID|メッセージ\n");
    f = @(n, varargin) odeEventSet("f", n, "FaultBus", "B008", varargin{:});

    % time
    c = { ...
      "time", "引数なし",               @(n) n.simulate(); ...
      "time", "[]",                     @(n) n.simulate([]); ...
      "time", "[] + 事象 [1,1.05]",     @(n) n.simulate([], f(n,"TimeSpan",[1,1.05])); ...
      "time", "スカラー 5",              @(n) n.simulate(5); ...
      "time", "スカラー 5 + 事象",        @(n) n.simulate(5, f(n,"TimeSpan",[1,1.05])); ...
      "time", "列ベクトル [0;3]",        @(n) n.simulate([0;3]); ...
      "time", "[3,0] 逆順",              @(n) n.simulate([3,0]); ...
      "time", "[1,1] 長さゼロ",           @(n) n.simulate([1,1]); ...
      "time", "[0,NaN]",                @(n) n.simulate([0,NaN]); ...
      "time", "[NaN,3]",                @(n) n.simulate([NaN,3]); ...
      "time", "[0,Inf]",                @(n) n.simulate([0,Inf], TimeLimit=5); ...
      "time", "[-1,2] 負の開始",          @(n) n.simulate([-1,2]); ...
      "time", "[1,3] 非ゼロ開始",         @(n) n.simulate([1,3]); ...
      "time", "[0,1,2] 3要素",           @(n) n.simulate([0,1,2]); ...
      "time", "[0,2,1] 3要素非単調",      @(n) n.simulate([0,2,1]); ...
      "time", "[0,0.5,1,2,3] 5要素 + 事象 [1,1.05]", @(n) n.simulate([0,0.5,1,2,3], f(n,"TimeSpan",[1,1.05])); ...
      "time", "[0,1;2,3] 行列",          @(n) n.simulate([0,1;2,3]); ...
      "time", """abc"" 文字列",          @(n) n.simulate("abc"); ...
      "time", "{0,1} セル",              @(n) n.simulate({0,1}); ...
      "time", "1+1i を含む",             @(n) n.simulate([0,1+1i]); ...
      "time", "事象を第1引数に",          @(n) n.simulate(f(n,"TimeSpan",[1,1.05]))};
    % オプション
    c = [c; { ...
      "opt", "未知 Foo=1",              @(n) n.simulate([0,1], Foo=1); ...
      "opt", "小文字 tolerance=1e-5",   @(n) n.simulate([0,1], tolerance=1e-5); ...
      "opt", "奇数個 ""Tolerance""",    @(n) n.simulate([0,1], "Tolerance"); ...
      "opt", "名前が数値 1,2",           @(n) n.simulate([0,1], 1, 2); ...
      "opt", "Tolerance=1 (範囲外)",     @(n) n.simulate([0,1], Tolerance=1); ...
      "opt", "Tolerance=-1",            @(n) n.simulate([0,1], Tolerance=-1); ...
      "opt", "Tolerance=""a""",         @(n) n.simulate([0,1], Tolerance="a"); ...
      "opt", "Solver=""ode99""",        @(n) n.simulate([0,1], Solver="ode99"); ...
      "opt", "Solver=""ode45"" (DAE不可)", @(n) n.simulate([0,1], Solver="ode45"); ...
      "opt", "Solver=""ode23s""",       @(n) n.simulate([0,1], Solver="ode23s"); ...
      "opt", "Solver=""ode23t"" + SolverOptions ODE15s", @(n) n.simulate([0,1], Solver="ode23t", SolverOptions=matlab.ode.options.ODE15s); ...
      "opt", "SolverOptions=数値",       @(n) n.simulate([0,1], SolverOptions=1); ...
      "opt", "TimeLimit=0",             @(n) n.simulate([0,1], TimeLimit=0); ...
      "opt", "TimeLimit=-1",            @(n) n.simulate([0,1], TimeLimit=-1); ...
      "opt", "Progress=""foo""",        @(n) n.simulate([0,1], Progress="foo"); ...
      "opt", "Progress=[1,0]",          @(n) n.simulate([0,1], Progress=[true,false]); ...
      "opt", "Verbose=""x""",           @(n) n.simulate([0,1], Verbose="x"); ...
      "opt", "Export=1",                @(n) n.simulate([0,1], Export=1); ...
      "opt", "v3名 RelativeTolerance",   @(n) n.simulate([0,1], RelativeTolerance=1e-5); ...
      "opt", "オプションの後に事象",        @(n) n.simulate([0,1], "Tolerance", 1e-5, f(n,"TimeSpan",[0.2,0.3])); ...
      "opt", "事象でない位置引数 123",      @(n) n.simulate([0,1], 123); ...
      "opt", "事象のセル {ev}",            @(n) n.simulate([0,1], {f(n,"TimeSpan",[0.2,0.3])}); ...
      "opt", "事象の配列 [ev,ev]",         @(n) n.simulate([0,1], [odeEventSet("a",n,"TimeSpan",0.2), odeEventSet("b",n,"TimeSpan",0.3)])}];
    % 事象
    tr = @(n,str,varargin) odeEventSet("t", n, "TripUnit", str, varargin{:});
    c = [c; { ...
      "event", "TimeSpan 逆順 [2,1]",     @(n) n.simulate([0,3], f(n,"TimeSpan",[2,1])); ...
      "event", "TimeSpan 3要素",           @(n) n.simulate([0,3], f(n,"TimeSpan",[1,1.05,2])); ...
      "event", "TimeSpan 列 [1;2]",        @(n) n.simulate([0,3], f(n,"TimeSpan",[1;2])); ...
      "event", "TimeSpan NaN",             @(n) n.simulate([0,3], f(n,"TimeSpan",[NaN,2])); ...
      "event", "TimeSpan [1,Inf]",         @(n) n.simulate([0,3], f(n,"TimeSpan",[1,Inf])); ...
      "event", "完全に範囲外 (後) [5,6]",    @(n) n.simulate([0,3], f(n,"TimeSpan",[5,6])); ...
      "event", "完全に範囲外 (前) [-2,-1]",  @(n) n.simulate([0,3], f(n,"TimeSpan",[-2,-1])); ...
      "event", "一部範囲外 [2,5]",          @(n) n.simulate([0,3], f(n,"TimeSpan",[2,5])); ...
      "event", "開始 t0 と同時 [0,0.1]",    @(n) n.simulate([0,3], f(n,"TimeSpan",[0,0.1])); ...
      "event", "t0 より前から [-1,0.1]",    @(n) n.simulate([0,3], f(n,"TimeSpan",[-1,0.1])); ...
      "event", "長さゼロの fault [1,1]",    @(n) n.simulate([0,3], f(n,"TimeSpan",[1,1])); ...
      "event", "スカラー fault 1",          @(n) n.simulate([0,3], f(n,"TimeSpan",1)); ...
      "event", "ごく短い [1,1+1e-12]",      @(n) n.simulate([0,3], f(n,"TimeSpan",[1,1+1e-12])); ...
      "event", "重なり: 別母線",             @(n) n.simulate([0,3], odeEventSet("a",n,"TimeSpan",[1,1.2],"FaultBus","B008"), odeEventSet("b",n,"TimeSpan",[1.1,1.3],"FaultBus","B009")); ...
      "event", "重なり: 同じ母線",           @(n) n.simulate([0,3], odeEventSet("a",n,"TimeSpan",[1,1.2],"FaultBus","B008"), odeEventSet("b",n,"TimeSpan",[1.1,1.3],"FaultBus","B008")); ...
      "event", "同じ tag の2事象",           @(n) n.simulate([0,3], odeEventSet("a",n,"TimeSpan",[1,1.2],"FaultBus","B008"), odeEventSet("a",n,"TimeSpan",[2,2.2],"FaultBus","B009")); ...
      "event", "tag=""t1""",                @(n) n.simulate([0,3], odeEventSet("t1",n,"TimeSpan",[1,1.2],"FaultBus","B008")); ...
      "event", "tag に空白 ""my fault""",    @(n) n.simulate([0,3], odeEventSet("my fault",n,"TimeSpan",[1,1.2],"FaultBus","B008")); ...
      "event", "tag=""NoAction1""",         @(n) n.simulate([0,3], odeEventSet("NoAction1",n,"TimeSpan",[1,1.2],"FaultBus","B008")); ...
      "event", "未知の FaultBus",            @(n) n.simulate([0,3], odeEventSet("a",n,"TimeSpan",[1,1.2],"FaultBus","B999")); ...
      "event", "未知の TripUnit",            @(n) n.simulate([0,3], tr(n,"XXX","TimeSpan",[1,1.2])); ...
      "event", "未知の OffsetUnit",          @(n) n.simulate([0,3], odeEventSet("a",n,"TimeSpan",1,"OffsetUnit","XXX","OffsetState","delta","OffsetValue",0.1)); ...
      "event", "未知の OffsetState",         @(n) n.simulate([0,3], odeEventSet("a",n,"TimeSpan",1,"OffsetUnit","SG1B001","OffsetState","xxx","OffsetValue",0.1)); ...
      "event", "OffsetState/Value 個数違い",  @(n) n.simulate([0,3], odeEventSet("a",n,"TimeSpan",1,"OffsetUnit","SG1B001","OffsetState",["delta";"omega"],"OffsetValue",[0.1;0.2;0.3])); ...
      "event", "OffsetUnit=AVR の tag",      @(n) n.simulate([0,3], odeEventSet("a",n,"TimeSpan",1,"OffsetUnit",string(n.a_Bus{1}.a_Component{1}.a_LocalController{1}.str_tag),"OffsetState","Vfd","OffsetValue",0.1)); ...
      "event", "未知の InputUnit",           @(n) n.simulate([0,3], odeEventSet("a",n,"TimeSpan",[1,2],"InputUnit","XXX","InputName","Pmech","InputValue",0.1)); ...
      "event", "未知の InputName",           @(n) n.simulate([0,3], odeEventSet("a",n,"TimeSpan",[1,2],"InputUnit","SG1B002","InputName","xxx","InputValue",0.1)); ...
      "event", "InputValue 個数違い",        @(n) n.simulate([0,3], odeEventSet("a",n,"TimeSpan",[1,2],"InputUnit","SG1B002","InputName",["Pmech";"Vfield"],"InputValue",[0.1;0.2;0.3])); ...
      "event", "InputValue が行列を返す関数", @(n) n.simulate([0,3], odeEventSet("a",n,"TimeSpan",[1,2],"InputUnit","SG1B002","InputName","Pmech","InputValue",{@(t) [t;t]})); ...
      "event", "trip=AVR の tag",            @(n) n.simulate([0,3], tr(n,string(n.a_Bus{1}.a_Component{1}.a_LocalController{1}.str_tag),"TimeSpan",[1,1.2])); ...
      "event", "trip 発電機を全部",           @(n) n.simulate([0,3], tr(n,all_gens(n),"TimeSpan",[1,1.2])); ...
      "event", "fault 全母線",                @(n) n.simulate([0,3], odeEventSet("a",n,"TimeSpan",[1,1.2],"FaultBus",string(n.a_Bus))); ...
      "event", "事象の順序: 後の事象を先に",    @(n) n.simulate([0,3], odeEventSet("b",n,"TimeSpan",[2,2.2],"FaultBus","B009"), odeEventSet("a",n,"TimeSpan",[1,1.2],"FaultBus","B008")); ...
      "event", "fault が最後まで続く",         @(n) n.simulate([0,3], f(n,"TimeSpan",[1,3]))}];

    for i = 1:size(c,1)
        probe_arg(c{i,:});
    end

    % 事象の順序違いの結果の一致
    n = build("IEEE14bus");
    ea = odeEventSet("a",n,"TimeSpan",[1,1.2],"FaultBus","B008");
    eb = odeEventSet("b",n,"TimeSpan",[2,2.2],"FaultBus","B009");
    s1 = n.simulate([0,3], ea, eb);
    s2 = n.simulate([0,3], eb, ea);
    fprintf("順序違いの結果: 完全一致=%d, 最大差=%.3e\n", isequaln(s1.rm_variable, s2.rm_variable), mat_diff(s1,s2));
    % 未知の tag を与えたときに外乱なしと同じ応答か
    s0 = n.simulate([0,3]);
    s3 = n.simulate([0,3], odeEventSet("a",n,"TimeSpan",[1,1.2],"FaultBus","B999"));
    fprintf("未知の FaultBus の応答と外乱なしの差: %.3e\n", sim_diff(s3, s0));
    % 範囲外の事象が time を変えないこと
    fprintf("既定の終了時刻 (time=[]): 事象 [1,1.05]: %g, 事象 [10,10.05]: %g, 事象 [20,20.05]: %g, 事象なし: %g\n", ...
        n.simulate([], fault(n,"B008",[1,1.05])).rv_t(end), n.simulate([], fault(n,"B008",[10,10.05])).rv_t(end), n.simulate([], fault(n,"B008",[20,20.05])).rv_t(end), n.simulate([]).rv_t(end));
    % スカラー / 長さゼロの fault はどれだけ続くか
    a = n.simulate([0,3], fault(n,"B008",1));
    b = n.simulate([0,3], fault(n,"B008",[1,3]));
    c = n.simulate([0,3], fault(n,"B008",[1,1]));
    fprintf("fault TimeSpan=1 vs [1,3]: 差=%.3e / TimeSpan=[1,1] vs [1,3]: 差=%.3e / 終端の B008 |V|=%.3e\n", mat_diff(a,b), mat_diff(c,b), norm(a.rm_variable(end, a.tab_variable.Bus=="B008" & ismember(a.tab_variable.Kind,["Vre","Vim"]))));
    % 別の事象の区切りがあるときのスカラー fault
    a2 = n.simulate([0,3], fault(n,"B008",1), odeEventSet("x",n,"TimeSpan",[1.5,2],"InputUnit","SG1B002","InputName","Pmech","InputValue",0));
    fprintf("スカラー fault と別事象 [1.5,2]: t=1.2 の B008 |V|=%.3e, t=1.7 の B008 |V|=%.3e\n", bus_v(a2,"B008",1.2), bus_v(a2,"B008",1.7));
    % 逆順 TimeSpan の事象は効くか
    a = n.simulate([0,3], fault(n,"B008",[2,1]));
    fprintf("TimeSpan=[2,1] の応答と外乱なしの差: %.3e\n", sim_diff(a,s0));
    % AVR の tag の trip は効くか
    n2 = build("IEEE14bus");
    a = n2.simulate([0,3], odeEventSet("t", n2, "TimeSpan", [1,1.2], "TripUnit", string(n2.a_Bus{1}.a_Component{1}.a_LocalController{1}.str_tag)));
    fprintf("AVR の tag の trip の応答と外乱なしの差: %.3e\n", sim_diff(a, n2.simulate([0,3])));

    % 5-4 ソルバ指定が効くか
    fprintf("### 5-4 Solver 指定が実際に効くか (IEEE9bus, fault B007, time=[0,3])\n");
    fprintf("指定|flag|n_t|sum(rv_t)|options.Solver|ode15s(既定)と時刻が一致|結果\n");
    n = build("IEEE9bus");
    ev = fault(n,"B007");
    s_ref = n.simulate([0,3], ev);
    c_s = { ...
        "Solver=ode15s",  kv("Solver","ode15s"); ...
        "Solver=ode23t",  kv("Solver","ode23t"); ...
        "Solver=ode23tb", kv("Solver","ode23tb"); ...
        "Solver=ode23s",  kv("Solver","ode23s"); ...
        "Solver=ode45",   kv("Solver","ode45"); ...
        "Solver=stiff",   kv("Solver","stiff"); ...
        "Solver=auto",    kv("Solver","auto"); ...
        "Solver=ode23t + SolverOptions=ODE23t",   kv("Solver","ode23t","SolverOptions",matlab.ode.options.ODE23t); ...
        "Solver=ode23tb + SolverOptions=ODE23tb", kv("Solver","ode23tb","SolverOptions",matlab.ode.options.ODE23tb); ...
        "Solver=ode23s + SolverOptions=ODE23s",   kv("Solver","ode23s","SolverOptions",matlab.ode.options.ODE23s); ...
        "Solver=ode45 + SolverOptions=ODE45",     kv("Solver","ode45","SolverOptions",matlab.ode.options.ODE45); ...
        "SolverOptions=ODE23t のみ",               kv("SolverOptions",matlab.ode.options.ODE23t); ...
        "Solver=ode23t + SolverOptions=ODE15s",   kv("Solver","ode23t","SolverOptions",matlab.ode.options.ODE15s); ...
        "Solver=ode15s + SolverOptions=ODE23t",   kv("Solver","ode15s","SolverOptions",matlab.ode.options.ODE23t)};
    for i = 1:size(c_s,1)
        try
            nv = c_s{i,2};
            [~, r, f] = evalc_sim(@() n.simulate([0,3], ev, nv{:}, TimeLimit=30));
            fprintf("%s|%d|%d|%.6f|%s|%d|OK\n", c_s{i,1}, f, numel(r.rv_t), sum(r.rv_t), string(r.options.Solver), isequal(r.rv_t, s_ref.rv_t));
        catch me
            fprintf("%s|-|-|-|-|-|ERR %s: %s\n", c_s{i,1}, me.identifier, first_line(me.message));
        end
    end
    % 保存された既定値として指定
    n3 = build("IEEE9bus");
    n3.solver_ODE.Solver = "ode23t";
    r = n3.simulate([0,3], fault(n3,"B007"));
    fprintf("net.solver_ODE.Solver=ode23t と保存: n_t=%d, ode15s と時刻が一致=%d, options.Solver=%s\n", numel(r.rv_t), isequal(r.rv_t, s_ref.rv_t), string(r.options.Solver));
    % 初期化していないとき
    n0 = build("IEEE14bus", Init=false);
    try
        n0.simulate([0,1]);
        fprintf("未初期化: エラーにならなかった\n");
    catch me
        fprintf("未初期化: %s: %s\n", me.identifier, first_line(me.message));
    end
end

function v = bus_v(sol, str_bus, t)
    lv = sol.tab_variable.Bus == str_bus & ismember(sol.tab_variable.Kind, ["Vre","Vim"]);
    [tu, iu] = unique(sol.rv_t, "last");
    v = norm(interp1(tu, sol.rm_variable(iu, lv), t));
end

function sv = all_gens(n)
    sv = strings(0,1);
    for i = 1:numel(n.a_Bus)
        cm = n.a_Bus{i}.a_Component;
        for j = 1:numel(cm)
            if isa(cm{j}, "component.generator.abstract")
                sv(end+1,1) = cm{j}.str_tag; %#ok
            end
        end
    end
end

function probe_arg(str_grp, str_name, fcn)
    sol = []; flag = NaN; output = struct("tEnd",NaN,"nPhases",NaN); %#ok
    try
        net = build("IEEE14bus");
        net.solver_ODE.TimeLimit = 30;
        lastwarn("");
        txt = evalc("[sol, flag, output] = fcn(net);");
        [str_w, id_w] = lastwarn;
        fprintf("%s|%s|OK|%d|%g|%d|%d|%s|%s\n", str_grp, str_name, flag, output.tEnd, output.nPhases, numel(sol.rv_t), id_w, ...
            clip(str_w + " " + txt + " / " + first_line(output.message)));
    catch me
        fprintf("%s|%s|ERR|-|-|-|-|%s|%s\n", str_grp, str_name, me.identifier, clip(me.message));
    end
end

function s = clip(s)
    s = regexprep(string(s), "\s+", " ");
    s = strip(s);
    if strlength(s) > 260
        s = extractBefore(s, 261) + "…";
    end
end

function s = first_line(s)
    s = clip(string(s));
end


%% 6 精度
function section_accuracy()
    fprintf("\n## 6 精度の整合\n");
    fprintf("### 6-1 Tolerance と誤差\n");
    fprintf("条件: fault 先頭母線以外 B007/B008, [1,1.05], time=[0,10], ode15s, 基準は Tolerance=1e-10, AbsoluteTolerance=1e-12。時間は3回の中央値\n");
    fprintf("誤差 fin: 終了時刻の x,V の最大差 (補間なし), peak: 全区間の omega の最大|値|の差\n");
    fprintf("net|Tolerance|AbsoluteTolerance|sim中央値[s]|n_t|nRHS|誤差fin|peak差|flag\n");
    for s_net = {struct("n","IEEE9bus","b","B007"), struct("n","IEEE14bus","b","B008"), struct("n","IEEE68bus","b","B001")}
        sn = s_net{1};
        net = build(sn.n);
        ev  = fault(net, sn.b);
        ref = net.simulate([0,10], ev, Tolerance=1e-10, AbsoluteTolerance=1e-12);
        c_tol = {1e-3,1e-6; 1e-4,1e-6; 1e-5,1e-6; 1e-6,1e-6; 1e-7,1e-6; 1e-4,1e-8; 1e-6,1e-8; 1e-8,1e-10};
        if sn.n == "IEEE68bus"
            c_tol = {1e-3,1e-6; 1e-4,1e-6; 1e-6,1e-8};
        end
        for k = 1:size(c_tol,1)
            r = c_tol{k,1};  a = c_tol{k,2};
            run = @() net.simulate([0,10], ev, Tolerance=r, AbsoluteTolerance=a);
            t = median_time(run, 3);
            [sol, flag] = run();
            [n_rhs, ~, ~] = profile_counts(run);
            lv = sim_columns(sol.tab_variable);
            fin = max(abs(sol.rm_variable(end,lv) - ref.rm_variable(end,lv)));
            lo  = sol.tab_variable.Name == "omega";
            pk  = abs(max(abs(sol.rm_variable(:,lo)), [], "all") - max(abs(ref.rm_variable(:,lo)), [], "all"));
            fprintf("%s|%g|%g|%.3f|%d|%d|%.3e|%.3e|%d\n", sn.n, r, a, t, numel(sol.rv_t), n_rhs, fin, pk, flag);
        end
    end
    % ソルバ間
    net = build("IEEE9bus");
    ev = fault(net,"B007");
    for c_tol = {{1e-4,1e-6},{1e-8,1e-10}}
        o = c_tol{1};
        a = net.simulate([0,10], ev, Solver="ode15s", Tolerance=o{1}, AbsoluteTolerance=o{2});
        b = net.simulate([0,10], ev, Solver="ode23t", SolverOptions=matlab.ode.options.ODE23t, Tolerance=o{1}, AbsoluteTolerance=o{2});
        lv = sim_columns(a.tab_variable);
        fprintf("ode15s vs ode23t (IEEE9, Tolerance=%g): 終了時刻の差 %.3e, 補間比較の差 %.3e, n_t %d / %d\n", o{1}, max(abs(a.rm_variable(end,lv)-b.rm_variable(end,lv))), sim_diff(a,b), numel(a.rv_t), numel(b.rv_t));
    end

    fprintf("### 6-2 線形化応答と小外乱応答\n");
    fprintf("条件: t=0 に状態 offset, 非線形は Tolerance=1e-8, AbsoluteTolerance=1e-10, time=[0,10]\n");
    fprintf("線形: 線形化ブロックを代数消去し E\\(Axx-Axv*inv(Avv)*Avx) の expm で自由応答 (get_ss は使わない)。比較は t>=0.05 の x と V\n");
    fprintf("net|unit/state|offset|最大偏差(線形)|最大差|相対誤差|相対誤差/offset\n");
    for str_net = ["IEEE9bus","IEEE14bus"]
        net = build(str_net);
        res = net.linearize();
        fprintf("%s: rcond(E)=%.3e, rcond(Avv)=%.3e, tab 一致=%d, 平衡点の最大|実部| 固有値 (右端3つ)=", str_net, rcond(full(res.rm_E)), rcond(full(res.rm_Avv)), isequal(res.tab_variable, net.get_variable_map()));
        [A, iv_d, A_alg] = reduced_A(res);
        e = sort(real(eig(A)), "descend");
        fprintf("%s, 微分状態 %d / 状態 %d\n", mat2str(e(1:3)', 4), numel(iv_d), size(res.rm_E,1));
        tab = res.tab_variable;
        iv_x = find(tab.Kind == "x");
        iv_v = find(tab.Kind == "Vre" | tab.Kind == "Vim");
        for str_state = ["delta","omega"]
            for r_eps = [1e-4, 1e-3, 1e-2, 1e-1]
                ev = odeEventSet("os", net, "TimeSpan", 0, "OffsetUnit", "SG1B002", "OffsetState", str_state, "OffsetValue", r_eps);
                sol = net.simulate([0,10], ev, Tolerance=1e-8, AbsoluteTolerance=1e-10);
                lvx = tab.Owner(iv_x) == "SG1B002" & tab.Name(iv_x) == str_state;
                z0 = double(lvx(iv_d))*r_eps;
                lt = sol.rv_t >= 0.05;
                tg = sol.rv_t(lt);
                Z = A_alg * lin_response(A, z0, tg);     % 全状態へ戻す
                V = -(res.rm_Avv \ (res.rm_Avx * Z));
                sim_x = sol.rm_variable(lt, iv_x) - res.rv_point(iv_x)';
                sim_v = sol.rm_variable(lt, iv_v) - res.rv_point(iv_v)';
                d = max(abs([sim_x - Z', sim_v - V']), [], "all");
                m = max(abs([Z; V]), [], "all");
                fprintf("%s|SG1B002/%s|%g|%.3e|%.3e|%.3e|%.3e\n", str_net, str_state, r_eps, m, d, d/m, d/m/r_eps);
            end
        end
    end

    % get_ss の座標と比較 (Kron)
    net = build("IEEE9bus");
    res = net.linearize();
    A = reduced_A(res);
    try
        sys = res.get_ss("Kron");
        e1 = eig(sys);
        e1 = e1(isfinite(e1));
        e2 = eig(A);
        fprintf("get_ss(Kron) の有限固有値 %d 個 vs 手元の代数消去 %d 個: 実部の右端の差 %.3e, 各固有値の最近傍との最大距離 %.3e\n", numel(e1), numel(e2), abs(max(real(e1)) - max(real(e2))), max(arrayfun(@(z) min(abs(e1 - z)), e2)));
    catch me
        fprintf("get_ss(Kron) 比較不可: %s\n", me.message);
    end
end

function [A, iv_d, T] = reduced_A(res)
    % E z' = F z, F = Axx - Axv*inv(Avv)*Avx。E の零行に対応する代数的な状態も消去する
    % A: 微分状態の行列, iv_d: 微分状態の添字, T: 微分状態 -> 全状態の写像
    E = res.rm_E;
    F = res.rm_Axx - res.rm_Axv*(res.rm_Avv\res.rm_Avx);
    lv_d = any(E ~= 0, 2);
    iv_d = find(lv_d);
    iv_a = find(~lv_d);
    Fda = F(iv_d, iv_a);
    Faa = F(iv_a, iv_a);
    Fad = F(iv_a, iv_d);
    A = E(iv_d, iv_d) \ (F(iv_d, iv_d) - Fda*(Faa\Fad));
    T = zeros(size(F,1), numel(iv_d));
    T(iv_d, :) = eye(numel(iv_d));
    T(iv_a, :) = -(Faa\Fad);
end

function Z = lin_response(A, z0, tg)
    % 等間隔でない時刻の自由応答。固有値分解が悪条件のときも expm を使えるよう逐次計算する
    Z = zeros(numel(z0), numel(tg));
    z = expm(A*tg(1))*z0;
    Z(:,1) = z;
    for k = 2:numel(tg)
        dt = tg(k) - tg(k-1);
        if dt > 0
            z = expm(A*dt)*z;
        end
        Z(:,k) = z;
    end
end
