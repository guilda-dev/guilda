# 再設計の状況

この文書の基準は `feature/ieej-report-models` の `301b5d0`、日付は 2026-11-04 です。このブランチは統合ブランチ `refactor/design-alignment`(分岐元 `version4.0`)を `1223c6a` まで取り込み、IEEJ の報告書モデルの作業を加えたものです。`refactor/design-alignment` は 2 回に分けて取り込みました。

- **`8bbd9a0` まで(マージ `b2a46e8`):** 解析クラスの役割を先にした名前(`c51e1ea`、`SolverPF`、`ResultODE` など)と、開発者向け文書の日英切り替え(`cf42421`)です。イベントのクラスはこのブランチの `Scenario` を残し、`c51e1ea` の `EventODE` は取り込んでいません。
- **`1223c6a` まで(マージ `301b5d0`):** 開発者ページの日本語訳と、新しい `feature-*.html`・`class-*.html` のページ(約 36 コミット)です。下の「開発者ページの統合」を参照してください。

移行の方法は [v4-migration.md](v4-migration.md) にあります。この文書には、テスト結果、未決事項、数値の変化の記録を書きます。

## テスト

**確認済み(2026-11-04、MATLAB R2026a):** 想定外の失敗はありません。

- `301b5d0`(`refactor/design-alignment` の `1223c6a` のマージ)での `DebugScript.run_all`: 684 件、PASS 682 / KNOWN 1 / FAIL 0 / FIXED? 0 / SKIP 1、960 s。機能別の件数は下の表と同じです。このマージとその後の 3 つの `docs:` コミットは文書とノートだけを変え、コードとテストは `b2a46e8` と同じです。
- `a9afe24` での `DebugScript.run_all`: 684 件、PASS 682 / KNOWN 1 / FAIL 0 / FIXED? 0 / SKIP 1、851 s(コーディネータの実行。機能別の内訳はこの記録にありません)。
- 下の機能別の表は、`a9afe24` に `docs/ieej-report-models-notes` の変更(F6 のコメント、`_GUILDAverification/` の比較関数と README、notes)を加えた作業ツリーでの再実行です。合計は上と同じです。時間は他の MATLAB 3 つと並行したためで、目安になりません。

```
合計 684 件: PASS 682 / KNOWN 1 / FAIL 0 / FIXED? 0 / SKIP 1   (968 s)
```

| 機能別 | 件数(PASS) | | Issue 別 | 件数(PASS) |
|---|---:|---|---|---:|
| F1 | 29 | | I50 | 7 |
| F2 | 18 | | I51 | 16 |
| F3 | 46 | | I52 | 10 |
| F4 | 30(他に SKIP 1) | | I53 | 6 |
| F5 | 6 | | I54 | 5 |
| F6 | 40 | | I55 | 8 |
| F7 | 54 | | I56 | 13 |
| F8 | 23 | | I57 | 8 |
| F9 | 12 | | I58 | 5 |
| F10 | 10 | | I60 | 6 |
| F15 | 7 | | I61 | 8 |
| F16 | 27 | | I62 | 15 |
| F17 | 9 | | I63 | 5 |
| F18 | 10 | | I64 | 6 |
| F19 | 13 | | I66 | 11 |
| F21 | 13 | | I67 | 11 |
| F22 | 34(他に KNOWN 1) | | I68 | 4 |
| F24 | 7 | | I69 | 5 |
| F25 | 4 | | I70 | 7 |
| F26 | 2 | | I71 | 11 |
| F27 | 4 | | I89 | 8 |
| F28 | 7 | | I90 | 13 |
| F29 | 13 | | I91 | 7 |
| F30 | 22 | | I92 | 15 |
| F31 | 11 | | I93 | 7 |
| | | | I102 | 6 |
| | | | I105 | 5 |
| | | | I111 | 3 |

- **SKIP:** F4 の `ACAndDCOPFAgreeWithMATPOWEROnIEEE14_bus` です。理由は `MATPOWER (runopf) がパスに無い` です。この比較は実際の MATPOWER ではまだ実行していません。case14 の最適値(8081.53 / 7642.59 $/hr)は MATPOWER なしで検査しています。
- **既知の不具合(KNOWN 1):** F22 の `AVR_DC1WithItsDefaultGainHasAFiniteEquilibrium` です。`AVR_DC1` の既定 `kap = 0` では `Vref = Inf` になり、`simulate` が MATLAB のエラーで止まります(`DebugScript.known_failures`)。
- **追加されたテスト:** F27(park の `Xq_p = Xq`)、F28(`AVR_DC1` の界磁電圧の上下限)、F29(ブランチ開放)、F30(調速機)、F31(`Scenario`)。
- **対話操作:** `+DebugScript/manual_F9_interactive.m` は手動の確認用で、上の結果に含まれません。今回は実行していません。
- **`_GUILDAverification/` は `run_all` に含まれません。** 比較の結果は下の「IEEJ のネットワーク」にあります。

