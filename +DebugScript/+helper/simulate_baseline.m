function sct_report = simulate_baseline(opt)
% simulate の軌道の基準を記録し、現在のコードの軌道と比べる (notes/simulate-redesign.md §8.3)
%
%   DebugScript.helper.simulate_baseline(Mode="record")    % 基準を保存する (S0 で 1 回)
%   DebugScript.helper.simulate_baseline(Mode="compare")   % 現在のコードで計算し、基準と isequaln で比べる
%
% 6 つの例 (IEEE68 の地絡、IEEE68 の LocalController=false の外乱なし、IEEE14 AVR+PSS の解列、
% IEEE14 のブランチ開放、IEEE9 のオフセットと一定値の入力、AGC 付き IEEE14 の GC と観測機器の解列)
% を計算し、rv_t, rm_variable, rm_I, output.phases, flag を比べる。タグは系統から読む。
%
% E2 (notes/branch-status-events.md §4.4) の後の例外は 2 つ:
% - ieee14_open: 開放の行列を作り直すので丸めの分だけ違いうる。isequaln でなければ、同じ時刻の
%   点の rm_variable と rm_I の差の最大値を記録し、ソルバーの Tolerance 以下であることを確かめる
%   (時刻の並びが違うときは基準の時刻へ線形補間して比べる)。
% - agc_trip: 解列した源の規則で 2.5 s (GC が観測する機器の解列) から変わりうる。2.5 s より前
%   (2.5 s の区間の終わりの点まで) を isequaln で比べ、以後の差は記録だけする。
% 基準の MAT はリポジトリの外 (既定 /Users/taku/GUILDA/simulate-baseline/baseline_s0.mat) に置き、
% コミットしない。
%
% simulate と add_scenario の API が S2-S6 で変わっても使い続けるため、API に触れるのは
% 末尾のローカル関数 new_scenario (シナリオの作成) と run_case (simulate の呼び出し) だけにしてある。
% 各手順はこの 2 つの関数の数行だけを書き換える。外乱は sc.add_fault などの便利メソッドで加える。
    arguments (Input)
        opt.Mode (1,1) string {mustBeMember(opt.Mode, ["record","compare"])} = "compare"
        opt.File (1,1) string = "/Users/taku/GUILDA/simulate-baseline/baseline_s0.mat"
        opt.Cases (1,:) string = strings(1,0)   % 計算する例の名前 (空はすべて)
    end
    arguments (Output)
        sct_report  % 例ごとの結果 (Mode="compare" では一致と差の最大値)
    end

    c_case = cases();
    if ~isempty(opt.Cases)
        c_case = c_case(ismember(cellfun(@(c) c.name, c_case), opt.Cases));
    end
    c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none")); %#ok<NASGU>

    sct_run = struct();
    for k = 1:numel(c_case)
        cs = c_case{k};
        fprintf("[simulate_baseline] %s ...\n", cs.name);
        tic;
        sct_run.(cs.name) = run_one(cs);
        fprintf("[simulate_baseline] %s done (%.1f s, %d points)\n", cs.name, toc, numel(sct_run.(cs.name).rv_t));
    end

    if opt.Mode == "record"
        [s_dir, ~, ~] = fileparts(opt.File);
        if ~isfolder(s_dir)
            mkdir(s_dir);
        end
        sct_meta = struct("commit", git_commit(), "date", string(datetime("now")), ...
                          "matlab", string(version()));
        baseline = sct_run;
        save(opt.File, "baseline", "sct_meta");
        fprintf("[simulate_baseline] saved %s (commit %s)\n", opt.File, sct_meta.commit);
        sct_report = sct_run;
        return
    end

    S = load(opt.File, "baseline", "sct_meta");
    fprintf("[simulate_baseline] baseline %s (commit %s)\n", opt.File, S.sct_meta.commit);
    sct_report = struct();
    l_all = true;
    sv_accepted = strings(1, 0);     % cases that are not isequaln but accepted (Tolerance or split)
    for s_name = string(fieldnames(sct_run)).'
        a = sct_run.(s_name);
        b = S.baseline.(s_name);
        cs = c_case{string(cellfun(@(c) c.name, c_case, "UniformOutput", false)) == s_name};
        sct_cmp = struct();
        % phases の列名は旧タグを新しいタグに読み替える (notes/branch-status-events.md §3.6, §4.4):
        % fault<n> → Fault%03d、trip<n> と open<n> → Parallel%03d (基準の各例は一方だけを使う)
        tab_b = b.phases;
        sv_var = string(tab_b.Properties.VariableNames);
        for s_old = ["fault", "trip", "open"]
            lv = matches(sv_var, s_old + digitsPattern);
            s_new = "Fault";
            if s_old ~= "fault"
                s_new = "Parallel";
            end
            sv_var(lv) = s_new + compose("%03d", str2double(extractAfter(sv_var(lv), strlength(s_old))));
        end
        tab_b.Properties.VariableNames = sv_var;
        b.phases = tab_b;
        for s_f = ["rv_t","rm_variable","rm_I","phases","flag"]
            sct_cmp.(s_f) = isequaln(a.(s_f), b.(s_f));
        end
        l_same = all(cell2mat(struct2cell(sct_cmp)));
        r = struct("same", l_same, "fields", sct_cmp, ...
                   "maxdiff_t", max_diff(a.rv_t, b.rv_t), ...
                   "maxdiff_variable", max_diff(a.rm_variable, b.rm_variable), ...
                   "maxdiff_I", max_diff(a.rm_I, b.rm_I), "note", "");
        if ~l_same && isfield(cs, "tolerance") && sct_cmp.phases && sct_cmp.flag
            % 丸めの差: 基準の時刻での差 (時刻の並びが違えば補間) を Tolerance と比べる
            r.maxdiff_variable = max_diff(on_grid(a.rv_t, a.rm_variable, b.rv_t), b.rm_variable);
            r.maxdiff_I        = max_diff(on_grid(a.rv_t, a.rm_I, b.rv_t), b.rm_I);
            r_tol = a.options.Tolerance;
            l_same = r.maxdiff_variable <= r_tol && r.maxdiff_I <= r_tol;
            r.note = sprintf("within Tolerance %g: %d (points %d vs %d)", r_tol, l_same, numel(a.rv_t), numel(b.rv_t));
        elseif ~l_same && isfield(cs, "split") && sct_cmp.phases && sct_cmp.flag
            % 解列した源の規則: split より前 (その区間の終わりの点まで) は isequaln、以後は記録
            ka = find(a.rv_t >= cs.split, 1);
            kb = find(b.rv_t >= cs.split, 1);
            l_same = isequal(ka, kb) && isequaln(a.rv_t(1:ka), b.rv_t(1:kb)) ...
                     && isequaln(a.rm_variable(1:ka,:), b.rm_variable(1:kb,:)) && isequaln(a.rm_I(1:ka,:), b.rm_I(1:kb,:));
            r.maxdiff_variable = max_diff(on_grid(a.rv_t(ka+1:end), a.rm_variable(ka+1:end,:), b.rv_t(kb+1:end)), b.rm_variable(kb+1:end,:));
            r.maxdiff_I        = max_diff(on_grid(a.rv_t(ka+1:end), a.rm_I(ka+1:end,:), b.rv_t(kb+1:end)), b.rm_I(kb+1:end,:));
            r.note = sprintf("isequaln before %g s: %d; after: points %d vs %d", cs.split, l_same, numel(a.rv_t)-ka, numel(b.rv_t)-kb);
        end
        r.same = l_same;
        sct_report.(s_name) = r;
        l_all = l_all && l_same;
        if all(cell2mat(struct2cell(sct_cmp)))
            fprintf("[simulate_baseline] %-14s isequaln\n", s_name);
        else
            sr_verdict = ["DIFFERENT", "ACCEPTED"];
            if l_same
                sv_accepted(end+1) = s_name; %#ok<AGROW>
            end
            fprintf("[simulate_baseline] %-14s %s: %s; max |diff| t %g, variable %g, I %g. %s\n", s_name, ...
                    sr_verdict(1 + l_same), ...
                    strjoin(string(fieldnames(sct_cmp)).'+"="+string(cell2mat(struct2cell(sct_cmp))).', ", "), ...
                    r.maxdiff_t, r.maxdiff_variable, r.maxdiff_I, r.note);
        end
        if ~isequal(a.options, b.options)
            fprintf("[simulate_baseline] %-14s note: the solver options differ from the baseline\n", s_name);
        end
    end
    if l_all && isempty(sv_accepted)
        fprintf("[simulate_baseline] all cases isequaln\n");
    elseif l_all
        fprintf("[simulate_baseline] all cases isequaln or ACCEPTED within Tolerance or before the split (accepted: %s)\n", strjoin(sv_accepted, ", "));
    else
        fprintf("[simulate_baseline] SOME CASES DIFFER\n");
    end
