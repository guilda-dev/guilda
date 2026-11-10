# 潮流計算のオプションと Solver/Method の再設計

潮流計算のオプション、`Method*` ソルバークラス、Solver オブジェクトのウォームスタートとキャッシュ、
母線の `V0`/`Varg0` の廃止、各解析での `operation` 制約の扱いの仕様。

- 決定: 2026-11-09、メンテナー。
- 基準コミット: `0af04ad3`(`refactor/design-alignment`)。「現状」はこのコミットのコード。
- 状態: 手順 A(`MethodBase` と数値微分の共有、1 節・12 節)は `refactor/method-base` で実装。
  手順 B(SolverPF のオプション、GUILDA.setting のセクション、ウォームスタート、キャッシュ、
  母線の `V0`/`Varg0` の廃止、`tab_violation`)は `refactor/powerflow-options` で実装(「手順 B の実装」節)。
  手順 C(連続潮流計算の `Limits`、10 節)は `feature/cpf-limits` で実装(「手順 C の実装」節)。実装の指示書はこのノートを引用する。
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
- 既定値は 1e-8(2026-11-10 決定、コーディネーターの数値実験)。
  - フラットスタートの NR は全系統 4〜7 反復で 1e-8 を下回る。
  - 1e-8 で止めた初期化後の 10 s シミュレーション(イベントなし)のドリフトは全系統 1e-12 以下。1e-6 では WEST30 夜間で 7e-7。
  - 1e-12 以下は大規模系統の丸め誤差の下限(約 1e-13)に近く不可。

**現状**: 意味が手法ごとに異なる(1 節の表)。NR はステップ幅で判定し、不平衡は `max(1e-6, Tolerance)` で追加確認。fsolve の `FunctionTolerance` は不平衡の最大値ではない。

## 4. MethodDynamic

**決定**

- `Mass`、`Damper`、`foh_PQ` は GUILDA.setting に置かず、自動。
  - `Mass` 0。
  - `Damper` 1(`Mass` 0 では時間の尺度を変えるだけのため)。
  - `foh_PQ` 0 固定。再試行しない(2026-11-10、コーディネーターの実験: 解がない負荷では foh 0/1/5/20 のすべてが同じく失敗し、
    解がある限界近くでは foh 0 で全部収束。foh で解けるようになった例はない)。
- `t_span` は廃止。収束で停止し、内部の安全上限は仮想時間 1e4
  (Damper 1 で収束までの仮想時間はふだん 1000 以下、負荷限界近くで最大約 3500。実時間は常に 0.5 s 未満)。
- ODE の許容誤差は `Tolerance` に合わせる: AbsTol = min(Tolerance, 1e-5)、RelTol = min(100·Tolerance, 1e-4)
  (Tolerance 1e-10 で RelTol 1e-6 / AbsTol 1e-8 では上限まで収束しないケースがあり、1e-8 / 1e-10 で収束)。
- flag は他の Method と同じ 1 収束 / 0 安全上限 / -2 電圧崩壊・位相角不安定・積分の失敗。

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

## 11. `Qmin`/`Qmax` の編集と平衡点

**決定**(2026-11-10): 対応しない。`Qmin`/`Qmax` を編集しても、"Qmax" 配分則の平衡点は stale にしない(現状のまま)。

- 理由: 機器が 1 台なら配分自体が起きない、Q が NaN でない機器は対象外、上下限が無限なら "baseMVA" に戻るなど、stale にすべき場合の判定が複雑になる。
- 現状: `Bus.set_equilibrium(..., QdistributionRule="Qmax")` は機器の `operation` の `Qmin`/`Qmax` で Q を配分する(`tools.distribute_power`)。
  `@Component/handle_edit.m` は dynamics と Topology、`@PowerNetwork/handle_edit.m` は operation を stale の判定に使わない。
  `initialize` は既定の "baseMVA" を使い、"Qmax" を選ぶ手段はない(`Bus.set_equilibrium` は外から呼べない)。

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

## 手順 B の実装(`refactor/powerflow-options`、2026-11-10)

**現状**(実装後のコード)