### 再現手順

MATLAB、Control System Toolbox、Optimization Toolbox が必要です。GUILDA のフォルダで次を実行します。`matlab` はお使いの MATLAB の実行ファイルです。約 14 分かかりました(`a9afe24`)。

```
matlab -batch "DebugScript.run_all"
```

`Level` で実行する範囲を選べます。既定は `"large"`(全件)で、上のコマンドの意味は変わりません。medium・large に入るテストは `+DebugScript/test_levels.m` の一覧で決め、一覧にないテストは small です。

- `"small"`: 1 件 1 秒程度までのテスト。変更のたびに実行します。
- `"medium"`: small に加えて 1 件 3 秒程度までのテスト。ブランチをマージする前に実行します。
- `"large"`: 全件。統合ブランチの確認とリリース前に実行します。

```
matlab -batch "DebugScript.run_all('Level','small')"
```

`Features` と組み合わせると、両方に該当するテストだけを実行します(例: `DebugScript.run_all("Features","F7","Level","medium")`)。

## `a9afe24` までに加わった機能

`fe9aa3a`(前回の基準)以後に `feature/ieej-report-models` へ入ったものです。コミットとテストで確認しました。

- **park の `Xq_p = Xq`:** `get_equilibrium` が `Xq - Xq_p` と `Xd - Xd_p` で割らなくなり、q 軸の過渡回路のない機械(IEEJ の LGT=4)を `Xq_p = Xq` で表せます(`4243124`、F27)。
- **`AVR_DC1` の界磁電圧の上下限:** `Vfld_max`(既定 `Inf`)と `Vfld_min`(既定 `-Inf`)。上下限では `Vfld` を止めるワインドアップなしの制限です。既定では軌道も `get_sys` も以前とビット単位で同じです(`8b225d2`、F28)。
- **調速機の枠と IEEJ の調速機:** 機器に `"avr"` / `"local"` の連鎖と並ぶ `"governor"` を付けられます。出力は重なってはならず(`GUILDA:Component:ControllerOutputOverlap`)、順序は連鎖、次に調速機です(`70a59ac`)。`controller.governor.IEEJ_LPT1`, `IEEJ_LPT3`, `IEEJ_LPT4`(`9733ecc`、F30)。[model-building-improvements.md](model-building-improvements.md) の Q12 の決定です。
- **ブランチ開放:** `OpenBranch`(`1d98226`、F29)。区間ごとに Y を作り直します。現在は `sc.add_open_branch` です。
- **`Scenario`(`ODEevent` の置き換え):** 系統が所有するシナリオに外乱、`Time`, `Options`, `Description`, `Judge`(既定 `Scenario.out_of_step`)を持ちます。`Scenario.compile` が区間のデータを 1 回だけ作ります(EV5)。CSV の読み書きもあります。`ODEevent(tag, net, ...)` は `_GUILDAsystem/_VersionSupport/ODEevent.m` で動き、`GUILDA:Deprecated:ODEevent` を警告します(`e543585`, `a116725`, `b870e43`, `ce78de1`、F31)。移行は [v4-migration.md](v4-migration.md) 1.18 です。
- **区間の開始の初期条件:** 微分状態を固定して代数変数だけを解きます。警告 `InitialConditionRelaxed` と緩めた再計算はなくなりました(`8bd906c`、統合は `bf7512b`)。
- **`_GUILDAverification/`:** 同梱ネットワークと文献の比較の置き場所(パスに入れない)。ネットワークごとに `README.md`、シナリオの CSV、報告書の判定の CSV、比較関数があります(`_GUILDAdoc/developer/folder-structure.html`)。

## 開発者ページの統合(2026-11-04)

`301b5d0`(マージ)、`f7c7aa5`、`81caa5f` と、この文書の更新のコミットです。

