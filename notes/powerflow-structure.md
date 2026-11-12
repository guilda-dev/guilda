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
- `PowerNetwork.n_revY` と `n_revPF` を読むソルバーはなくなりました(`handle_edit` が増やすだけです)。削除は別の作業にします。

### 3. `Format` オプション

| 値 | 最初の出力 |
|---|---|
| `"V"`(既定) | 母線の複素電圧(`net.a_Bus` の順の列) |
| `"powerflow(mat)"` | n×4 の複素行列。列は V、I(複素フェーザ)、P、Q(実数) |
| `"powerflow(tab)"` | 同じ内容の table(変数 `V`・`I`・`P`・`Q`、行名は母線タグ) |
| `"GUILDAorigin"` | `ResultPF` |

- `flag` と `output` はどの Format でも 2 番目・3 番目の出力です。
- **Export(ユーザーの決定、2026-11-12):** `calculate_powerflow` に `Export` オプションはありません。書き出しは `res.Export(...)` だけです(`initialize` も受け付けません)。最初の実装では、ほかの Format でも書き出しのためだけに `ResultPF` を作っていましたが、オプションごと削除しました。`ResultPF.Export` の名前(`export` か `Export` か)は確認中です。
- `initialize` にも同じ `Format`(既定 `"V"`)を加えました。潮流計算・FixedInput・平衡点からの計算は解いた点を、OPF は `"GUILDAorigin"` で `ResultOPF`、それ以外で AC OPF の解の母線 V・I・P・Q を返します。
- 内部の呼び出しは必要なものだけを求めます。`initialize` の潮流計算と `solve_fixed_input` の初期点は `Format="powerflow(tab)"` です。`initialize` は `Format="GUILDAorigin"` のときだけ `ResultPF` を作ります。
- 書き換えた呼び出し元: DebugScript(結果を読むテストに `Format="GUILDAorigin"` を追加)、同梱ネットワークのヘルプの例(`res = ...` → `V = ...`)、`PowerNetwork`・`ResultBase`・`SolverPF` のヘルプの例。`_GUILDAverification`、`Scenario`、CPF、OPF は `calculate_powerflow` の結果を読んでいません。
- **未対応:** `_GUILDAtutorial/*.mlx` は保留中のチュートリアルの作業(Issue #113)に含まれるため、変えていません。

### 4. データから作る `ResultPF`

- 入力は `ResultPF(tab_powerflow, cm_Y, sct_network, sct_solver)` です。`tab_powerflow` は `"powerflow(tab)"` の表、`sct_network` は `struct(net, false)`、`sct_solver` は solver・options・flag・output・elapsed・cm_Vhistory・rv_step・tab_PFcondition を持つ struct です。
- コンストラクタの中で `tab_bus`(列は従来どおり `Varg, V, P, Q, Vphasor, Iphasor`)、`tab_branch`、`tab_violation` を計算します。生きたオブジェクトは読みません。
- 新しいプロパティ: `tab_PFcondition`、`cm_Y`、`sct_network`(すべて SetAccess=private)。
- `ResultBase` には `[]` を渡し、`s_network` は `ResultPF` が設定します。**`ResultBase` は変えていません**(ヘルプの例だけ `Format="GUILDAorigin"` を加えました)。
- **`tools.distribute_power` の変更:** スナップショットの母線(struct)も受け付けるようにしました。内部の `group` が struct なら `tab_parameter.(グループ名)` を読みます。オブジェクトでの動作は変わりません。
- **枝のアドミタンス:** スナップショットのクラス名と dynamics パラメータから、`@ResultPF/private/branch_admittance.m` で計算します。式は `branch.pi`・`pi_transformer`・`T`・`two_winding_transformer` の `get_admittance_matrix` と同じで、一致は F2 のテスト「Branch flows of the result use the admittance of each branch class」で確かめています。
  **要判断:** 式が枝のクラスと 2 か所にあります。また、利用者が作った枝のクラスは NaN の潮流になります。代わりに、系統が枝ごとの 2×2 のアドミタンス行列をスナップショットに加える方法があります(式は 1 か所、利用者の枝のクラスも動きます。ただしスナップショットが `struct(net, false)` そのものではなくなります)。
- `ResultPF.Export` の JSON は保存した `tab_PFcondition` と `cm_Y` を使います。持たない結果(`ResultPF()`、平衡点からの結果)では、これまでどおり `GUILDA:ResultPF:NoNetwork` です(本文を新しい形に合わせました)。
- **動作の変化:** `initialize` の FixedInput と平衡点からの `ResultPF` も、枝潮流と運転制約の違反を持つようになりました(以前は空)。`r_elapsed` はソルバーの時間で、結果の組み立ては含みません。

## 5. `ResultPF` の表示メソッドの提案(未実装)

結果を読むためのメソッドの案です。どれも結果が持つデータ(`tab_bus`、`tab_branch`、`tab_violation`、`cm_Vhistory`、`sct_network`)だけを使い、系統は読みません。

| 名前 | 表示するもの | オプション |
|---|---|---|
| `disp_summary` | 収束の情報(Solver、flag、反復回数、残差、時間)、発電・負荷・損失の合計、電圧の最大と最小(母線名つき)、違反の件数 | なし |
| `disp_bus` | 母線ごとの種別(slack/PV/PQ)、\|V\|、位相 [deg]、P、Q。設定値と解の対応がわかるように、潮流条件の値も並べる | `Bus`(表示する母線タグ)、`Unit`(`"pu"` / `"SI"`。SI は baseKV・baseMVA で kV・MW・Mvar に換算)、`Sort`(`"tag"` / `"V"`) |
| `disp_branch` | 枝ごとの from・to の母線、両端の P・Q、損失、負荷率(\|S\|/Smax) | `Branch`(表示する枝タグ)、`Unit`、`Sort`(`"tag"` / `"loss"` / `"loading"`) |
| `disp_violation` | `tab_violation` を種類(母線・機器・枝)ごとにまとめた表。0 件なら「違反なし」 | `Class`(`"Bus"` / `"Component"` / `"Branch"` の絞り込み) |
| `plot_voltage` | 母線電圧の大きさと位相の棒グラフ(いまの `Plot`)。Vmin・Vmax の線を重ねる | `Parent`、`Quantity`(`"magnitude"` / `"angle"` / `"both"`)、`Limit`(制約の線を描くか) |
| `plot_branch` | 枝ごとの潮流の棒グラフ | `Parent`、`Quantity`(`"P"` / `"Q"` / `"S"` / `"loading"` / `"loss"`) |
| `plot_convergence` | 反復(dynamic では仮想時間)ごとの最大残差と電圧の変化(`cm_Vhistory`、`rv_step`) | `Parent`、`Bus`(電圧の推移を描く母線) |
| `plot_network` | 系統図(スナップショットの `graph` パラメータの座標)に母線電圧を色で、枝潮流を矢印で重ねる | `Parent`、`Color`(`"V"` / `"angle"`)、`Arrow`(`"P"` / `"Q"` / `"none"`) |

**既存の `Plot`:** `Plot` と `Export` は `ResultBase` の約束(すべての結果クラスに共通の入口)なので、名前は残すことを勧めます。中身は `plot_voltage` を呼ぶだけにし、`plot_*` の各メソッドを個別の図として加えます。`plot_` の形へ改名すると、ほかの結果クラス(`ResultOPF`、`ResultCPF`、`ResultODE`、`ResultLIN`)の `Plot` もそろえる必要があります。

`disp` の既定(オブジェクトを表示したとき)を `disp_summary` にするかどうかも、合わせて決めてください。

## テスト

- 手順ごとに `DebugScript.run_all('Level','small','FailOnUnexpected',true)` を実行しました。最後の medium は 688 件、PASS 686 / KNOWN 1 / FAIL 0 / SKIP 1 です。詳細は [status.md](status.md) の「潮流計算の構造の見直し」節にあります。
