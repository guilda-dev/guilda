# 潮流計算のオプションと Solver/Method の再設計

潮流計算のオプション、`Method*` ソルバークラス、Solver オブジェクトのウォームスタートとキャッシュ、
母線の `V0`/`Varg0` の廃止、各解析での `operation` 制約の扱いの仕様。

- 決定: 2026-11-09、メンテナー。
- 基準コミット: `0af04ad3`(`refactor/design-alignment`)。「現状」はこのコミットのコード。
- 状態: 手順 A(`MethodBase` と数値微分の共有、1 節・12 節)は `refactor/method-base` で実装。
  手順 B(SolverPF のオプション、GUILDA.setting のセクション、ウォームスタート、キャッシュ、
  母線の `V0`/`Varg0` の廃止)と手順 C(連続潮流計算の `Limits`)は未実装。実装の指示書はこのノートを引用する。
- 区別: **決定**(メンテナーの決定)、**現状**(コードで確認済み)、**未決**(末尾の一覧)。

## 1. Method クラス

**決定**

- `MethodNewtonRaphson` / `MethodLevenbergMarquardt` / `MethodGradient` / `MethodFsolve` /
  `MethodDynamic` は `_GUILDAsystem/_auxiliary/` に残す(名前空間なし)。
- 新しい基底クラス `MethodBase`(`_auxiliary/@MethodBase/`、`auxiliary` を継承する抽象 handle クラス)を前の 4 クラスの親にする。
  - プロパティ: `Fcn`(F(x)=0 の F)、`Jac`(空なら数値ヤコビアン)、`InitVal`、`ConvTol`、`MaxIter`、`Display`、
    `Increment`(数値ヤコビアンの刻み)。
  - メソッド:
    - Abstract `solve`。出力は `[x, flag, output, rm_history, rv_step]`。
    - protected `set_options(obj, opt)`: Name-Value の構造体をプロパティへ代入(サブクラスのコンストラクタが使用)。
    - protected `eval_jacobian(obj, x)`: `Jac`、または `Increment` による `tools.fd_jacobian`。
    - protected `make_output(...)`: flag と `output`(iterations、algorithm、residual、message)を作成。
      `Display` が "none" 以外なら最後のメッセージを表示。
    - protected `print_iter(...)`: 反復ごとの表示。
  - `flag`: 1 収束、0 `MaxIter` 到達、-2 発散または解なし。
  - `output.message` は各 Method の中で作成(SolverPF では作らない)。
  - 収束判定は 4 クラスとも「|F(x)| の最大値 ≤ `ConvTol`」(Gradient は残差 r)。
  - 既定値は各クラスが自身で持つ(Method クラスは `GUILDA.config` を読まない)。
  - 数値ヤコビアンは `MethodBase.eval_jacobian` で共有(12 節)。
- `MethodNewtonRaphson`: `NRMFcn` → `Fcn`、`NRMJac` → `Jac`、`NRMVal` は削除(呼び出し側が F(x)-b を渡す)。互換層なし。
  - `StepSize` と、記号式の `Fcn`(Symbolic Math Toolbox)は維持。
  - 特異なヤコビアンでは最小ノルムのステップ。|F| > `ConvTol` のままステップが停滞すると flag -2
    (`@SolverPF/solve.m` の `run_method` にあった NR の判定を移動)。
  - 既定値: `ConvTol` 1e-5、`MaxIter` 1000、`InitVal` 1、`Increment` 1e-4、`StepSize` 1(現状の JSON の値)。
- `MethodFsolve`: `FunctionTolerance` → `ConvTol`、`MaxIterations` → `MaxIter`(0 は fsolve の既定)。
  flag は exitflag > 0 かつ |F| の最大値 ≤ `ConvTol` で 1、exitflag 0 で 0、それ以外は -2。元の exitflag は `output.exitflag`。
- `MethodDynamic` は `MethodBase` の外(方程式の形が異なるため)。
- 既定値は 1 か所で持つ。`@SolverPF/solve.m` の `run_method` にハードコードした既定値(1e-8、50、1e6、100 など)は削除。
- 連続潮流計算の修正子は、将来 `MethodBase` 型として LM / fsolve も受け付け可能。Gradient と Dynamic は連続潮流計算に不向き。

**現状**