end


function c_case = cases()
% 例の一覧: name, 系統を作る関数, 外乱を加える関数, 時間
    c_case = {
        struct("name", "ieee68_fault",   "build", @build_ieee68,        "disturb", @dist_ieee68_fault, "time", [0, 10])
        struct("name", "ieee68_nolc",    "build", @build_ieee68_nolc,   "disturb", @(net, sc) [],      "time", [0, 5])
        struct("name", "ieee14_trip",    "build", @build_ieee14_avrpss, "disturb", @dist_ieee14_trip,  "time", [0, 5])
        struct("name", "ieee14_open",    "build", @build_ieee14,        "disturb", @dist_ieee14_open,  "time", [0, 5], "tolerance", true)
        struct("name", "ieee9_offset",   "build", @build_ieee9,         "disturb", @dist_ieee9_offset, "time", [0, 5])
        struct("name", "agc_trip",       "build", @build_agc,           "disturb", @dist_agc_trip,     "time", [0, 5], "split", 2.5)
    };
end

function sct = run_one(cs)
    net = cs.build();
    DebugScript.helper.quiet(@() net.initialize());
    sc = new_scenario(net, cs.name, cs.time);
    cs.disturb(net, sc);
    [result, flag, output] = run_case(net, sc, cs.time);
    sct = struct("rv_t", result.rv_t, "rm_variable", result.rm_variable, "rm_I", result.rm_I, ...
                 "phases", output.phases, "flag", flag, "options", result.options);