- **マージの衝突:** `api-design.html`、`class-design.html`、`folder-structure.html`、`model-implementation.html`、`index.html` は、取り込み側の日英の構造と訳を残し、このブランチの変更(`Scenario`、調速機の枠、ブランチ開放、`_GUILDAverification` と全体図)に日本語の兄弟要素を加えて入れ直しました。
- **新しいページの修正:** `feature-simulation.html` は `EventODE` を前提にしていたので、現在の `Scenario` と `SolverODE`(`Scenario.compile`、`check_islands`、`set_admittance`、`set_offsets`、`initial_condition`、`phase_result`)に合わせて書き直しました。`class-powernetwork.html`(`a_Scenario`、`add_scenario`)、`class-component.html`・`class-localcontroller.html`・`feature-model-building.html`(調速機の枠、`ControllerOutputOverlap`、`AVR_DC1` の上下限、`controller.governor`)、`class-bus.html`・`class-globalcontroller.html`(書き込み元から `EventODE` を削除)も直しました。両言語とも直しています。
- **Update log:** 2026-11-02 の「Analysis classes renamed」を決定に合わせました(イベントのクラスは `Scenario`、`ODEevent` は非推奨のラッパー、`EventODE` は公開していない)。2026-11-04 の IEEJ の項目の古い制限(調速機なし、線路開放なしなど)を直し、`Scenario`、ブランチ開放、`AVR_DC1` の上下限、park の `Xq_p = Xq`、調速機、IEEJ の既定、`_GUILDAverification` の項目を加えました。旧 ID `GUILDA:odeEventSet:*` を書いた 2 つの項目には、現在の ID を補いました。
- **確認:** 変更したページは Python の `html.parser` で開き、閉じていないタグがないことを確認しました。ブラウザでの表示は確認していません(未確認)。`list_UpdateLog.js` は Node で読み込めることを確認しました。
- **`dev-pages-code-findings.md`:** 基準 `765663b` のまま `EventODE` の行番号を参照しているので、冒頭に `Scenario` への置き換えの注を加えました。SIM-3 が現在のコードでも成り立つかは未確認です。

## IEEJ のネットワーク

`network.IEEJ_EAST10`, `IEEJ_EAST30`, `IEEJ_WEST10`, `IEEJ_WEST30` は、電気学会の報告書のモデルを既定にしました。調速機あり(`Governor=true`)、励磁の界磁電圧 `EF` は 0〜4 pu(`Vfld_min = 0`, `Vfld_max = 4`)、q 軸は `Xq_p = Xq` です。`Governor=false` で調速機なしにできます。

- **負荷は未決(利用者の作業待ち):** 負荷は今も定インピーダンス(`"load-impedance"`)です。報告書の NLT=2(P は 0.7 pu 以上で定電流、Q は定インピーダンス)は GUILDA にありません。利用者の ZIP 負荷モデルを待っています。
- **報告書の表との一致(各 README の記録。基準 `ae320a0`、2026-11-04、MATLAB R2026a):**

| ネットワーク | 表 | 調速機あり | 調速機なし |
|---|---|---|---|
| EAST10 | 4.3 | 33 / 44 | 35 / 44 |
| EAST30 | 4.9 | 55 / 55 | 55 / 55 |
| WEST10 | 4.5 | 9 / 26 | 9 / 26 |
| WEST30 | 4.13 | 5 / 12 | 5 / 12 |

  調速機ありの 4 つの値は、`docs/ieej-report-models-notes` の作業ツリー(`a9afe24` に比較関数の起動部分の変更を加えたもの)で全件を再実行し、同じ値を確認しました。調速機なしの値は各 README の `ae320a0` の記録です。
- **WEST30:** 平衡点はピークと夜間の両方で不安定です。定電流の P 負荷と調速機を入れたリポジトリ外の試験用のコピーでは 11 / 12 が一致しましたが、再測定していません(未確認)。
- **WEST10:** ピークの不一致の原因は特定していません(13 件中 2 件の一致)。夜間の調速機ありでは、周期 1.97 s のモードがわずかに不安定です(実部 +0.0013。クラスの説明では約 2.0 s と記載)。
- 条件、モデルの違い、事例ごとの結果は `_GUILDAverification/<network>/README.md` にあります。比較関数は、GUILDA を起動したあと `run(fullfile(GUILDA.pwd, "_GUILDAverification", "<network>", "<compare_...>.m"))` で既定の全件を、またはそのフォルダへ `cd` してオプションつきで呼び出します。4 つとも同じ方法で動きます(2026-11-04 に両方の方法で確認)。

## 潮流計算のオプション(手順 B、2026-11-10)

仕様と実装の記録は [powerflow-options.md](powerflow-options.md) にあります(「手順 B の実装」節、「Q3〜Q6 の実装」節)。

- 設定は GUILDA.setting の PowerFlowCalculation セクション、`Tolerance` の既定は全手法で 1e-8、`WarmStart` の既定は true、母線の `V0` / `Varg0` は廃止、`ResultPF.tab_violation` を追加。
- **数値の変化:** フラットスタート・既定の設定で、変更前の解との差は newton で最大 1.4e-10、levenberg-marquardt で 1.1e-8(EAST10 夜間)、dynamic で 3.1e-7(以前の既定 `Tolerance` 1e-5 よりは代数解に近い)。連続潮流計算は変わらない(IEEE14 で λ の差 4e-12)。
- **Q3〜Q6(2026-11-10):** OPF の `WarmStart` の既定は false。`SolverOPF` は OPF の問題をキャッシュし、`PowerNetwork.n_revOPF` で照合(IEEE68 DC OPF 1.0 → 0.2 s、AC OPF 22 → 19 s)。
  fsolve の `FunctionTolerance` と `OptimalityTolerance` は `Tolerance^2`(`Tolerance` 1e-10 の flag -2 と FixedInput の 1.7e-7 での停止を解消)。機器の P・Q の配分は `tools.distribute_power` に統一。
