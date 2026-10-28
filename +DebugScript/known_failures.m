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
    "test_F1_model_building/AddLocalControllerLQR",              "controller.local_LQR は v3 の LocalController API のまま (抽象クラス扱い)。v4 では制御器の入力は機器の出力 Y (発電機は omega のみ) で、add_local_controller も key が avr/pss の制御器しか保持しないため、状態フィードバックの LQR を移植するには契約の決定が必要"
    "test_F1_model_building/AGCDefaultParametersCoverAllControlledUnits", "broadcast_PI_AGC の alpha/beta 既定値がスカラーで、複数台制御時にパラメータ行数 (1) と制御対象数が合わず tab_parameter がエラー"
    "test_F1_model_building/TwoGlobalControllersAreInitialized", "initialize / odeSimulator / odeEventSet が a_GlobalController{1} しか扱わない"
    % ---- F2 power flow --------------------------------------------------------------------------
    % ---- F3 initialize --------------------------------------------------------------------------
    % ---- F4 OPF ---------------------------------------------------------------------------------
    % ---- F5 CPF ---------------------------------------------------------------------------------
    % ---- F6 time simulation ---------------------------------------------------------------------
    % ---- F8 utilities ---------------------------------------------------------------------------
    % ---- F9 environment -------------------------------------------------------------------------
    ];
    tab = table(list(:,1), list(:,2), 'VariableNames', ["Test","Reason"]);
end