| クラス | 方程式 | 収束判定 | `solve` の出力 | flag |
|---|---|---|---|---|
| `MethodNewtonRaphson` | `NRMFcn`、`NRMJac`、`NRMVal`(F(x)=b) | ステップの最大要素 ≤ `ConvTol` | `[xi, iteration, flag, rm_history]` | logical |
| `MethodLevenbergMarquardt` | `Fcn`、`Jac` | 最大残差 ≤ `ConvTol` | `[x, flag, output, rm_history, rv_step]` | 1/0/-2 |
| `MethodGradient` | `Fcn`(方向 d と残差 r) | 最大 \|r\| ≤ `ConvTol` | 同上 | 1/0/-2 |
| `MethodFsolve` | `Fcn`、`Jac` | fsolve の `FunctionTolerance` | 同上 | fsolve の exitflag |
| `MethodDynamic` | `Y`、`PFcondition` | 最大 P/Q 不平衡 ≤ `Tolerance` | `[cv_Vbus, flag, output, cm_Vhistory, rv_step]` | logical |

- NR の flag とメッセージは `@SolverPF/solve.m` の `run_method` が作成(NR の「ステップは小さいが不平衡が `max(1e-6, Tolerance)` を超える」判定もそこ)。
- NR の既定値は 2 か所: `@GUILDA/config/DefaultMethodNewtonRaphson.json`(`ConvTol` 1e-5、`MaxIter` 1000、`InitVal` 1、`Increment` 1e-4、`StepSize` 1)と `run_method`(1e-8、50)。
- `@SolverCPF/solve.m` は `MethodNewtonRaphson("NRMFcn", f_PF, "NRMJac", [], ...)` で作成し、数値ヤコビアン(`Increment`)を予測子と修正子(`private/correct.m`)で使用。`correct.m` は引数の型を `MethodNewtonRaphson` に固定。

## 2. オプションの置き場所

**決定**

- `calculate_powerflow` の Name-Value: `Method`、`Tolerance`、`MaxIteration`、`Verbose`、`Plot`、`Export`、`WarmStart`。
- 既定値は GUILDA.setting(`@GUILDA/setting.m`、JSON は `@GUILDA/config/DefaultPowerFlowCalculation.json`)の PowerFlowCalculation セクション:

  | 項目 | 意味 |
  |---|---|
  | `Method` | 計算手法 |
  | `Tolerance` | 最大 P/Q 不平衡 [pu](3 節) |
  | `MaxIteration` | 最大反復回数。0 は手法ごとの自動(newton 50、gradient 1e6、LM 100、fsolve 400) |
  | `NewtonStepSize` | NR の更新係数 |
  | `GradientStepSize` | gradient の α。0 は自動 |
  | `FsolveUseParallel` | fsolve の `UseParallel` |
  | `FsolveMaxFunEvals` | fsolve の `MaxFunctionEvaluations` |
  | `WhenFailed` | 未収束時の反応 |
  | `WarmStart` | ウォームスタートの既定(7 節) |

- Name-Value はその呼び出しだけを上書き。JSON には書き込まない。
- GUILDA.setting のセクションは解析ごと。MethodNewtonRaphson セクションは手順 B で削除。
  - ContinuationPowerFlow セクションに `CorrectorMaxIteration`、`CorrectorStepSize`、`Increment` を追加(連続潮流計算の修正子と数値ヤコビアン)。
  - Method クラスは直接使うときのために自身の既定値を持つ(1 節)。
- fsolve の `PlotFcn` は設定から削除。
- `Display` は設定から外し、`Verbose` で指定(5 節)。

### オプション名の対応表

現状(`0af04ad3`):

| `calculate_powerflow` NV | `SolverPF` プロパティ / JSON キー | NR | LM | Gradient | Fsolve | Dynamic |
|---|---|---|---|---|---|---|
| `Method` | `Method` | – | – | – | – | – |
| `Tolerance` | `Tolerance`(0 = 手法の既定) | `ConvTol`(ステップ、1e-8) | `ConvTol`(残差、1e-8) | `ConvTol`(不平衡、1e-8) | `FunctionTolerance`(0 = fsolve 既定 1e-6) | `Tolerance`(1e-5) |
| `MaxIteration` | `MaxIterations`(0 = 手法の既定) | `MaxIter`(50) | `MaxIter`(100) | `MaxIter`(1e6) | `MaxIterations`(0 = fsolve 既定) | 使わない(`t_span`) |
| `Verbose` | `Display`("iter"/"none") | `Display` | `Display` | `Display` | `Display` | なし |
| なし | `MaxFunEvals` | – | – | – | `MaxFunEvals` | – |
| なし | `UseParallel` | – | – | – | `UseParallel` | – |
| なし | `PlotFcn` | – | – | – | `PlotFcn` | – |
| なし | `WhenFailed` | – | – | – | – | – |
| なし | `gradient.StepSize`(プロパティのみ、JSON なし) | – | – | `StepSize` | – | – |
| なし | `dynamic.Mass/Damper/foh_PQ/t_span`(プロパティのみ) | – | – | – | – | 同名 |
| なし | JSON MethodNewtonRaphson `StepSize` | `StepSize` | – | – | – | – |
| `Plot`、`Export` | なし(`calculate_powerflow` 内で処理) | – | – | – | – | – |