- **要判断:** powerflow-options.md の「手順 B の実装」の要判断 1・2、「Q3〜Q6 の実装」の要判断 1(既定値が既存の環境に届かない件、判断中)。
- **Q1(2026-11-10):** OPF・連続潮流計算・時間応答シミュレーション・線形化の設定も GUILDA.setting(OptimalPowerFlow、ContinuationPowerFlow、TimeSimulation、新設の Linearization)から `get_options` が実行ごとに読む。`net.solver_*` に残るのは条件だけ(`solver_OPF` の `Cost`・`Constraint`・`DefaultCost`・`ReferenceBus`、`solver_CPF` の `LoadBus`)で、削除したプロパティへの代入と v3 互換の `net.solver_ODE.Reporter` はエラー(互換なし)。
- JSON キーを Name-Value 名にそろえた(`OptimalityTolerance`・`RelativeTolerance` → `Tolerance`、`MaxIterations` → `MaxIteration`。ユーザー設定の旧キーは変換せず捨てる)。全解析の呼び出しオプション `Plot` を廃止し、解析中のライブ表示 `PlotFcn` に置換(当面 `"none"` のみ、`tools.check_plotfcn`)。図は `result.Plot()`。移行の説明は [v4-migration.md](v4-migration.md)「解析の設定は GUILDA.setting、`net.solver_*` は条件だけ」。

## GUILDA.setting のコマンドと設定ファイルの version(2026-11-10)

ブランチは `feature/setting-command`(未 push)。

- `GUILDA.setting("カテゴリ", 名前=値, ...)` で、ウィンドウを開かずに設定を変更できる。値は既定の JSON の `Type`(`double`・`logical`・`string`・`select` と `options`)で検証し、未知のカテゴリ・名前や不正な値は何も変えずにエラー(`GUILDA:GUILDA:UnknownSettingCategory`・`UnknownSettingName`・`SettingNameValue`・`InvalidSettingValue`)。保存はウィンドウの Apply と同じ `set_config` で、`GUILDA.config` のキャッシュも読み直す。
- カテゴリ名・設定名の Tab 補完はしない。MATLAB は `@GUILDA` の補完を隣の `resources` フォルダ(リポジトリルート)からしか読まず、ルートにフォルダを増やさないとメンテナーが判断した(2026-11-10)。
- 利用者の JSON には既定ファイルの `version` を書く。`version` が違う・無いカテゴリは既定値で書き直し、INFO(`GUILDA:GUILDA:ConfigReset`)で知らせる。既定値・キー名・構造を変えたら `version` を上げる(class-design.html「設定ファイルとその版」)。これで潮流計算の手順 B の要判断「既定値が既存の環境に届かない件」も、version を上げれば解消する。
- `v3_user_config`(利用者設定の旧キーの変換)は削除した。既定ファイルに `version` が入ると、version のない利用者の JSON はすべて既定値に戻るため、変換の働く場面がない。
- 各 `Default*.json` に `"version": 1` を追加(`feature/plotfcn` のマージ後)。version のない利用者の JSON は既定値に戻るため、PlotFcn の節の移行の注意(保存済みの `MaxIteration` 0 で潮流計算が失敗する)は起きない(F9 で確認)。
- 設定ウィンドウに Type `"string"`(連続潮流計算の `Limits`)の入力欄(カンマ区切り)を追加。これまでは入力欄がなく、前の行の入力欄が動いていた。

## PlotFcn の実装と OPF の `Verbose`(2026-11-10)

仕様と実装の記録は [powerflow-options.md](powerflow-options.md) にあります(「PlotFcn の実装と OPF の `Verbose`」節)。ブランチは `feature/plotfcn`(未 push)。