- 設定: `SolverPF` は設定のプロパティを持たない。`get_options` が PowerFlowCalculation セクションの値の構造体を `tools.resolve_options` に渡し、
  Name-Value を適用。`OptionMap` は `Method`、`Tolerance`、`MaxIteration`、`Verbose`(→ `Display`)、`WarmStart`。
  旧ユーザー設定のキーは `v3_user_config` が変換(`MaxIterations`、`MaxFunEvals`、`UseParallel` は改名、`Display`、`PlotFcn` は削除、`Tolerance` 0 は削除)。
- `Tolerance` は Name-Value で `mustBePositive`(0 の「手法の既定」は廃止)。
- `MethodDynamic`: 初期値は `PFcondition` の列 `Varg0`、`V0`(SolverPF が初期電圧を渡すための列。なければフラットスタート)。
  初期値で収束済みなら積分せずに flag 1(ウォームスタートでイベントが交差しないため)。
- ウォームスタートの既定は PowerFlowCalculation が true、OptimalPowerFlow が false(Q3 の決定。下の「Q3〜Q6 の実装」)。`initialize` は自身の既定を持たず、`WarmStart` を潮流計算 / OPF に渡す。
  `optimize_powerflow` の `WarmStart` は呼び出しのオプション(`SolverOPF` に設定のプロパティを足さないため)。
- フラットスタートのスラック母線の位相は設定値 `Varg`(2 節の「位相 0」は PQ・PV 母線。旧コードもスラックは `Varg` から開始)。
- キャッシュ: `SolverPF` はアドミタンス行列(n_revY)と潮流条件・方程式(n_revPF)を保持。母線の並びがオブジェクトとして同じで n_revTopology が同じときだけ使う。
  結果の行名は毎回の母線のタグ(タグの編集はカウンタを増やさない)。収束した解(flag 1)だけをウォームスタートに保存。
- OPF: `SolverOPF` は最後に解けた AC OPF の母線の [Varg, V] を保持。`build_opf_problem` の x0 は常にフラットスタート。OPF の問題のキャッシュは Q4(下の「Q3〜Q6 の実装」)。
- `tab_violation` の列: `Class`("Bus" / "Component" / "Branch")、`Object`(タグ)、`Limit`(例 "Vmax"、"Qmin"、"Smax")、`Value`、`Bound`、`Excess`(|Value − Bound|)。
  違反が `Tolerance` を超えるものだけ。機器の P、Q は `initialize` が与える値(`Bus.set_equilibrium` の "baseMVA" 規則と同じ配分を `@SolverPF/private/violation_table.m` で再計算)。
  ブランチは両端の大きい方の |P|、|Q|、|S|、|I| と |Varg_from − Varg_to|。収束しなければ 0 行。
- 確認(MATLAB R2026a): フラットスタート・既定の `Tolerance` 1e-8 で、変更前(`313dc8d1`、保存した初期値、`Tolerance` 1e-10)の NR 解との差は
  IEEE9 / IEEE68 / IEEJ 10・30 機(ピーク・夜間)で最大 1.4e-10(newton)、1.1e-8(levenberg-marquardt、EAST10 夜間)、1.1e-10(fsolve)。
  `Tolerance` 1e-10 では newton・LM・fsolve とも 1.1e-10 以下。dynamic は 1e-8 で最大 3.1e-7、1e-10 で 3.1e-9。
- fsolve: `Tolerance` 1e-8 では上の全系統で flag 1。1e-10 では EAST30 ピーク、WEST10 夜間、WEST30 夜間で fsolve が最大不平衡 1.5e-10〜1.5e-9 で止まり flag -2。
- 連続潮流計算(IEEE14、LoadBus B009・B014): 変更前と同じ 362 点、λ の差 4e-12、電圧の差 1e-12(初期の平衡点の差による)。
- ウォームスタートの効果: 負荷を 1 % ずつ増やす掃引で newton の反復は 4〜6 → 2〜4、dynamic の ODE ステップは 25〜45 % 減。同じ条件の再計算は 0 反復。
  1 回の実時間は方程式と結果の表の作成が大半で、差は 1 割前後。AC OPF(fmincon 内点法)では反復が減るとは限らない(IEEE14 17 → 22、IEEE68 80 → 55)。