変更後:

| `calculate_powerflow` NV | GUILDA.setting PowerFlowCalculation | `MethodBase` 共通 | 手法固有 |
|---|---|---|---|
| `Method` | `Method` | – | – |
| `Tolerance` | `Tolerance` | `ConvTol`(全手法で最大 P/Q 不平衡) | Fsolve は `FunctionTolerance` にも渡す。Dynamic は自身の `Tolerance` |
| `MaxIteration` | `MaxIteration`(0 = 自動) | `MaxIter` | Dynamic は不使用(内部の安全上限) |
| `Verbose` | なし | `Display`("iter"/"none") | – |
| なし | `NewtonStepSize` | – | NR `StepSize` |
| なし | `GradientStepSize`(0 = 自動) | – | Gradient `StepSize` |
| なし | `FsolveUseParallel` | – | Fsolve `UseParallel` |
| なし | `FsolveMaxFunEvals` | – | Fsolve `MaxFunEvals` |
| なし | `WhenFailed` | – | –(SolverPF が使用) |
| `WarmStart` | `WarmStart` | – | –(SolverPF が初期値を選択) |
| `Plot`、`Export` | なし | – | – |
| なし | ContinuationPowerFlow セクション `CorrectorMaxIteration`、`CorrectorStepSize`、`Increment` | `MaxIter`、`Increment` | NR `StepSize`(連続潮流計算の修正子のみ) |

## 3. Tolerance

**決定**

- `Tolerance` は全手法で最大 P/Q 不平衡 [pu]。
- fsolve には `FunctionTolerance` として渡し、解いた後に SolverPF が不平衡を確認。
- 既定値は、`V0`/`Varg0` なし(フラットスタート)でも IEEJ_WEST30 / IEEJ_EAST30 夜間断面の平衡点の残差が小さく保てる値。
  - 参照: `_GUILDAobject/+network/@IEEJ_WEST30/IEEJ_WEST30.m` のヘルプ。保存した初期値ではドリフト 1e-13、フラットスタートでは夜間に 10 s で 1e-9〜1e-8。
  - 正確な値は実装時に検証(未決)。

**現状**: 意味が手法ごとに異なる(1 節の表)。NR はステップ幅で判定し、不平衡は `max(1e-6, Tolerance)` で追加確認。fsolve の `FunctionTolerance` は不平衡の最大値ではない。

## 4. MethodDynamic

**決定**

- `Mass`、`Damper`、`foh_PQ` は GUILDA.setting に置かず、自動。
  - `Mass` 0。
  - `Damper` 1(`Mass` 0 では時間の尺度を変えるだけのため)。
  - `foh_PQ` 0。電圧崩壊または位相角不安定で止まったときは、ランプ付き(`foh_PQ` > 0)で再試行。
- `t_span` は廃止。収束で停止し、内部に安全上限を持つ。

**現状**: `SolverPF.dynamic` の既定は `Mass` 0、`Damper` 0.1、`foh_PQ` 0、`t_span` 0:1/120:50。`MethodDynamic` の `Damper` 既定も 0.1。終了は `t_span` の終わりかイベント(収束、電圧崩壊、位相角不安定)。

## 5. Verbose と Plot

**決定**

- `Verbose`: 反復ごとに進行状況を表示(`Display="iter"`)。
- `Plot`: 解いた後に `result.Plot()` を呼ぶ(母線の電圧・位相の棒グラフ)。

**現状**: 同じ動作。`Verbose` は `SolverPF.OptionMap` で `Display` に変換。

## 6. `net.solver_*` の役割

**決定**