- `PlotFcn` のキー: 潮流計算 `"residual"`(方程式ごとの残差の棒、全 Solver)、OPF は fmincon のプロット関数(`"fval"` → `optimplotfval` など 7 種。linprog・quadprog は `GUILDA:SolverOPF:PlotFcnUnsupported`)、連続潮流計算 `"pvcurve"`(全母線の PV 曲線を伸ばす)。関数ハンドル `stop = f(x, optimValues, state)` も 3 解析で受け付ける。時間応答シミュレーション・線形化は `"none"` のみのまま。
- 潮流計算の flag に -1(PlotFcn で停止)を追加。OPF の JSON キー `Display` を `Verbose`(logical、既定 false)に置換し、既定ではソルバーは何も表示しない。
- `"none"` では結果が変わらない(5 つの Solver、CPF、AC OPF で一致を確認)。
- **テスト(MATLAB R2026a):** 設定キーの統一の後の `DebugScript.run_all('Level','medium')`(`84dc051b`、コードの最後のコミット)664 件、PASS 662 / KNOWN 1 / FAIL 0 / FIXED? 0 / SKIP 1、457 s。small はコードのコミットごと(`dc089366`、`c9aeaf32`、`2963cc71`、`84dc051b`)に 492〜493 件、FAIL 0(`d3ac4edb`・`03834b69` は該当機能のテストファイルだけ実行)。
  新しい表示のテスト(F2・F4・F5 の `PlotFcn*`、3 秒超のため large に登録)は最後に個別に実行して 4 件 PASS。large 全体は未実行。
- **要判断:** powerflow-options.md の同節の要判断 2〜4(flag -1 の通知など)。
- **設定キーの統一(レビュー後):** 潮流計算に `Verbose` のキー、自動・既定は全解析で NaN、1 つのソルバーの設定は `<Solver 名><オプション名>`(`FsolveMaxFunctionEvaluations`、`LinprogAlgorithm`、`FminconUseParallel` など)、TimeSimulation の `SeparateComplexParts` は logical。対応表は powerflow-options.md の「設定キーの統一」節。
  **移行の注意:** 保存済みの利用者設定に `MaxIteration` 0 が残ると潮流計算が 0 回の反復で失敗する(同節の要判断)。

## 入力を固定した平衡点と Solver / Method の名前(2026-11-10)

仕様と実装の記録は [fixed-input.md](fixed-input.md) にあります(「実装」節)。ブランチは `feature/fixed-input`(未 push)。

- 潮流計算のアルゴリズムは `Solver`(旧 `Method`。JSON キーも)、線形化の縮約は `Method`(旧 `Algorithm`、旧名は警告つきで有効)。
- `Component.set_input` と stale タグ `input`(`net.sct_stale.input`)。`initialize(Method="FixedInput")` は入力を固定して状態・電圧・電流とスラック母線の発電機の Pmech を解く。
- 負荷の `Z` / `PQ_st` を廃止。
- **テスト(MATLAB R2026a):** `DebugScript.run_all('Level','medium')` 655 件、PASS 653 / KNOWN 1 / FAIL 0 / FIXED? 0 / SKIP 1、549 s。large は未実行。
- **要判断:** fixed-input.md の「実装」節の要判断 1〜3(AVR の Vfield も固定されるため負荷を少し増やすと平衡点がない系統がある、など)。

## 潮流計算の構造の見直し(2026-11-12)

仕様と実装の記録、表示メソッドの提案は [powerflow-structure.md](powerflow-structure.md) にあります。ブランチは `refactor/powerflow-structure`(未 push)です。

- `calculate_powerflow` の v3 の呼び出し形式を削除し、オプションは 1 つの `arguments` ブロックで検証します。`SolverPF.OptionMap`・`get_options` はありません(ほかの解析のソルバーは変えていません)。
- `SolverPF.solve(cm_Y, tab_PFcondition, sct_options)` は系統を読みません。方程式のキャッシュはなく、母線タグが一致するときだけウォームスタートを使います。
- `calculate_powerflow` と `initialize` に `Format` を追加しました(既定は `calculate_powerflow` が `"GUILDAorigin"`、`initialize` が `"powerflow(mat)"`)。結果クラスの書き出しのメソッドは `export` です。`calculate_powerflow` の `Export` オプションは削除し、書き出しは `res.export` だけです。`"GUILDAorigin"` の `ResultPF` は `struct(net, false)` のスナップショットとアドミタンス行列から作り、系統のハンドルを持ちません。
- 収束しないときの ID は `GUILDA:PowerNetwork:PowerflowNotConverged` です。
- **テスト(MATLAB R2026a):** small はコードの手順ごと(`6ecc6903`、`847e5b76`、`335c9162`)に FAIL 0(`335c9162` は I69 の修正後に該当テストを再実行)。最後の small 513 件、PASS 511 / KNOWN 1 / FAIL 0 / FIXED? 0 / SKIP 1。medium 688 件、PASS 686 / KNOWN 1 / FAIL 0 / FIXED? 0 / SKIP 1、545 s。追加の 3 手順(`96f131f9` Export の削除、`737c287d` 既定 Format、`254a2602` `Branch.struct`)も small を手順ごとに実行して 513 件中 FAIL 0、最後に medium 688 件、PASS 686 / KNOWN 1 / FAIL 0 / SKIP 1、525 s。その後の 2 手順(`eefdce1b` `export` への改名、n×4 の配列を使う `initialize`)も small を手順ごとに FAIL 0、最後に medium 688 件、PASS 686 / KNOWN 1 / FAIL 0 / SKIP 1、512 s。改名した `export` を使う large のテスト 5 件(F2・F4・F5・F6 の Plot/Export)は個別に実行して PASS。large は未実行。
- 枝潮流は `Branch.struct` がスナップショットに加える `cm_Y` から求めます(案 C)。
- `ResultPF` に `disp_summary`・`disp_bus`・`disp_branch`・`disp_violation` と `plot_voltage`(Vmin・Vmax の線)を追加し、すべての結果クラスの `Plot` を `plot_*` に改名しました(2026-11-12)。`plot_branch`・`plot_convergence`・`plot_network` は後で実装します。テストは `refactor/design-alignment`(`7bc4cd45`)を取り込んだ後、手順ごとの small(`1fad7f64` 512 件、`ec432a62` 514 件)で FAIL 0、最後の medium 689 件、PASS 687 / KNOWN 1 / FAIL 0 / SKIP 1、649 s。改名した plot_* を使う large のテスト 6 件は個別に実行して PASS。
- **未対応:** `_GUILDAtutorial/*.mlx`(保留中のチュートリアルの作業)。`PowerNetwork.n_revY`・`n_revPF` は `refactor/opf-structure` で削除しました(下の節)。