end


%% 系統
function net = build_ieee68()
    net = DebugScript.helper.quiet(@() network.IEEE68bus());
end

function net = build_ieee68_nolc()
    net = DebugScript.helper.quiet(@() network.IEEE68bus(LocalController=false));
end

function net = build_ieee14()
    net = DebugScript.helper.build_ieee14();
end

function net = build_ieee14_avrpss()
% F6 "Fault with local controllers" と同じ構成
    net = DebugScript.helper.build_ieee14();
    for i = 1:2
        net.a_Bus{i}.a_Component{1}.add_local_controller("avr-ST1");
        net.a_Bus{i}.a_Component{1}.add_local_controller("pss-PSS1");
    end
end

function net = build_ieee9()
    net = DebugScript.helper.quiet(@() network.IEEE9bus());
end

function net = build_agc()
% F18 の構成: IEEE14 の母線 1, 2 の発電機を制御する agc-PI
    net = DebugScript.helper.build_ieee14();
    net.add_global_controller("agc-PI", {net.a_Bus{1}.a_Component{1}, net.a_Bus{2}.a_Component{1}});
end


%% 外乱 (便利メソッドは S0-S6 で変わらない)
function dist_ieee68_fault(net, sc)
    sc.add_fault(net.a_Bus{8}.s_tag, [1, 1.07]);
end

function dist_ieee14_trip(net, sc)
    sc.add_trip(net.a_Bus{3}.a_Component{1}.s_tag, [1, 1.2]);
end

function dist_ieee14_open(net, sc)
    sc.add_open_branch(net.a_Branch{3}.s_tag, [1, 3]);
end

function dist_ieee9_offset(net, sc)
    sc.add_offset(net.a_Bus{1}.a_Component{1}.s_tag, "delta", 0.1, 0);
    sc.add_input(net.a_Bus{2}.a_Component{1}.s_tag, "Pmech", 0.05, [1, 3]);
end

function dist_agc_trip(net, sc)
    sc.add_trip(net.a_GlobalController{1}.s_tag, [1, 2]);       % GC の解列
    sc.add_trip(net.a_Bus{2}.a_Component{1}.s_tag, [2.5, 3]);   % GC が観測・制御する機器の解列
end


%% API に触れる箇所 (S2-S6 はここだけを書き換える)
function sc = new_scenario(net, s_tag, time)
% 時間だけを持つシナリオを系統に作る
    sc = net.add_scenario(s_tag, Time=time);
end

function [result, flag, output] = run_case(net, sc, time)
% シナリオを時間 time で計算する
    [result, flag, output] = DebugScript.helper.quiet(@() net.simulate(sc.s_tag, Time=time, Progress="none"));
end


%% 補助
function M = on_grid(rv_t, M, rv_tb)
% 時刻 rv_t の値 M を時刻 rv_tb の値にする (同じ並びならそのまま、違えば区間ごとに線形補間。
% 区間は重複した境界の時刻で分け、両方の区間の数が違えば NaN)
    arguments (Input)
        rv_t  (:,1) double  % 値の時刻 (増加、境界は重複)
        M     double        % 値 (時刻ごとに 1 行)
        rv_tb (:,1) double  % 求める時刻
    end
    arguments (Output)
        M     double        % rv_tb の各時刻の値
    end
    if isequal(rv_t, rv_tb)
        return
    end
    iv_seg  = cumsum([1; diff(rv_t) == 0]);
    iv_segb = cumsum([1; diff(rv_tb) == 0]);
    M_in = M;
    M = NaN(numel(rv_tb), size(M_in,2));
    if iv_seg(end) ~= iv_segb(end)
        return
    end
    for k = 1:iv_seg(end)
        lv = iv_seg == k;
        lvb = iv_segb == k;
        if nnz(lv) == 1
            M(lvb,:) = repmat(M_in(lv,:), nnz(lvb), 1);
        else
            M(lvb,:) = interp1(rv_t(lv), M_in(lv,:), rv_tb(lvb), "linear", "extrap");
        end
    end
end

function d = max_diff(a, b)
    if ~isequal(size(a), size(b))
        d = NaN;
        return
    end
    m = abs(a - b);
    m = m(~(isnan(a) & isnan(b)));
    d = max([m(:); 0]);
end

function s = git_commit()
    [st, out] = system("git -C """ + fileparts(mfilename("fullpath")) + """ rev-parse HEAD");
    s = "unknown";
    if st == 0
        s = strtrim(string(out));
    end
end