- `net.solver_*` は `PowerNetwork` に残し、役割を変える。
- 一般の数値設定は保存しない(常に GUILDA.setting + 呼び出しの Name-Value)。
- 保持するもの:
  1. ネットワーク固有の条件: 連続潮流計算の `LoadBus`、OPF の `ReferenceBus` / `Cost` / `Constraint`。
  2. ウォームスタートのデータ(7 節)。
  3. キャッシュ: アドミタンス行列、方程式のハンドル、OPF の問題(8 節)。
  4. サブクラスで差し替え可能なソルバーオブジェクト。
     - `SolverCPF` / `SolverODE` の `Sealed` を外す。
     - `solver_*` プロパティにクラスの検証を付ける。
- スラック母線は `Bus.l_isSlack` のまま。

**現状**

- `SolverPF` のヘルプと `PowerNetwork.m` のプロパティ説明は「stored defaults」(`net.solver_PF.WhenFailed = "WARN"` の例)。
- `SolverPF` のコンストラクタが `GUILDA.config("PowerFlowCalculation")` から既定値を複製。
- `classdef (Sealed = true)`: `SolverCPF`、`SolverODE`(`SolverPF`、`SolverOPF`、`SolverLIN` は Sealed なし)。
- `solver_*` にクラス検証はない(コメントの `<@Type>` のみ)。

## 7. ウォームスタート

**決定**

- 解析ごとの既定を GUILDA.setting に持ち、Name-Value `WarmStart`(true/false)で上書き。
- API Design ルール 7(共通 Name-Value)に `WarmStart` と `Limits`(10 節)を追加。
- OFF = フラットスタート: 位相 0、大きさ 1。PV 母線とスラック母線の大きさは設定値 `V`。
- 対象: 潮流計算、OPF、`initialize`。連続潮流計算は対象外。
- ウォームスタートのデータを捨てるのは Topology の編集のときだけ(母線タグの順序の確認も行う)。
- parameter / powerflow / operation の編集では保持(パラメータの掃引のため)。

**現状**: ウォームスタートなし。初期値は母線の `V0`/`Varg0`。NR / LM / fsolve は全母線を `V0`/`Varg0` から開始。PV・スラックの大きさを設定値にするのは gradient だけ(`private/power_equation.m` の `rv_xp0`)。

## 8. キャッシュの有効性

**決定**(コーディネーターの提案)

- `PowerNetwork` に 3 つの改訂カウンタを持ち、`handle_edit` で増やす。分類は `@PowerNetwork/handle_edit.m` の現在の分類(stale タグ powerflow)に合わせる。

  | カウンタ | 増やす編集 | 無効にするもの |
  |---|---|---|
  | Y | ブランチの dynamics、母線の dynamics(`Gshunt`、`Bshunt`)、ネットワークの Topology、ネットワークの base | アドミタンス行列(と、それを使う方程式) |
  | PF | Y の編集すべて、母線の powerflow・Slack・Topology(機器の接続)、機器の powerflow | 方程式のハンドル |
  | Topology | ネットワークの Topology(母線・ブランチの追加、削除、置換) | ウォームスタートのデータ(とすべてのキャッシュ) |

- キャッシュは作成時のカウンタを記録し、使用時に比較。
- 保存したウォームスタートは、タグではなくオブジェクトの同一性で母線に対応付ける(タグの変更では捨てない)。
- 以下の表は提案時の整理(上の表で確定)。

| 編集 | ウォームスタート | キャッシュ |
|---|---|---|
| Topology | 捨てる | すべて再構築 |
| powerflow | 保持 | 方程式を再構築 |
| ブランチのパラメータ | 保持 | アドミタンス行列を再構築 |
| Slack | 保持 | 方程式を再構築 |
| dynamics / operation / Tag | 保持 | 両方保持 |

- 注: 母線の dynamics(`Gshunt`、`Bshunt`)はアドミタンス行列に入るため、ブランチのパラメータと同じ扱いが必要(詳細化で確認)。

**現状**: 改訂カウンタはない。`_auxiliary/@LayerPackage/log_edit.m` が編集を上位の層へ通知し、`@PowerNetwork/handle_edit.m` が `sct_stale.powerflow` にログを追加(ネットワークの base / Topology、母線の dynamics / powerflow / Slack / Topology、ブランチの dynamics、機器の powerflow)。

## 9. 母線の `V0`/`Varg0` の廃止