## 最適潮流計算の構造の見直し(2026-11-12)

ブランチは `refactor/opf-structure`(未 push)です。潮流計算と同じ構造にしました。

- `optimize_powerflow` を `calculate_optimal_powerflow` に改名しました(別名なし)。`build_opf_problem` と GUILDA.setting の `OptimalPowerFlow` はそのままです。
- OPF の v3 互換(`v3_opf_args`、`v3_optimize_powerflow`、6 出力、`"methods"`)を削除しました。`legacy_output.m` は F10 のテストが使うので残しています。
- オプションは `calculate_optimal_powerflow` と `build_opf_problem` の `arguments` ブロックで検証します(未知の名前は `MATLAB:TooManyInputs`)。`Cost`・`Constraint`・`DefaultCost`・`ReferenceBus` は呼び出しだけのオプション(既定 `[]`、`[]`、true、`"auto"`)で、`SolverOPF` のプロパティ、`OptionMap`、`get_options`、`Export` は削除しました。関数ハンドルでない値は `GUILDA:PowerNetwork:InvalidOpfHandle` です。
- `@PowerNetwork/private/opf_data.m` が母線・機器・ブランチの 3 つの表、`base`、解決済みの `ReferenceBus` を集めます。`SolverOPF.build_problem` / `solve` は系統を読みません。問題のキャッシュと `PowerNetwork.n_revOPF` は削除し、ウォームスタートは母線タグで照合します。`ResultOPF` は `struct(net, false)` と解から作ります。
- **テスト(MATLAB R2026a):** small を手順ごとに実行して FAIL 0(手順 3 で 512 件、PASS 510 / KNOWN 1 / SKIP 1)。medium 686 件、PASS 684 / KNOWN 1 / FAIL 0 / SKIP 1、856 s。F4 は全段階(37 件 + SKIP 1)を個別に実行して PASS。
- 読むものがなくなった版番号 `PowerNetwork.n_revY`・`n_revPF`・`n_revTopology` と、`handle_edit` のその増分を削除しました。`net.solver_PF` / `net.solver_OPF` のウォームスタートは母線タグで照合します。
- **未対応:** F8 の large のテスト 2 件(`MATFileRoundTripKeepsControllersAndLowerLayers`、`MATPOWERImportReproducesCase14`)は、この作業の前のコミットでも失敗します。

## 未決事項

状態は `a9afe24` のコードと履歴で確認しました(`301b5d0` までの統合はコードを変えていません)(下で日付や基準を別に示した項目を除く)。

### チュートリアル

- **未対応(確認済み):** `_GUILDAtutorial/*.mlx` の最後の変更は 2026-07-24 で、再設計の変更を反映していません。Issue #113「Update the tutorials to the current model building API」は開いています(2026-11-02 に確認)。
- **実行での確認は古い基準のものです:** `df3f709` の調査で、`Step2` と早見表の呼び出しは実行すると失敗しました。`power_network`, `add_controller_global`, `set_component` などの旧 API です(詳細は [model-building-workflow.md](model-building-workflow.md))。`faa2d13` では再実行していません。
- **更新の途中のブランチ:** `docs/tutorial-steps-1-3-v4`, `docs/tutorial-steps-4-6-v4`, `docs/tutorial-classmanual-v4` は仕様が固まるまで保留です。統合ブランチに対して大きく遅れており(`docs/tutorial-steps-1-3-v4` で 375 コミット)、リモートには公開されていません。再開するときは、[v4-migration.md](v4-migration.md) の 1.4, 1.6, 1.12, 1.17 と照合してください。
- **イベントの API:** チュートリアルは今も `odeEventSet` を使っています(`Step4_SimulateCondition.mlx` で確認)。`ODEevent` も `Scenario` も使っていません。#113 の保留中のブランチも含めて、更新するときは [v4-migration.md](v4-migration.md) 1.18 と照合してください。
- **読者への注意:** 現時点で、チュートリアルを v4 の使い方の手本にしないでください。

