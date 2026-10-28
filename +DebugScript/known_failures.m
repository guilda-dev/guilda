function tab = known_failures()
% 既知の不具合で失敗するテストの一覧 (テスト名 → 理由)
%
%   tab = DebugScript.known_failures()
%
% テストは「正しい動作」を assert しているため、製品コードの不具合が直るまで失敗する。
% run_all はここに登録されたテストの失敗を KNOWN として、想定外の失敗 (FAIL) と分けて表示する。
% 不具合を修正したら該当行を削除すること (残っていると run_all が FIXED? と表示する)。
%
% テスト名は "<ファイル名>/<セクション名から作られる名前>"。
% 名前は DebugScript.run_all の一覧、または {testsuite("DebugScript").Name} で確認できる。

    list = [
    % ---- F1 model building ----------------------------------------------------------------------
    "test_F1_model_building/AddBranchByBusTag",                  "add_branch.m:31 が未定義の変数 net を参照 (obj.a_Bus であるべき)"
    "test_F1_model_building/RemoveBus",                          "remove_bus は PowerNetwork.m で宣言のみで実装ファイルが無い"
    "test_F1_model_building/RemoveGlobalController",             "remove_global_controller は PowerNetwork.m で宣言のみで実装ファイルが無い"
    "test_F1_model_building/AddLocalControllerLQR",              "controller.local_LQR は v3 の LocalController API のまま (抽象クラス扱い)。v4 では制御器の入力は機器の出力 Y (発電機は omega のみ) で、add_local_controller も key が avr/pss の制御器しか保持しないため、状態フィードバックの LQR を移植するには契約の決定が必要"
    "test_F1_model_building/AGCDefaultParametersCoverAllControlledUnits", "broadcast_PI_AGC の alpha/beta 既定値がスカラーで、複数台制御時にパラメータ行数 (1) と制御対象数が合わず tab_parameter がエラー"
    "test_F1_model_building/TwoGlobalControllersAreInitialized", "initialize / odeSimulator / odeEventSet が a_GlobalController{1} しか扱わない"
    % ---- F2 power flow --------------------------------------------------------------------------
    "test_F2_powerflow/DynamicModeReachesTheAlgebraicSolution",  "solve_dynamic が PV 母線の電圧を V ではなく V0 (初期値) に固定する"
    % ---- F3 initialize --------------------------------------------------------------------------
    "test_F3_initialize/InitializeReturnsFlagTableOutput",       "initialize.m が calculate_powerflow の出力を [tab, output, flag] の順で受けている (flag と output が逆)"
    "test_F3_initialize/InitializeWithOptimalPowerflow",         "optimize_powerflow が失敗 (F4 参照)。さらに initialize は戻り値の順序も誤っている"
    "test_F3_initialize/InitializeFromXequilibrium",             "initialize.m に ""calculate from Xequilibrium"" の分岐が無く tab_PFsol が未定義"
    % ---- F4 OPF ---------------------------------------------------------------------------------
    "test_F4_opf/EconomicLoadDispatch",                          "build_opf_problem が tab_parameter.OPF 列を参照するが存在しない。結果整形も削除済み Cubicle (a_Cubicle, str_ConnectType) を参照"
    "test_F4_opf/DCOptimalPowerFlow",                            "build_opf_problem が tab_parameter.OPF 列を参照するが存在しない。結果整形も削除済み Cubicle を参照"
    "test_F4_opf/ACOptimalPowerFlow",                            "build_opf_problem が tab_parameter.OPF 列を参照するが存在しない。結果整形・@Branch/build_opf_problem も削除済み Cubicle を参照"
    % ---- F5 CPF ---------------------------------------------------------------------------------
    "test_F5_cpf/LegacyEntryContinuation_Power_Flow",            "Continuation_Power_Flow(net,opt) が opt を名前-値引数の関数へ位置引数で渡すため必ずエラー"
    % ---- F6 time simulation ---------------------------------------------------------------------
    "test_F6_simulation/SimulateWithoutEvents",                  "イベント無しの simulate で odeEventSet.table ではなく組み込みの table が呼ばれエラー"
    "test_F6_simulation/OffsetStateAfterTimeZero",               "OffsetState は最初の区間 (TimeSpan 0) でしか初期値に反映されず、t>0 のオフセットは無視される"
    % ---- F8 utilities ---------------------------------------------------------------------------
    "test_F8_utilities/IEEE14busGeneratorLimitsAreNumbers",     "IEEE14bus の CSV で Pmin/Qmin が ""#NAME?"" (Excel で -Inf が壊れた値) になっており NaN として読まれる"
    % ---- F9 environment -------------------------------------------------------------------------
    "test_F9_environment/GUILDAStartsInBatchMode",               "起動時に Tutorial 設定が true だと Main.mlx を open し、デスクトップの無いバッチ実行ではエラーになる"
    ];
    tab = table(list(:,1), list(:,2), 'VariableNames', ["Test","Reason"]);
end