**決定**: 母線の `V0`/`Varg0` パラメータを削除。初期値は各 Solver が管理(7 節)。

影響箇所(`grep -rwE "V0|Varg0"`、`0af04ad3` で確認):

| 箇所 | 内容 |
|---|---|
| `_GUILDAsystem/@PowerNetwork/add_bus.m` | Name-Value `V0`、`Varg0` |
| `_GUILDAsystem/@Bus/Bus.m` | powerflow グループの列とコメント |
| `_GUILDAsystem/@Bus/get_pf_condition.m` | 出力列 `Varg0`、`V0` |
| `_GUILDAsystem/_auxiliary/@SolverPF/solve.m` | 孤立母線の電圧、gradient の自動 α(`tab.V0`) |
| `_GUILDAsystem/_auxiliary/@SolverPF/private/power_equation.m` | 初期点 `rv_x0`、`rv_xp0` |
| `_GUILDAsystem/_auxiliary/@SolverOPF/private/build_bus.m` | `x0` |
| `_GUILDAsystem/_auxiliary/@SolverOPF/build_problem.m` | ヘルプ |
| `_GUILDAsystem/@PowerNetwork/optimize_powerflow.m` | ヘルプ |
| `_GUILDAsystem/_auxiliary/@MethodDynamic/solve.m` | 初期状態 `Tinit`、`Vinit` |
| `_GUILDAsystem/@PowerNetwork/import_csv.m` | 任意列。旧列は INFO メッセージを出して無視 |
| `_GUILDAsystem/@PowerNetwork/import_matpower.m` | `V0`/`Varg0` = VM/VA を読まない(下の注) |
| `_GUILDAsystem/+tools/network_to_mpc.m` | VM/VA の書き出し(平衡点の電圧、なければ 1/0)、発電機 `VG` の代替値 `pf.V0` |
| `_GUILDAobject/+network/@IEEE9bus`、`@IEEE68bus`、`@IEEJ_EAST10`、`@IEEJ_EAST30`、`@IEEJ_WEST10`、`@IEEJ_WEST30` の `bus/parameter.csv`(IEEJ は night / peak) | 列の削除 |
| `_GUILDAobject/+network/@IEEJ_WEST30/IEEJ_WEST30.m` | ヘルプ(初期値の説明) |
| `_GUILDAobject/+network/@IEEJ_EAST30/IEEJ_EAST30.m` | ヘルプ 38 行(報告書データの電圧を指す可能性あり、要確認) |
| `+DebugScript/test_F17_parameter_type.m` | `removevars(tab0, "V0")`(別の列で置き換え) |
| `_GUILDAdoc/developer/`: `class-design.html`、`feature-data-io.html`、`feature-model-building.html`、`feature-opf.html`、`feature-power-flow.html` | 説明の更新 |
| `notes/`: `get-sys-workflow.md`、`model-building-workflow.md`、`simulate-review-workflow.md`、`status.md`、`v4-migration.md` | 調査文書は基準コミットの記録のため本文を変えない。`v4-migration.md`、`status.md` は更新 |

対象外(同名の別物、grep の誤検出):

- `controller.local_LQR` の `V0`(設計モデルの無限大母線電圧)、`local_LQR_retrofit` の `V0`(平衡点の端子電圧)、`@LocalController/handle_edit.m` のコメント、`SystemTools/GUILDA/en/local_LQR.xml`。
- `+DebugScript/test_F3_edit_handling.m`、`test_F3_initialize.m`(ローカル変数 `V0`)。
- `+DebugScript/+helper/build_smib.m`(local_LQR の `V0` のコメント)。
- `+DebugScript/test_I71_layer_get_sys.m` 167 行(「V0 = 1 と異なる母線」というコメント。母線の既定電圧の意味なので表現だけ見直す)。
- `_GUILDAdoc/vendor/katex/katex.min.js`。

注: `import_matpower` は VA から `Varg`(スラックの位相)、発電機のない母線では VM から `V` も設定する。「VM/VA を読まない」のは初期値としての用途だけ。

## 10. `operation` 制約の扱い

**決定**

- 潮流計算は `operation` の制約を課さない(頑健性のため)。
  - PV→PQ の切り替えなし、OLTC なし、注入は定 PQ。
  - 将来の ZIP 負荷は潮流解を基準電圧とする。