### モデル実装の文書

- **追加済み(確認済み):** `_GUILDAdoc/developer/model-implementation.html` は `4d1336e` で追加しました。新しいモデルの実装手順、契約、最小の発電機と制御器、`validate` による確認を説明しています。
- Issue #114「Document how to implement new models」は開いています(2026-11-02 に確認)。

### 互換コードの一括削除

- `COMPAT(v3)` のフックは 25 行です(`grep -rn "COMPAT(v3)" _GUILDAsystem _GUILDAobject @GUILDA`)。ロジックは `_GUILDAsystem/_VersionSupport/` にあります。
- **未検証:** [v4-migration.md](v4-migration.md) の「Removing compat code in one step」を実行したのは第 1 段階の後だけです。以後は手順を実行しておらず、削除するテストの一覧はテストを読んで増やしたものです。

### 同梱ネットワーク

- `IEEE14bus`, `IEEE14bus_NoTap`, `IEEE14bus_lossless`, `Ishizaki6Bus`, `TEST31bus`, `Txt3Bus` には `network/parameter.csv` がないので、既定の基準値(`GUILDA.config("Model","Hz")`、100 MVA)で読み込みます。`IEEE9bus` と `IEEE68bus` にはあります。

### OPF

要件とロードマップは [opf-requirements.md](opf-requirements.md) にあります。

- **完了:** 段階 1(正しさの修正)と段階 2(カスタマイズ。2026-11-07 にオブジェクトごとの `set_opffcn` から `SolverOPF` の `Cost` / `Constraint` などのオプションへ変更)です。変更点は [v4-migration.md](v4-migration.md) 1.9 にあります。
- **未着手:** 段階 3 の外部バックエンド(`prob2struct` 経由の CPLEX / Gurobi、`tools.network_to_mpc` 経由の MATPOWER)です。
- **先送り:** 多期間 OPF です。設計上の問いは opf-requirements.md にあります。
- 記録: AC OPF の開始点は、フラットスタート、または同じ系統で最後に解けた AC OPF の母線電圧(`WarmStart`、既定 false)です。母線の `V0` / `Varg0` は廃止しました。潮流解からの開始点は以前に測定して採用しませんでした(反復が減らず、9 母線 43 → 43、IEEE14 59 → 72)。前回の AC OPF の解からの開始も、内点法では反復が減るとは限りません(IEEE14 17 → 22、IEEE68 80 → 55)。このため既定は false です([powerflow-options.md](powerflow-options.md) の Q3)。

### `Scenario` の未確認の既定

`Scenario` の実装者が既定として選び、保守者がまだ確認していない点です(v4-migration.md 1.18)。

- `ODEevent` の互換で、同じ系統に同じタグの `ODEevent` を作り直すと、前のものを置き換えます(系統から外れて実行できなくなります)。
- 互換の返り値は `Scenario` で、`ev.TimeSpan` などの旧プロパティはありません(`ev.tab_disturbance` の列として読むだけ)。
- `sc.simulate` はありません。実行は `net.simulate(sc)` です。
- 判定(`sc.judge`)は `net.simulate` の `output` に入りません。

### 解析結果と編集

- **未実装:** 結果は、解析の後に系統が編集されたかを記録しません。`tab_editLog` は `initialize` で消えるので、刻印には使えません。提案は [get-sys-improvements.md](get-sys-improvements.md) の ED5 です。

### 保守者の判断を待つ問い

各ノートの判断の節に、質問と現状があります。

| ノート | 未決の問い |
|---|---|
| [model-building-improvements.md](model-building-improvements.md) §8 | Q3(モデルの残差をいつエラーにするか)、Q10(数値の添字)、Q11(外部クラスの登録)、Q13(未完成のクラスの整理)。Q12 は 2026-11-04 に変えると決まり、実装済みです |
| [get-sys-improvements.md](get-sys-improvements.md) §7 | Q8(使われていないコードの削除)、Q9(線形化の疎行列)、Q10(編集の刻印)、Q11(UX シートの記入) |
| [simulate-improvements.md](simulate-improvements.md) §8 | Q1(`Solver` の不一致は保留と記録)、Q8、Q12。Q13 のブランチ開放は EV5 より前に実装され、EV5 はその後 `Scenario.compile` として実装されました(同ノートの「その後の実装」) |

