function results = run_all(opt)
% 機能別デバッグテスト (+DebugScript/test_F*.m) をまとめて実行し、結果を一覧表示する
%
%   DebugScript.run_all
%   DebugScript.run_all("Features", ["F2","F3"])
%   results = DebugScript.run_all("FailOnUnexpected", false);
%
% バッチ実行:
%   matlab -batch "cd <GUILDAのフォルダ>; DebugScript.run_all"
%
% 実行の流れ
%   1. GUILDA の起動処理 (パス追加・キーマップ生成) を行う
%      ※ バッチ実行ではチュートリアル (Main.mlx) を開けずにエラーになるため、
%        そのエラーは無視して続行する (test_F9_environment の既知の不具合)。
%   2. testsuite("DebugScript") で test_F*.m の各 %% セクションをテストとして取得
%   3. 機能ごとに実行し、PASS / FAIL / KNOWN (既知の不具合) / FIXED? を表示
%      KNOWN  : DebugScript.known_failures に登録済みの失敗 (理由を表示)
%      FAIL   : 想定外の失敗 (要調査)
%      FIXED? : 既知の不具合として登録されているのに成功したテスト (登録の見直しが必要)
%      SKIP   : 前提 (任意のツールなど) が無いため実行しなかったテスト。テストの中で
%               error("DebugScript:Skip", "理由") を投げると SKIP になる (失敗に数えない)
%
% 対話操作が必要な機能 (GUILDA.setting など) は manual_F9_interactive.m で手動確認する。
%
% オプション
%   Features         : 実行する機能 ("F1"〜"F10")
%   Verbose          : true のとき GUILDA の表示をそのまま出す (既定 false: ログファイルへ保存)
%   FailOnUnexpected : true のとき想定外の失敗があれば最後に error にする (バッチの終了コード用)
%   LogFile          : 抑制した出力の保存先

    arguments
        opt.Features         (1,:) string  = "F" + (1:10)
        opt.Verbose          (1,1) logical = false
        opt.FailOnUnexpected (1,1) logical = true
        opt.LogFile          (1,1) string  = fullfile(tempdir, "GUILDA_DebugScript_" + string(datetime("now","Format","uuuuMMdd_HHmmss")) + ".log")
    end

    import matlab.unittest.TestRunner
    import matlab.unittest.plugins.DiagnosticsRecordingPlugin

    % GUILDA のフォルダへ移動 (GUILDA.dictionary などは現在のフォルダを使う)
    str_root = fileparts(fileparts(mfilename("fullpath")));
    str_cwd  = pwd;
    cd(str_root);
    c_cwd = onCleanup(@() cd(str_cwd));

    % 図は表示しない
    fig_vis = get(0, "DefaultFigureVisible");
    set(0, "DefaultFigureVisible", "off");
    c_fig = onCleanup(@() set(0, "DefaultFigureVisible", fig_vis));

    % GUILDA の起動
    log = "";
    try
        log = log + evalc("GUILDA;");
    catch ME
        log = log + newline + "GUILDA startup error (ignored): " + ME.message + newline;
        fprintf(2, "WARNING: GUILDA の起動処理でエラー: %s\n", strtok(ME.message, newline));
    end

    % 必要な Toolbox の確認 (無いと潮流計算・線形化のテストが失敗する)
    req = ["fsolve", "Optimization Toolbox"; "ss", "Control System Toolbox"];
    for k = 1:size(req,1)
        if ~exist(req(k,1), "file")
            fprintf(2, "WARNING: %s がありません (%s)。多くのテストが失敗します。\n", req(k,2), req(k,1));
        end
    end

    % テストの取得
    suite = testsuite("DebugScript");
    str_file    = string({suite.TestParentName});
    str_file    = erase(str_file, "DebugScript.");
    str_feature = extractBetween(str_file, "test_", "_");
    lv_run      = ismember(str_feature, opt.Features);
    suite = suite(lv_run);  str_file = str_file(lv_run);  str_feature = str_feature(lv_run);
    if isempty(suite)
        error("DebugScript:NoTests", "Features = [%s] に該当するテストがありません (例: [""F1"",""F2""])。", join(opt.Features, ","));
    end

    tab_known = DebugScript.known_failures();

    runner = TestRunner.withNoPlugins;
    runner.addPlugin(DiagnosticsRecordingPlugin);

    % 機能ごとに実行
    rows = cell(0,1);
    t_all = tic;
    for f = unique(str_file, "stable")
        lv  = str_file == f;
        sub = suite(lv);
        fprintf("[%s] %s (%d tests) ... ", str_feature(find(lv,1)), f, numel(sub));
        t_f = tic;
        if opt.Verbose
            res = runner.run(sub);
        else
            res = [];
            log = log + evalc("res = runner.run(sub);");
        end
        fprintf("%.1f s\n", toc(t_f));
        for i = 1:numel(res)
            rows{end+1,1} = classify(res(i), str_feature(find(lv,1)), f, tab_known); %#ok<AGROW>
        end
    end
    results = vertcat(rows{:});
    t_total = toc(t_all);

    % ログの保存
    if ~opt.Verbose
        fid = fopen(opt.LogFile, "w", "n", "UTF-8");
        if fid > 0
            fprintf(fid, "%s", log);
            fclose(fid);
        end
    end

    print_summary(results, t_total, opt);

    if opt.FailOnUnexpected && any(results.Result == "FAIL")
        error("DebugScript:UnexpectedFailure", "%d 件の想定外の失敗があります。", sum(results.Result == "FAIL"));
    end
    if nargout == 0
        clear results
    end