- IEEJ 30 機のフラットスタートからの `initialize` 後、イベントなし 10 s のドリフト: WEST30 ピーク 1.9e-12、夜間 5.4e-14、EAST30 ピーク 8.2e-14、夜間 3.5e-12。

**要判断**(実装では決めていない。3〜6 は 2026-11-10 に決定、「Q3〜Q6 の実装」)

1. `net.solver_OPF` / `solver_CPF` / `solver_ODE` / `solver_LIN` は今も数値の設定を保存する(6 節の「一般の数値設定は保存しない」は手順 B では `SolverPF` だけ)。
2. `initialize(Method="powerflow")` で潮流計算の手法を選ぶ手段は GUILDA.setting だけ(`Method` は initialize 自身の名前)。旧 `net.solver_PF.Method = ...` の代わりが必要か。
3. AC OPF の `WarmStart` の既定(true)。内点法では反復が減るとは限らない(上の記録、status.md の OPF の記録も同様)。
4. OPF の問題のキャッシュ: `operation` / `OPF` の編集を数えるカウンタがないため実装していない。
5. fsolve で `Tolerance` を 1e-10 程度まで下げると flag -2 になる系統がある。対処案(未検証): `FunctionTolerance` を `Tolerance^2` にする、または fsolve の後に NR で仕上げる。
6. 機器の違反の判定は `Bus.set_equilibrium` の配分を複製している(`QdistributionRule` "Qmax" の系統では initialize の値と異なりうる)。

## 手順 C の実装(`feature/cpf-limits`、2026-11-10)

**現状**(実装後のコード)

- オプション: `SolverCPF.Limits`(`(1,:) string`、既定 `"none"`)。JSON キー `Limits`(`DefaultContinuationPowerFlow.json`)、`OptionMap` の `Limits`、`validate_options` の検査。
  - 値: `"Q"`・`"V"`・`"S"` の重複のない部分集合(順序は自由)、または `"all"` / `"none"` 単独。それ以外は `GUILDA:SolverCPF:InvalidLimits`。
  - 直接設定した保存値(`net.solver_CPF.Limits = ...`)も `get_options` で検査。`result.options.Limits` は与えた値のまま(`"all"` は展開しない)。
- 制約の一覧: `@SolverCPF/private/limit_set.m`(有限の制約ごとに 1 行)、点での値: `limit_values.m`。Inf・NaN は制約なし。
  - `"Q"`: スラックでない PV 母線。発電機 = `powerflow` の `Q` が NaN の機器(`Bus.get_pf_condition` が PV とする根拠と同じ)。
    限界は発電機の `Qmin` / `Qmax` の合計、値は「母線の注入 Q − 他の機器の Q(`LoadBus` なら (1+λ) 倍)」。
  - `"V"`: 母線の `|V|` と `Vmin` / `Vmax`(PV・スラック母線も対象。電圧は設定値に固定)。
  - `"S"`: ブランチの両端の大きい方の `|S|` と `Smax`(`ResultPF.tab_violation` と同じ定義)。
- 検出: 修正後の点で値が制約を `Tolerance`(修正子の許容誤差、既定 1e-5)より大きく超えたら、直前の点との線形内挿で制約に達する点を求める。ステップ内で最初に達した制約(内挿の割合が最小)を処理。
  - `"Q"`: 母線を PQ に切替(`w.rv_Qfix` に限界値、`build_layout` の `lv_PQ`)。内挿点をその λ で修正(`correct_at`、λ 固定)。
    切替で他の発電機が限界を超えたら同じ点で続けて切替。予測子は接線から再開(向きは直前のステップ、長さは `sqrt(ArcLength)`)。PQ→PV には戻さない。
  - `"V"` / `"S"`: 内挿点を、直前の点を中心とする球面上で修正(先端付近でも λ 固定より頑健)し、その点で終了。
  - 1 ステップ内で出入りした制約(往復)は検出しない。