### コードの問題の一覧

- **未対応:** For Developer のページを書く途中で見つかった問題を [dev-pages-code-findings.md](dev-pages-code-findings.md) に記録しました(基準 `765663b`、2026-11-04)。CPF の `iv_CPFX` が残る問題(CPF-1)など、再現したバグを含みます。修正するかは未決です。

## 解決済みの項目

以前この文書で未決だった項目です。

- **`TimeLimit`:** 実行全体の上限として実装済みです(`e0b6d97`)。既定は `Inf` です。`test_I55_time_limit.m` で確認しています。
- **Hz と baseMVA の編集:** Hz は `f_*` だけを古くし、baseMVA は平衡点も古くします(`LayerPackage`)。`_GUILDAdoc/developer/class-design.html` の編集の表にも行があります。

## IEEE14 のデータと CSV のタップ

[v4-migration.md](v4-migration.md) 1.15 が参照する数値の記録です。古いスクリプトの結果と比べるときに使います。各行の値は記載のコミットの時点の計算で、`faa2d13` では再計算していません。F8 のテストは現在の母線電圧、OPF コスト、最も遅い固有値を固定しています。

- **CSV のタップ:** `PowerNetwork.import_csv` は `tap` / `phase` 列を読み、`Tap` / `Phase` も受け付けます。両方あると `GUILDA:import_csv:DuplicateColumns` です。以前は読み込んだタップがすべて 1 でした(IEEE14 の 4-7, 4-9, 5-6 など)。
- **`IEEE14bus` は MATPOWER `case14` に一致します**(100 MVA)。`C` は case14 の b の半分、負荷の Q は −Qd、母線の `Vmin` / `Vmax` は 0.94 / 1.06、発電機の上下限、コストは `HP = c2·100²`、`fP = c1·100`、負荷のコストは 0 です。Ybus は case14 と 1e-14 で一致し、潮流の発電機 Q は `runpf(case14)` の値(−16.55, 43.56, 25.08, 12.73, 17.62 MVAr)、AC / DC OPF は 8081.53 / 7642.59 $/hr です。
- **意図して残した点:** すべての発電機(母線 3, 6, 8 の調相機を含む)は 1 組の動特性の `gen-park` です。母線 7 の負荷は 0 です。ブランチ 7-9 は `pi` 線路です(case14 でタップ 1)。
- **`IEEE14bus` の修正前との差**(`63bc5a0` のコードで計算): 母線電圧は最大 0.052 pu(母線 14)、角度は 0.82°、スラックの P は 232.86 → 232.39 MW です。発電機母線の無効電力は (−34.3, −8.7, −13.9, −12.0, 3.1) → (−16.6, 30.9, 6.1, 5.2, 17.6) MVAr です。ELD / DC OPF の配分は各 51.8 MW(コスト 2.66)→ 221.0 / 38.0 / 0 / 0 / 0 MW(7642.59 $/hr)、AC OPF のコストは 2.68 → 8081.52 $/hr です。最も遅いモードは −0.535 → −0.540、最小の減衰比は 0.037 → 0.035 です。母線 8 は潮流で 1.09 pu となり `Vmax` 1.06 を超えますが、case14 と同じです(潮流は上下限を課しません)。
- **`IEEE14bus_NoTap`** は `IEEE14bus` の変圧器 4-7, 4-9, 5-6 をタップ 1、位相 0 にしたものです。`IEEE14bus` との差: 母線電圧は最大 0.015 pu(母線 5)、角度は 0.45°、AC OPF のコストは 8079.95 と 8081.52 $/hr、最も遅いモードは −0.530 と −0.540 です。
- **`IEEE14bus_lossless` のタップ修正の影響**(データは旧来のまま): 母線電圧は最大 0.016 pu(母線 5)、角度は 0.15°、母線の無効電力は最大 27.9 MVAr、最も遅いモードは −0.332 → −0.385 です。B008 の故障後の ω の差は 1.5e-4(ピーク 1.6e-3)、OPF のコストは不変です。
- **`IEEE14bus_lossless` は現在 `IEEE14bus` の R = 0 版です。** タップを修正した旧データとの差(`2723422` のコードと `fe1e5c3` の CSV で計算): 母線電圧は最大 0.054 pu(母線 14)、角度は 0.33°、スラックの P は不変(219.0 MW、損失なし)、最も遅いモードは −0.385 → −0.595、最小の減衰比は 0.037 → 0.035 です。ELD / DC / AC OPF のコストは 2.66 → 7642.59 $/hr で、損失がないので 3 つとも同じです。
