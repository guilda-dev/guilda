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
    "test_F1_model_building/ReplaceComponent",                   "replace_component が PowerNetwork.tab_parameter.base.Hz を参照するが base 列が無い"
    "test_F1_model_building/RemoveBus",                          "remove_bus は PowerNetwork.m で宣言のみで実装ファイルが無い"
    "test_F1_model_building/RemoveGlobalController",             "remove_global_controller は PowerNetwork.m で宣言のみで実装ファイルが無い"
    "test_F1_model_building/AddLocalControllerLQR",              "controller.local_LQR は v3 の LocalController API のままで抽象クラス扱い (インスタンス化不可)"
    "test_F1_model_building/EditLogRecordsOnlyChangedParameters","Parameter.callbackPostSet が NaN~=NaN を変更とみなし、未変更の NaN パラメータ (Xaxis 等) も編集ログに残る"
    "test_F1_model_building/AGCDefaultParametersCoverAllControlledUnits", "broadcast_PI_AGC の alpha/beta 既定値がスカラーで、複数台制御時にパラメータ行数 (1) と制御対象数が合わず tab_parameter がエラー"
    "test_F1_model_building/TwoGlobalControllersAreInitialized", "initialize / odeSimulator / odeEventSet が a_GlobalController{1} しか扱わない"
    % ---- F2 power flow --------------------------------------------------------------------------
    "test_F2_powerflow/DynamicModeReachesTheAlgebraicSolution",  "solve_dynamic が PV 母線の電圧を V ではなく V0 (初期値) に固定する"
    % ---- F3 initialize --------------------------------------------------------------------------
    "test_F3_initialize/InitializeReturnsFlagTableOutput",       "initialize.m が calculate_powerflow の出力を [tab, output, flag] の順で受けている (flag と output が逆)"
    "test_F3_initialize/InitializeFromXequilibrium",             "initialize.m に ""calculate from Xequilibrium"" の分岐が無く tab_PFsol が未定義"
    "test_F3_initialize/EquilibriumOfGen1axis",                  "gen-1axis: Jacobi 関数の引数の数が合わず simulate が ""入力引数が多すぎます"" で失敗"
    "test_F3_initialize/EquilibriumOfGen2axis",                  "gen-2axis: get_equilibrium の呼び出しで ""入力引数が多すぎます"" (initialize で失敗)"
    "test_F3_initialize/EquilibriumOfGenDroop",                  "gen-droop: Jacobi 関数の引数の数が合わず simulate が ""入力引数が多すぎます"" で失敗"
    "test_F3_initialize/EquilibriumOfLoadImpedance",             "load-impedance: fcn_dx の宣言に omega0 が無く f_dx 呼び出しが ""入力引数が多すぎます"""
    "test_F3_initialize/DynamicsParameterEditIsUsedAfterInitialize", "Component.set_odefcn がコンストラクタ時のパラメータを関数ハンドルに固定し、tab_parameter の変更が f_dx に反映されない"
    % ---- F4 OPF ---------------------------------------------------------------------------------
    % ---- F5 CPF ---------------------------------------------------------------------------------
    "test_F5_cpf/LegacyEntryContinuation_Power_Flow",            "Continuation_Power_Flow(net,opt) が opt を名前-値引数の関数へ位置引数で渡すため必ずエラー"
    % ---- F6 time simulation ---------------------------------------------------------------------
    "test_F6_simulation/SimulateWithoutEvents",                  "イベント無しの simulate で odeEventSet.table ではなく組み込みの table が呼ばれエラー"
    "test_F6_simulation/OffsetStateAfterTimeZero",               "OffsetState は最初の区間 (TimeSpan 0) でしか初期値に反映されず、t>0 のオフセットは無視される"
    % ---- F7 linearization -----------------------------------------------------------------------
    "test_F7_linearization/GetSysKron",                          "Component.get_sys が削除済みの JacobiAxx 等 (旧 API) を呼ぶ"
    "test_F7_linearization/GetSysFeedback",                      "Component.get_sys が削除済みの JacobiAxx 等 (旧 API) を呼ぶ"
    "test_F7_linearization/GetSysDAE",                           "Component.get_sys が削除済みの JacobiAxx 等 (旧 API) を呼ぶ"
    "test_F7_linearization/ThreeAlgorithmsGiveSameEigenvalues",  "Component.get_sys が削除済みの JacobiAxx 等 (旧 API) を呼ぶ"
    "test_F7_linearization/NonUnitBus",                          "Component.get_sys が削除済みの JacobiAxx 等 (旧 API) を呼ぶ"
    "test_F7_linearization/WithLocalControllers",                "Component.get_sys が削除済みの JacobiAxx 等 (旧 API) を呼ぶ"
    "test_F7_linearization/WithGlobalController",                "Component.get_sys が削除済みの JacobiAxx 等 (旧 API) を呼ぶ"
    "test_F7_linearization/IEEE14EquilibriumIsStable",           "Component.get_sys が削除済みの JacobiAxx 等 (旧 API) を呼ぶ"
    "test_F7_linearization/odeLinearizerDirectUse",              "Component.get_sys が削除済みの JacobiAxx 等 (旧 API) を呼ぶ"
    % ---- F8 utilities ---------------------------------------------------------------------------
    % ---- F9 environment -------------------------------------------------------------------------
    "test_F9_environment/GUILDAStartsInBatchMode",               "起動時に Tutorial 設定が true だと Main.mlx を open し、デスクトップの無いバッチ実行ではエラーになる"
    ];
    tab = table(list(:,1), list(:,2), 'VariableNames', ["Test","Reason"]);
end
