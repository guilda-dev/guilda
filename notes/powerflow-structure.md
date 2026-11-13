# 潮流計算の構造の見直し

ブランチは `refactor/powerflow-structure`(未 push)です。この文書には、実装の記録、判断した点、`ResultPF` の表示メソッドの提案を書きます。

## 方針(ユーザーの決定)

- ソルバーは親の系統をたどって兄弟のオブジェクトを読みません。系統がデータを組み立て、ソルバーは数値計算だけを行います。
- v3 との後方互換はなくします。
- 結果のオブジェクトは、系統のハンドルではなく、系統の struct のスナップショットを持ちます。

## 実装の記録

### 1. `calculate_powerflow` の v3 対応の削除

- `v3_powerflow_args.m`、Deprecated の `CalculatePowerflowMode`・`CalculatePowerflowExport`、`SolverPF.get_options`・`SolverPF.OptionMap`・`@SolverPF/private/validate_options.m` を削除しました。
- `calculate_powerflow` は 1 つの `arguments (Input)` ブロックで `Solver`・`Tolerance`・`MaxIteration`・`Verbose`・`WarmStart`・`PlotFcn`・`Format` を検証します。既定値は `GUILDA.config("PowerFlowCalculation", ...)` です。
- 呼び出しのオプションでない設定(`WhenFailed`、`NewtonStepSize`、`GradientStepSize`、`FsolveMaxFunctionEvaluations`、`FsolveUseParallel`)は、これまでどおり `GUILDA.config` から読みます。ソルバーに渡す struct には、`Verbose` から作る `Display` も入れます。
- 未知の名前は MATLAB の arguments ブロックのエラーになります(以前は `GUILDA:resolve_options:UnknownName`)。`initialize(Method="powerflow", Foo=1)` も同じです。
- OPF、連続潮流計算、時間応答シミュレーション、線形化の `OptionMap` はそのままです。

### 2. `SolverPF` は系統を読まない

- `[cv_V, flag, output, cm_Vhistory, rv_step] = solve(obj, cm_Y, tab_PFcondition, sct_options)`。方程式は呼び出しごとに作ります。
- 改訂番号によるキャッシュ(`a_Bus`、`n_revTopology`、`cm_Y`、`n_revY`、`n_revPF`、`sct_equation`)を削除しました。残るのはウォームスタートの `cv_Vwarm` と、その解の母線タグ `sv_warmBus` だけです。
- ウォームスタートは、`WarmStart` が true で、母線タグ(順序も)が一致するときだけ使います。**動作の変化:** 以前は枝の追加・削除で解を捨て、タグの変更では保持していました。いまは逆に、枝の編集では保持し(初期値が変わるだけで解は同じです)、タグの変更では使いません。
- `calculate_powerflow` がスラック母線の選択、`tab_PFcondition`(各 `Bus.get_pf_condition`)と `cm_Y`(`get_admittance_matrix`)の組み立て、`WhenFailed` の通知を行います。
- **メッセージ ID の変更:** 収束しないときの警告・エラーは `GUILDA:SolverPF:NotConverged` から `GUILDA:PowerNetwork:PowerflowNotConverged` に変わりました。`msg` は呼び出し元のクラスの ID しか受け付けないためです。`SolverPF.xml` は空になったので削除しました。
- `PowerNetwork.n_revY` と `n_revPF` を読むソルバーはなくなりました。`n_revTopology` とともに `refactor/opf-structure` で削除しました(2026-11-12、`handle_edit` の増分も削除)。

### 3. `Format` オプション

| 値 | 最初の出力 |
|---|---|
| `"V"` | 母線の複素電圧(`net.a_Bus` の順の列) |
| `"powerflow(mat)"` | n×4 の複素行列。列は V、I(複素フェーザ)、P、Q(実数) |
| `"powerflow(tab)"` | 同じ内容の table(変数 `V`・`I`・`P`・`Q`、行名は母線タグ) |
| `"GUILDAorigin"`(既定) | `ResultPF` |

- **既定値(ユーザーの決定、2026-11-12):** `calculate_powerflow` の既定は `"GUILDAorigin"` です。最初の実装は `"V"` でした。`initialize` は `Format` を取りません(下の項目)。