- `ResultPF` は違反を表 `tab_violation` に記録するだけ(警告もエラーもなし。違反がなければ 0 行)。
- `SolverPF` は「方程式の構築 → Method で 1 回解く」のまま。制約の切り替えやタップの外側ループは `SolverCPF` / `SolverOPF` の役割。
- 連続潮流計算のオプション `Limits`: `["Q","V","S"]` の string 配列、または `"all"` / `"none"`。既定 `"none"`(GUILDA.setting)、Name-Value で上書き。
- OPF は常に制約を課す(制約を外すには `Inf`)。
- `simulate` は違反を記録するだけ。動的なリミッタは `dynamics` パラメータのまま。
- 有効な制約の状態や調整したタップは、`calculate_*` ではモデルに書き戻さない。書き戻すのは `initialize` だけ(`get_sys` の線形化のため)。

**現状**: 潮流計算・連続潮流計算は `operation` を読まない。OPF は母線の `Vmin`/`Vmax`(`build_bus.m`)ほかを使用。`SolverCPF` に `Limits` はない。

## 11. 既存の不具合(別途修正)

- `set_equilibrium(..., QdistributionRule="Qmax")` は機器の `operation` の `Qmin`/`Qmax` で Q を配分する(`_GUILDAsystem/@Bus/set_equilibrium.m` の `distribute_power`)。
- しかし `Qmin`/`Qmax` を編集しても平衡点が stale にならない。
  - `@Component/handle_edit.m` は dynamics と Topology だけに反応。
  - `@PowerNetwork/handle_edit.m` も機器の operation 編集を扱わない。

## コードと決定の食い違い・補足(`0af04ad3` で確認)

- `SolverPF` の Name-Value は `MaxIteration`、プロパティと JSON キーは `MaxIterations`(変更後は `MaxIteration` に統一)。
- `SolverPF` の `WhenFailed` のプロパティ既定は `"NONE"`、JSON は `"WARN"`(コンストラクタが JSON で上書きするので実害なし)。
- NR の既定値が JSON(1e-5、1000)と `run_method`(1e-8、50)の 2 か所(1 節の決定で解消。手順 A で NR クラスが JSON を読まなくなった。`run_method` の値の削除は手順 B)。
- 連続潮流計算の修正子は JSON の NR `MaxIter` 1000、`StepSize` 1 を使用(手順 A では `@SolverCPF/solve.m` が `GUILDA.config("MethodNewtonRaphson", ...)` から明示的に渡す。手順 B で ContinuationPowerFlow セクションへ移動、2 節)。
- `MethodDynamic` の `Damper` 既定は 0.1(決定は 1)。flag は logical(他の Method と異なる)。
- `import_matpower` の VM/VA は初期値以外にも使用(9 節の注)。

## 12. 数値微分の共有

**決定**: 中心差分のヤコビアンは `tools.fd_jacobian`(`_GUILDAsystem/+tools/fd_jacobian.m`)の 1 か所で計算。

- 列 i は (f(x + Step·e_i) − f(x − Step·e_i)) / (2·Step)。Name-Value `Step` は必須(既定値なし)。
- 呼び出し元と刻み(現状の値と差分の形を維持し、結果はビット単位で同一):
  - `MethodBase.eval_jacobian`: `Increment`(NR の既定 1e-4、x ± 1e-4)。旧 `@MethodNewtonRaphson/numerical_differentiation.m` は削除。
  - `@Component/private/Jacobi_dx_num.m`、`Jacobi_I_num.m`、`Jacobi_Y_num.m`: [x; V; I; u] を 1 本のベクトルにまとめて呼び、ブロックに分割(1e-5、x ± 0.5e-5)。
  - `@Component/validate.m`(上の `Jacobi_*_num` を使用)、`@LocalController/validate.m`(同じ 1e-5)。
  - 連続潮流計算の予測子・修正子: `Increment`(`@SolverCPF/solve.m`)。

## 未決

2. `Tolerance` の既定値(IEEJ_WEST30 / EAST30 夜間で検証)。
3. `MethodDynamic` の再試行時の `foh_PQ` の値と、内部の安全上限。

決定済み(2026-11-09、番号は旧一覧): 1 `MethodBase` のメンバーと NR の改名(1 節)、4 ルール 7 への `WarmStart` / `Limits` の追加(7 節)、
5 違反の表 `tab_violation`(10 節)、6 GUILDA.setting のセクション(2 節)、7 改訂カウンタ(8 節)。