- 初期点で既に違反している制約(提案どおり実装): `"Q"` はその点で切替(初期点は平衡点から λ 固定で修正した点になる)、`"V"` / `"S"` は 1 点の経路で終了し `flag = false`。
- 結果: `ResultCPF.tab_switch`(列 `lambda`、`Step`、`Bus`、`Limit`、`Bound`)、`ResultCPF.tab_stop`(0 または 1 行。列 `lambda`、`Step`、`Class`、`Object`、`Limit`、`Bound`)。
  `Step` は `rv_lambda` での位置。`lambda` は `tab_path` と同じ小文字(他の列は `tab_violation` に合わせた)。
- `flag`: 先端を越えた、または 1 ステップ以上の後に `"V"` / `"S"` で終了したとき true。先端より前で止まると `r_lambdaMax` は停止点の λ。
- `"Q"` と `UseInternalState=true` の組み合わせは `GUILDA:SolverCPF:LimitsInternalState`(発電機の Q が内部状態で決まり、PV/PQ の区別がないため)。`"V"`・`"S"` は内部状態ありでも使用可。
- モデルへの書き戻しなし(母線はモデル上 PV のまま、stale にもならない)。`operation` の編集は平衡点を古くしない(8 節・11 節)ので、制約を変えて `initialize` なしで再計算できる。
- `Limits="none"` の経路は変更前(`84e0a421`)とビット単位で一致(IEEE14、`LoadBus` B009・B014 と B009〜B014、`UseInternalState` true / false で `rm_x`、`rm_xPredicted`、修正子の反復回数を比較)。IEEE14・B009・B014 は 362 点。
- 拡張: 他の制約(ブランチの `Imax`、`Pmax` など)は `limit_set.m` に行、`limit_values.m` に値、`validate_options` と JSON の説明に種類を足す。経路を終える制約はそれだけで対応(`feature-cpf.html` の「機能を拡張する箇所」)。

**代表系統での挙動**(IEEE14、`LoadBus` = B009〜B014、既定の設定)

| `Limits` | 経路 | 切替(λ、母線、限界) | 停止 |
|---|---|---|---|
| `"none"` | 先端 λ ≈ 4.03 | – | – |
| `"Q"` | 146 点、先端 λ ≈ 1.29 | 0.198 B002 Qmax 0.5、0.309 B006 Qmax 0.24、0.351 B008 Qmax 0.24、0.530 B003 Qmax 0.4 | – |
| `"V"`、`"all"`(元のデータ) | 1 点、`flag = false` | – | 初期点で B006 の Vmax 1.06(設定電圧 1.07) |
| `"V"`(全母線の Vmax 1.1、B009〜B014 の Vmin 0.95) | 52 点 | – | λ ≈ 1.423、B014 Vmin 0.95(停止点の \|V\| = 0.950005) |
| `"all"`(同上) | 28 点 | 上の `"Q"` と同じ 4 件 | λ ≈ 0.677、B014 Vmin 0.95 |
| `"S"`(EL001 の Smax 1.94) | 23 点 | – | λ ≈ 0.613、EL001 Smax(停止点の \|S\| = 1.940246) |

- IEEE14 の元のデータでは B006(1.07)、B007(1.0615)、B008(1.09)が初期点で Vmax 1.06 を超える(`ResultPF.tab_violation` にも出る)。`"V"` を含む `Limits` は初期点で止まる。

**要判断**

1. 初期点で違反している `"V"` / `"S"` の扱い。実装は「初期点で終了、`flag = false`」。IEEE14 の元のデータでは `Limits="all"` が常に 1 点で終わる。
   代案: (a) 初期点で違反している制約はその追跡では課さない(初期点の違反は `ResultPF.tab_violation` で確認する)、(b) 違反が初期点より悪化した点で止める、(c) INFO メッセージを出して (a)。
   推奨は現状か (a)。(a) なら `settle` の V/S の部分を「その行を無効にする」に変えるだけ。
2. `flag` の意味の拡張(制約で止まったら true)。`"V"`・`"S"` で止まった経路は「最大負荷 = 停止点」という解なので true とした。
3. `"Q"` の値の定義: 母線上の発電機(`Q` が NaN の機器)の Q の合計を、その `Qmin` / `Qmax` の合計と比較。
   `LoadBus` の PV 母線では発電機の P も (1+λ) 倍される(従来の連続潮流計算の扱い)が、切替後の Q は限界値に固定(倍しない)。