end


function row = classify(res, str_feature, str_file, tab_known)
    str_test = string(extractAfter(res.Name, "/"));
    str_key  = str_file + "/" + str_test;
    lv_known = tab_known.Test == str_key;

    msg = "";
    str_id = "";
    if res.Failed || res.Incomplete
        rec = res.Details.DiagnosticRecord;
        if ~isempty(rec)
            if isprop(rec(1), "Exception")
                msg    = string(rec(1).Exception.message);
                str_id = string(rec(1).Exception.identifier);
            else
                msg = string(rec(1).Report);
            end
        end
        msg = strtrim(strtok(msg, newline));
    end

    if ~res.Passed && str_id == "DebugScript:Skip"
        str_result = "SKIP";
    elseif res.Passed
        if any(lv_known)
            str_result = "FIXED?";
            msg = "既知の不具合として登録済みだが成功: " + tab_known.Reason(find(lv_known,1));
        else
            str_result = "PASS";
        end
    else
        if any(lv_known)
            str_result = "KNOWN";
            msg = tab_known.Reason(find(lv_known,1)) + "  [" + msg + "]";
        else
            str_result = "FAIL";
        end
    end
    row = table(string(str_feature), str_test, str_result, res.Duration, msg, ...
                'VariableNames', ["Feature","Test","Result","Time","Message"]);
end


function print_summary(results, t_total, opt)
    bar = string(repmat('=',1,110));
    disp(" ")
    disp(bar)
    disp("  GUILDA DebugScript summary")
    disp(bar)
    w = max(strlength(results.Test)) + 2;
    fmt = "%-4s %-" + w + "s %-7s %7.2fs  %s\n";
    for i = 1:height(results)
        msg = results.Message(i);
        if strlength(msg) > 140
            msg = extractBefore(msg, 138) + "..";
        end
        fprintf(fmt, results.Feature(i), results.Test(i), results.Result(i), results.Time(i), msg);
    end
    disp(bar)

    n = @(s) sum(results.Result == s);
    fprintf("  合計 %d 件: PASS %d / KNOWN %d / FAIL %d / FIXED? %d / SKIP %d   (%.0f s)\n", ...
            height(results), n("PASS"), n("KNOWN"), n("FAIL"), n("FIXED?"), n("SKIP"), t_total);

    % 機能ごとの集計
    for f = unique(results.Feature)'
        r = results(results.Feature == f, :);
        fprintf("    %s: PASS %2d  KNOWN %2d  FAIL %2d  FIXED? %d  SKIP %d\n", f, ...
                sum(r.Result=="PASS"), sum(r.Result=="KNOWN"), sum(r.Result=="FAIL"), sum(r.Result=="FIXED?"), sum(r.Result=="SKIP"));
    end

    if n("FAIL") == 0 && n("FIXED?") == 0
        disp("  => 既知の不具合を除き、すべて成功しました (all green except known failures)")
    elseif n("FAIL") > 0
        disp("  => 想定外の失敗があります。FAIL の行を確認してください。")
    end
    if n("FIXED?") > 0
        disp("  => FIXED? のテストは修正済みの可能性があります。known_failures.m から削除してください。")
    end
    if ~opt.Verbose
        disp("  GUILDA の表示はログに保存: " + opt.LogFile)
    end
    disp(bar)
end