- `flag` と `output` はどの Format でも 2 番目・3 番目の出力です。
- **Export(ユーザーの決定、2026-11-12):** `calculate_powerflow` に `Export` オプションはありません。書き出しは `res.export(...)` だけです(`initialize` も受け付けません)。最初の実装では、ほかの Format でも書き出しのためだけに `ResultPF` を作っていましたが、オプションごと削除しました。書き出しのメソッドは、すべての結果クラスで `export` に改名しました(ユーザーの決定、2026-11-12。別名や互換の変換はありません)。
- **`initialize` の Format(ユーザーの決定、2026-11-13):** `initialize` は `Format` を取りません。最初の出力は、どの `Method` でも `set_equilibrium` に書く n×4 の複素数の配列(V・I・P・Q、`net.a_Bus` の順。OPF では AC OPF の解)です。`Format` を渡すと、どの `Method` でも `initialize` がオプションの解析で `GUILDA:PowerNetwork:InitializeFormat` で止め、`calculate_powerflow` へは渡しません(2026-11-12 の実装では `Format` を取り、既定が `"powerflow(mat)"` でした)。結果のオブジェクトは `calculate_powerflow` / `calculate_optimal_powerflow` で得ます。
- 内部の呼び出しは必要なものだけを求めます(ユーザーの決定、2026-11-12)。`initialize` の潮流計算は `Format="powerflow(mat)"` の n×4 の配列を求め、`set_equilibrium` は列から V・I・P・Q を読みます。`calculate_powerflow` は `"V"` では `cv_V` だけを返し、`"powerflow(mat)"` では `cv_V` と `Y*cv_V` から配列を作ります。table を作るのは `"powerflow(tab)"` と `ResultPF` のときだけ、`ResultPF` を作るのは `"GUILDAorigin"` のときだけです。FixedInput(`solve_fixed_input`)は母線の n×4 の配列と `sct_point`(機器ごとの X・U・I。`initialize` が母線へ書く)を返し、何も整形しません。OPF は `initialize` が `ResultOPF.tab_cub` から機器ごとの P・Q を、`tab_bus` から配列を作ります。平衡点からの計算も配列だけを返します。
- **補助関数の削除(ユーザーの決定、2026-11-13):** `@PowerNetwork/private/format_powerflow.m`・`powerflow_matrix.m`・`powerflow_table.m` を削除し、1〜2 行の中身を呼び出し元に直接書きました。`calculate_powerflow` は Format の分岐を自分の中に持ちます。`calculate_powerflow` の `PlotFcn` はローカルの `mustBePlotFcn` ではなく、`arguments` ブロックで `tools.check_plotfcn(...)` を直接呼びます。
- 書き換えた呼び出し元: DebugScript(`initialize` の結果を読んでいたテストは、最初の出力の配列と平衡点を確かめるか、`calculate_powerflow` / `calculate_optimal_powerflow` を呼びます。解いたかどうかは `output` に `iterations` があるかで確かめます。F2・F3 に Format を拒むテスト)、`calculate_powerflow`・`initialize`・`SolverPF` のヘルプの例。同梱ネットワークのヘルプの例(`res = net.calculate_powerflow()`)は元のままです。`_GUILDAverification`、`Scenario`、CPF、OPF は `calculate_powerflow` の結果を読んでいません。
- **未対応:** `_GUILDAtutorial/*.mlx` は保留中のチュートリアルの作業(Issue #113)に含まれるため、変えていません。

### 4. データから作る `ResultPF`

- 入力は `ResultPF(tab_powerflow, cm_Y, sct_network, sct_solver)` です。`tab_powerflow` は `"powerflow(tab)"` の表、`sct_network` は `struct(net, false)`、`sct_solver` は solver・options・flag・output・elapsed・cm_Vhistory・rv_step・tab_PFcondition を持つ struct です。
- コンストラクタの中で `tab_bus`(列は従来どおり `Varg, V, P, Q, Vphasor, Iphasor`)、`tab_branch`、`tab_violation` を計算します。生きたオブジェクトは読みません。
- 新しいプロパティ: `tab_PFcondition`、`cm_Y`、`sct_network`(すべて SetAccess=private)。
- `ResultBase` には `[]` を渡し、`s_network` は `ResultPF` が設定します。**`ResultBase` は変えていません**(ヘルプの例だけ `Format="GUILDAorigin"` を加えました)。
- **`tools.distribute_power` の変更:** スナップショットの母線(struct)も受け付けるようにしました。内部の `group` が struct なら `tab_parameter.(グループ名)` を読みます。オブジェクトでの動作は変わりません。
- **枝のアドミタンス(案 C、ユーザーの決定、2026-11-12):** `Branch` が `struct` を上書きし(`LayerPackage.struct` と同じ引数 `l_disp`・`s_header`・`sct_visited`、Hidden)、`LayerPackage.struct` の結果にフィールド `cm_Y`(`get_admittance_matrix` の 2×2 複素行列)を加えます。`ResultPF` はスナップショットの `cm_Y` で枝潮流を求めるので、式は枝のクラスだけにあり、利用者が作った枝のクラスでも潮流が求まります。`cm_Y` のない struct の枝は NaN です。最初の実装の `@ResultPF/private/branch_admittance.m`(クラス名ごとの式)は削除しました。
  テストは F2「Branch flows of the result use the admittance matrix in the snapshot」で、4 つの組み込みクラスの一致、2 度目に出会う枝がパスのままであること、クラス名を変えても `cm_Y` で潮流が決まること(利用者の枝クラスの代わり)を確かめています。利用者の枝クラスそのものは、`add_branch` が `GUILDA.keymap` に登録されたキーしか受け付けないため、テストでは作っていません。
- `ResultPF.export` の JSON は保存した `tab_PFcondition` と `cm_Y` を使います。持たない結果(`ResultPF()`、平衡点からの結果)では、これまでどおり `GUILDA:ResultPF:NoNetwork` です(本文を新しい形に合わせました)。
- **動作の変化:** `initialize` の FixedInput と平衡点からの `ResultPF` も、枝潮流と運転制約の違反を持つようになりました(以前は空)。`r_elapsed` はソルバーの時間で、結果の組み立ては含みません。

## 5. `ResultPF` の表示メソッド

ユーザーが承認した 5 つを実装しました(2026-11-12)。どれも結果が持つデータ(`tab_bus`、`tab_branch`、`tab_violation`、`tab_PFcondition`、`sct_network`、`output`)だけを使い、系統は読みません。`disp_*` は出力を 1 つ求めると表示せずに文字列を返します(`disp_connection` と同じ)。オブジェクトの表示(`disp`・`display`)は MATLAB の既定のままです。

| 名前 | 表示するもの | オプション | 状態 |
|---|---|---|---|
| `disp_summary` | 収束の情報(Solver、flag、反復回数、残差、時間、メッセージ)、母線の種別ごとの数と枝の数、母線注入の合計(発電 = 正の P、負荷 = 負の P、損失 = P と Q の合計)、\|V\| の最大と最小(母線名つき)、違反の件数 | なし | 実装 |
| `disp_bus` | 母線ごとの種別(slack/PV/PQ)、潮流条件の設定値、\|V\|、位相 [deg]、P、Q | `Bus`(母線タグ)、`Unit`(`"pu"` / `"SI"`。SI は \|V\| を母線の baseKV 倍の kV、P・Q を baseMVA 倍の MW・Mvar。設定値は pu のまま)、`Sort`(`"tag"` / `"V"`(\|V\| の小さい順)) | 実装 |
| `disp_branch` | 枝ごとの From・To の母線、両端の P・Q、損失、負荷率(両端の大きいほうの \|S\| / Smax。Smax が無限なら NaN) | `Branch`(枝タグ)、`Unit`、`Sort`(`"tag"` / `"loss"` / `"loading"`。大きい順) | 実装 |
| `disp_violation` | `tab_violation` を種類(Bus・Component・Branch)ごとにまとめた表。0 件なら 1 行 | `Class`(`"Bus"` / `"Component"` / `"Branch"` の絞り込み) | 実装 |
| `plot_voltage` | 母線電圧の大きさと位相の棒グラフ(旧 `Plot`)。有限の Vmin・Vmax を破線(Tag `"Vmin"`・`"Vmax"`)で重ねる | `Parent`、`Quantity`(`"magnitude"` / `"angle"` / `"both"`)、`Limit`(既定 true) | 実装 |
| `plot_branch` | 枝ごとの棒グラフ。`"P"`・`"Q"` は `Pfrom`・`Qfrom`、`"S"` は両端の大きいほうの \|S\|、`"loading"` は \|S\|/Smax(Smax が無限なら棒なし)と 1 の破線(Tag `"Limit"`)、`"loss"` は `Ploss` | `Parent`、`Quantity`(`"P"` / `"Q"` / `"S"` / `"loading"` / `"loss"`、既定 `"P"`) | 実装 |
| `plot_convergence` | `cm_Vhistory` の各点での電力方程式の最大残差(対数軸、横軸は `rv_step`。dynamic では仮想時間)と `Tolerance` の破線。残差は `SolverPF` の方程式と同じ定義で、保存した `tab_PFcondition` と `cm_Y` から計算します(最後の点は `output.residual` と一致) | `Parent`、`Bus`(指定すると、その母線の \|V\| の推移を 2 段目に描く) | 実装 |
| `plot_network` | MATLAB の graph plot で、母線の色を \|V\|(または位相)、枝を P(または Q)が入る端からの矢印にし、線幅を \|P\|(\|Q\|)に比例させる | `Parent`、`Color`(`"V"` / `"angle"`)、`Arrow`(`"P"` / `"Q"` / `"none"`) | 実装 |

- **`plot_network` の座標:** スナップショットの各母線の `graph` パラメータの `Xaxis`・`Yaxis` を使います。1 つでも NaN の母線があると、与えられた座標は使わず、全母線を MATLAB の graph plot の `"force"` レイアウトで置きます(一部だけ座標を補う方法は、座標の尺度が系統ごとに違うため採りませんでした)。各枝の向きは `Pfrom`(`Qfrom`)の符号で決め、`digraph` の辺の並びから枝を対応づけ、返す `GraphPlot` の `UserData` に辺ごとの枝タグを入れています。
- 3 つの図(`plot_branch`・`plot_convergence`・`plot_network`)は 2026-11-12 に追加しました(ユーザーの依頼)。結果のない値には `GUILDA:ResultPF:NoHistory`(条件・Y・履歴のない結果での `plot_convergence`)と `GUILDA:ResultPF:NoNetworkSnapshot`(スナップショットのない結果での `plot_network`)で止まります。
- 未知のタグは `GUILDA:ResultPF:UnknownTag`、スナップショットのない結果での `Unit="SI"` は `GUILDA:ResultPF:NoBase` です。
- **`Plot` の廃止(ユーザーの決定、2026-11-12):** すべての結果クラスの `Plot` を、中身を変えずに `plot_*` に改名しました(別名なし)。`ResultPF.plot_voltage`(制約の線を追加)、`ResultOPF.plot_dispatch`、`ResultCPF.plot_pvcurve`、`ResultODE.plot_trajectory`、`ResultLIN.plot_eigenvalue` です。`ResultBase.Plot` は削除しました。`GUILDA:ResultBase:Unsupported` は `export` がまだ使うので残しています。
- **未対応:** `_GUILDAtutorial/*.mlx` は保留中のチュートリアルの作業に含まれるため、`Plot` の呼び出しを変えていません。

## 6. `initialize` の整理(ユーザーの決定、2026-11-13)

- **`complex()` の削除:** [V I P Q] の配列は `[cv_V, cv_I, real(cv_S), imag(cv_S)]` と書きます(`calculate_powerflow`、`initialize` の OPF と平衡点からの計算、`solve_fixed_input`)。V が複素数なので、連結した配列は複素数のままです。出力の型(n×4 の複素数の配列)は変わりません。
- **v3 互換の削除:** `_VersionSupport/v3_initialize_args.m` とその呼び出し、`Deprecated.xml` の `InitializeMethods`・`InitializeMethodValue`、F3 の「Deprecated methods option and values warn」とその `test_levels.m` の行を削除しました。`"methods"` は未知の名前として解析のエラー、旧い値は `GUILDA:PowerNetwork:InitializeMethod` になります(F3 の「Initialize rejects unknown options」で確認)。
- **読みやすさ(動作は変えない):** 本体を上から順に 1. Method とオプションの解析、2. Method ごとの運転点、3. 母線への書き込み、4. 母線・ブランチ・グローバル制御器の initialize、5. KCL とモデルの残差の確認、6. 古さの解除、7. INFO と警告、の節に並べました。1〜2 行の関数や 1 回だけ使う関数(`take_method`、`solve_powerflow`、`solve_opf`、`opf_point`、`solve_fixed`、`write_powerflow`、`write_fixed_input`、`release_slack`、`stale_list`、`equilibrium_tolerance`、`large_model_residuals`、`largest`)は本体に入れ、`stop_powerflow` と `stop_opf` は `stop_analysis` に、潮流計算と FixedInput のスラック母線の解除は 1 つの `try/catch` にまとめました。行のまとめは `residual_row` です。634 行・ローカル関数 24 個 → 519 行・11 個。

## テスト

- 手順ごとに `DebugScript.run_all('Level','small','FailOnUnexpected',true)` を実行しました。最後の medium は 688 件、PASS 686 / KNOWN 1 / FAIL 0 / SKIP 1 です。詳細は [status.md](status.md) の「潮流計算の構造の見直し」節にあります。