4. 切替の検出の許容幅に修正子の `Tolerance` を流用(Q・V・S とも pu)。独立した設定は作っていない。
5. Update log(`_GUILDAdoc/database/list_UpdateLog.js`)への告知は未記入(並行作業との衝突を避けるため。マージ時にコーディネーターが記入)。

## Q3〜Q6 の実装(`refactor/powerflow-options`、2026-11-10)

**決定**(メンテナー、2026-11-10): 手順 B の要判断 3〜6。

- Q3: OPF の `WarmStart` の既定は false(フラットスタート)。潮流計算は true のまま。
- Q4: `operation` と OPF の設定の編集を数える改訂カウンタを `PowerNetwork` に足し、`SolverOPF` が OPF の問題をキャッシュ。
- Q5: fsolve の `FunctionTolerance` は `Tolerance^2`。下の測定で効果がなかったため、`OptimalityTolerance` も `Tolerance^2`(追加の決定、2026-11-10)。
- Q6: 機器の P・Q の配分を 1 つの関数にまとめ、`Bus.set_equilibrium` と違反の表の両方から呼ぶ。
- `Qmin`/`Qmax` の編集と "Qmax" 配分則の平衡点は対応しない(11 節)。

**現状**(実装後のコード)

- Q3: `DefaultOptimalPowerFlow.json` の `WarmStart` は false。
  - 注意: `GUILDA` のコンストラクタ(起動時の準備)は全設定の値を `@GUILDA/user/*.json` に書き出す(`set_config`)。
    一度起動した環境では旧既定 true がユーザー設定として残り、JSON の既定の変更が反映されない(このワークツリーでも true のまま)。
    F4 のテストは `WarmStart` を明示し、配布する既定は JSON を直接読んで確認。
- Q4: `PowerNetwork.n_revOPF`(Revisions ブロック、private)。`handle_edit` が増やすのは、`n_revPF` を増やす編集すべて、
  ネットワークの `Hz`(base)、すべての層の `operation`・`OPF`・`Tag`(変数名がタグのため)。
  - `SolverOPF` の private プロパティ `sct_problem`(Network、Revision、Key、Problem、InitialPoint、Bounds)。
  - `solve` の内部関数 `cached_problem`: ネットワーク(オブジェクト)、`n_revOPF`、`Method`・`Cost`・`Constraint`(関数ハンドルを `isequal` で比較)・`DefaultCost`・`ReferenceBus`、
    `WarmStart` とその初期値(`rm_Vwarm`)が同じなら、保持した問題と x0 を再利用。保持するのは最後の 1 つ。
  - `optimproblem` の変数はハンドル(`OptimizationVariable` は handle クラス)。`result.OPFprob` の変数の上下限を変えると保持した問題も変わるため、
    再利用の前に全変数の `LowerBound`・`UpperBound`・`Type` を作成時の値と比較し、違えば作り直す。
    問題の複製(`getByteStreamFromArray`)は IEEE68 で 17 s と構築(3 s)より遅く、警告も出るため不採用。
  - `net.build_opf_problem` はキャッシュを使わず毎回構築(利用者が変更する問題を保持した問題と共有しないため)。`Problem` を渡した `solve` の確認用の構築(`Cost`・`Constraint` なし)はキャッシュを使う。
  - `WarmStart=true` の AC OPF は解くたびに `rm_Vwarm` が変わるので、毎回作り直す。
  - 効果(R2026a、`WarmStart=false`、同じ条件の 2 回目、3 回平均): IEEE14 DC OPF 0.75 → 0.11 s、AC OPF 1.94 → 0.96 s、
    IEEE68 DC OPF 1.02 → 0.22 s、AC OPF 22.2 → 19.1 s。`build_problem` 単体は IEEE14 0.2〜0.6 s、IEEE68 0.7〜2.6 s。
    2 回目は `solve` が問題から作るソルバー用の関数も再利用されるため、構築時間以上に短くなる。費用の差は 0。
  - テスト: F4 の「The OPF problem is kept until the network or the settings change」(変数のハンドルの共有で再利用を判定)。
- Q5: `@MethodFsolve/solve.m` が `FunctionTolerance` と `OptimalityTolerance` に `ConvTol^2` を渡す。`FunctionTolerance` だけでは効果がなかった(下の測定)。
  - 測定(フラットスタート、`Tolerance` 1e-10): 変更前後とも WEST10 夜間(不平衡 1.5e-10)、EAST30 ピーク(1.5e-9)、WEST30 夜間(6.9e-10)が flag -2。反復回数も同じ。
    `Tolerance` 1e-8 では全系統 flag 1(前後とも)。
  - FixedInput、IEEE9 ×0.95(`Solver="fsolve"`): `Tolerance` 1e-8 / 1e-10 では前後とも不平衡 1.7e-7 で停止(exitflag 1、flag -2 でエラー)。
  - 原因: fsolve は `OptimalityTolerance`(既定 1e-6、一次の最適性 ‖JᵀF‖∞)で exitflag 1 として止まっている。
  - 採用した `OptimalityTolerance` = `Tolerance^2`: IEEE9 / IEEE68 / IEEJ 10・30 機(ピーク・夜間)で `Tolerance` 1e-8・1e-10 とも全例 flag 1、不平衡 1.7e-13 以下、
    newton の解との差 2.4e-14 以下(反復は 1 回程度増え、時間はほぼ同じ)。FixedInput IEEE9 ×0.95 も 1e-6 / 1e-8 / 1e-10 で flag 1、不平衡 1e-14 以下。
    (比較: `OptimalityTolerance` = `Tolerance` でも潮流計算は全例 flag 1 だが、FixedInput の 1e-6 は不平衡 1.7e-7 のまま。)
  - テスト: F2 の「fsolve reaches a small Tolerance」(EAST30 ピーク、WEST30 夜間、`Tolerance` 1e-10、medium)、F3 の `FixedInputGivesTheSamePointWithEverySolver`(fsolve を既定と 1e-10 で、large)。
- Q6: `_GUILDAsystem/+tools/distribute_power.m`(2 つのクラスが使うので `+tools`)。`[P Q]` の行列を返す(機器ごとに 1 行)。
  - `Bus.set_equilibrium` の内部関数 `distribute_power` と、`@SolverPF/private/violation_table.m` の内部関数 `component_power` を削除して置き換え。
  - 確認: IEEE9 / IEEE14 / IEEE68 / IEEJ 10・30 機(ピーク・夜間)の初期化後の全 417 母線で、旧 `set_equilibrium` の配分とビット単位で同一("baseMVA"・"Qmax" とも)。
    旧 `component_power` との差は最大 4.4e-16(Q が NaN の機器が 1 台のときの計算順の違い)。
  - テスト: F2 の「Components share the bus P and Q as initialize gives them」(2 台の発電機での両規則の手計算、`initialize` と `tab_violation` の値の一致)。

**要判断**

1. `GUILDA` の起動時に全設定がユーザー設定ファイルへ書き出されるため、配布する既定値の変更(Q3 など)が既存の環境に反映されない。
   既定値と同じ値は書き出さない、などの対応をするか(このブランチでは未対応)。

**決定**(2026-11-10): OPF のキャッシュは `Cost`・`Constraint` を関数ハンドルの同一性で比較するだけで、関数が取り込んだハンドルオブジェクトの状態の変化は考慮しない(`Cost`・`Constraint` に渡すのは v、p だけという前提)。

## 未決

なし(手順 B の実装で出た判断事項は「手順 B の実装」節の末尾、Q3〜Q6 の判断事項は「Q3〜Q6 の実装」節の末尾)。

決定済み(2026-11-09、番号は旧一覧): 1 `MethodBase` のメンバーと NR の改名(1 節)、4 ルール 7 への `WarmStart` / `Limits` の追加(7 節)、
5 違反の表 `tab_violation`(10 節)、6 GUILDA.setting のセクション(2 節)、7 改訂カウンタ(8 節)。
決定済み(2026-11-10): 2 `Tolerance` の既定値 1e-8(3 節)、3 `MethodDynamic` は再試行せず、安全上限は仮想時間 1e4(4 節)。
