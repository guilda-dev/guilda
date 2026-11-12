# `net.simulate` 実行時内部構造の現状調査

> 当時の調査記録です。調査の基準は `951800e` で、以後の変更は本文に反映していません。現状は [status.md](status.md) と [v4-migration.md](v4-migration.md) を見てください。

対象コミット: `951800e`(ブランチ `docs/simulate-review-runtime`)。コア実装は変更していない。
改善案の統合は後続の作業の担当で、ここでは問題点の方向性までを 1 行で示す。

## 0. 読み方

### 根拠の区別

| 印 | 意味 |
|----|------|
| **[事実]** | コードを読んで確認した(無印の説明も同じ) |
| **[実機]** | MATLAB R2026a でプローブを実行して確認した(IEEE14bus、スクリプトはコミットしていない) |
| **[推測]** | コードからの推定で、動作は確認していない |
| **[未確認]** | 確認できていない |

`+DebugScript/test_F6_simulation.m` は R2026a で 37 件すべて PASS(47 s)**[実機]**。性能の実測は `simulate-review-measurements.md` の担当で、ここでは行わない。

### ファイルの略称(`略称:行`)

| 略称 | パス |
|------|------|
| `simulate.m` | `_GUILDAsystem/@PowerNetwork/simulate.m` |
| `odeSimulator.m` | `_GUILDAsystem/_auxiliary/@odeSimulator/odeSimulator.m` |
| `makeODE.m` / `CalculateInitialCondition.m` / `checkSimulationTime.m` | `_GUILDAsystem/_auxiliary/@odeSimulator/private/` |
| `odeEventSet.m` | `_GUILDAsystem/_auxiliary/@odeEventSet/odeEventSet.m` |
| `getTimeSpan.m` / `mustBeVector.m` | `_GUILDAsystem/_auxiliary/@odeEventSet/private/` |
| `odeProgress.m` | `_GUILDAsystem/_auxiliary/@odeProgress/odeProgress.m` |
| `odeSimulationResult.m` / `Plot.m` / `Export.m` | `_GUILDAsystem/_auxiliary/@odeSimulationResult/` |
| `AnalysisResult.m` | `_GUILDAsystem/_auxiliary/@AnalysisResult/AnalysisResult.m` |
| `Comp/gda.m` / `LC/gda.m` | `_GUILDAsystem/@Component/get_dx_algebraic.m` / `_GUILDAsystem/@LocalController/get_dx_algebraic.m` |
| `Component.m` / `LocalController.m` / `GlobalController.m` / `Bus.m` | `_GUILDAsystem/@<クラス>/<クラス>.m` |
| `PowerNetwork.m` / `reset_solver.m` / `check_edit.m` / `linearize.m` / `optimize_powerflow.m` | `_GUILDAsystem/@PowerNetwork/` |
| `add_local_controller.m` | `_GUILDAsystem/@Component/add_local_controller.m` |
| `load/@power/power.m` / `load/@impedance/impedance.m` | `_GUILDAobject/+component/+load/` |
| `resolve_options.m` / `complex2matrix.m` | `_GUILDAsystem/+tools/` |
| `v3_simulate_args.m` / `v3_ode_reporter.m` | `_GUILDAsystem/_VersionSupport/` |
| `TimeSim.json` | `@GUILDA/config/DefaultTimeSimulation.json` |
| `F6` | `+DebugScript/test_F6_simulation.m` |

## 1. 引数の構造

### 1.1 解析順序

1. `arguments` ブロックが `time` を `(:,1) double`(既定 `[]`)へ変換する。残りは `varargin` に入る(`simulate.m:40-46`)。
2. `split_events`: 先頭から連続する `odeEventSet` をイベントとし、残りを Name-Value とする。Name 位置の型と、Name-Value 中のイベントを検査して `GUILDA:PowerNetwork:SimulateArguments` を出す(`simulate.m:53,71-90`)。
3. `v3_simulate_args`: `Reporter`→`Progress`、`RelativeTolerance`→`Tolerance` に読み替える。大小文字は区別しない(`simulate.m:54`、`v3_simulate_args.m:19-30`)。
4. `take_call_options`: `Export` だけを取り出して検査する。奇数個なら何もせず後段に任せる(`simulate.m:55,92-116`)。
5. `solver_ODE.get_options`: `resolve_options` で名前と変換を処理し、`validate_options` で値を検査する。最後に metaclass で公開プロパティ全部を走査して `sct_options` を作る(`odeSimulator.m:124-137,701-714`)。
6. `solve` を呼び(`simulate.m:58`)、戻ったら `Plot`、`Export` の順に実行する(`simulate.m:60-67`)。

### 1.2 オプション一覧

優先順位は **呼び出しの Name-Value > `net.solver_ODE` のプロパティ > (生成時に読む)ユーザー JSON > システム JSON > クラス既定値**。

| Name-Value | 保存先 | クラス既定値 | JSON | 上書き経路 |
|---|---|---|---|---|
| `Solver` | `Solver`(`odeSimulator.m:28`) | `"ode15s"` | なし | `OptionMap` `:69`。**単独指定は実行に反映されない(§3.5)** |
| `SolverOptions` | `SolverOptions`(`:32`) | `ODE15s` | なし | `:70`。`OutputFcn` は常に上書きされる(`:202`) |
| `Tolerance` | `RelativeTolerance`(`:36`) | `1e-4` | `TimeSim.json:2-6` | `:71`、生成時 `:97` |
| `AbsoluteTolerance` | 同名(`:40`) | `1e-6` | `TimeSim.json:7-11` | `:72`、生成時 `:96` |
| `SeparateComplexParts` | 同名(`:43`) | `"off"` | `TimeSim.json:12-20` | `:73`、生成時 `:98` |
| `TimeLimit` | 同名(`:53`) | `10` | `TimeSim.json:31-35` | `:74`、生成時 `:100-105`(数値かつ正でなければ `inf`) |
| `Progress` | 同名(`:48`) | `"dialog"` | `TimeSim.json:21-30` | `:75`、`progress_mode` で true/false を変換(`:324-335`)、生成時 `:99` |
| `Verbose` | 同名(`:56`) | `false` | なし | `:76` |
| `Plot` | 同名(`:59`) | `false` | なし | `:77` |
| `Export` | 保存しない | `false`(`simulate.m:110`) | なし | 呼び出しのみ |
| (`Reporter`) | `Progress` への依存プロパティ(`odeSimulator.m:81,108-109`) | — | — | COMPAT(v3)。`v3_ode_reporter.m:16` が警告 |

- 既定値の読み込み: `PowerNetwork` の生成時に `reset_solver` が `odeSimulator()` を作り(`PowerNetwork.m:124`、`reset_solver.m:11`)、`GUILDA.config("TimeSimulation")` を読む(`odeSimulator.m:95`)。config は `persistent` でキャッシュされる(`@GUILDA/config.m:8-11`)。`@GUILDA/user/` の同名ファイルがシステム設定に上書きマージされる(`@GUILDA/private/get_config.m:16-29`)。
- `TimeSim.json:35` は末尾カンマを含み厳密な JSON ではないが、`readstruct` は読める **[実機]**(`TimeLimit=10`)。
- 上書きは呼び出し限りで、`solver_ODE` には書き戻さない(`resolve_options.m:5-6`、`odeSimulator.m:145`)。F6 でもテスト済み(`F6:144-154`)。
- 名前の照合は大小文字を区別しない(`resolve_options.m:76`)。`sct_options` には **変換前の値** が入る(例: `Plot=1` は double のまま)。`validate_options` は検査するだけで値を返さない(`odeSimulator.m:125`)。
- `get_options` の metaclass 走査(`:127-137`)は、`OptionMap` が公開設定 9 個を全部覆っているので、`resolve_options` が返す `sct_given` と同じ内容を作り直している。
- `take_call_options` は `linearize.m:52` と `optimize_powerflow.m:70` にも同名のローカルコピーがある。

### 1.3 `time` の形式

| 入力 | 動作 | 根拠 |
|---|---|---|
| `[t0,tend]` | 正常 | `getTimeSpan.m:5,13-17` |
| `[]`(イベントあり) | `[0, ceil(tmax/10)*30]`。例: 最大 1.05 s → `tEnd=30` **[実機]** | `getTimeSpan.m:6-11` |
| `[]` / 省略(イベントなし) | `[0,10]` **[実機]** | `odeSimulator.m:170-176`、`getTimeSpan.m:9-11` |
| 3 要素 `[0,2,4]` | **黙って `[0,2]` を計算** `flag=1, tEnd=2` **[実機]**。範囲外判定だけは `time(end)` を使うので不整合 | `getTimeSpan.m:13`、`odeEventSet.m:165` |
| スカラー `2` | `MATLAB:badsubscript` **[実機]** | `getTimeSpan.m:13` |
| 降順 `[4,0]` | `MATLAB:table:RowIndexOutOfRange` **[実機]** | `getTimeSpan.m:15`、`odeSimulator.m:196` |
| `[2,2]` | `MATLAB:badsubscript` **[実機]** | `getTimeSpan.m:13-17` |
| 省略してイベントが先頭 `simulate(ev)` | `MATLAB:validation:UnableToConvert` **[実機]** | `simulate.m:42` |

`simulate.m:42` の説明は `[t0,tend]` のみで、`[]` の意味は `solve` のコメントにしかない(`odeSimulator.m:157`)。

## 2. イベント

### 2.1 種類と内部表現

イベント型は存在せず、1 つの `odeEventSet` に下記プロパティが同居する(`odeEventSet.m:28-60`)。同じイベントで複数種類を同時に指定できる。

| 種類 | プロパティ | 実行時の変換 | 効果 |
|---|---|---|---|
| 母線地絡 | `FaultBus` | `l_isFault` 設定、`lv_FBorTC` に載る(`:333,354`) | V, I の 4 変数を除去し `EM` で 0 に固定。ボルト地絡のみ(インピーダンス指定なし) |
| 解列 | `TripUnit` | `l_isConnect`(`:497`、`odeSimulator.m:418`)、`lv_FBorTC` | 機器自身の x, u を除去、電流 0(`Comp/gda.m:34`) |
| 状態オフセット | `OffsetUnit/State/Value` | `rv_Xoffset`(`:245-252`) | 開始区間の `x0` に 1 回だけ加算(`:229,373`) |
| 入力加算 | `InputUnit/Name/Value` | `rv_Uoffset`(クロージャ、`:254-282`) | 右辺で `ue` に加算(`odeSimulator.m:466`) |
| 何もしない | `NoAction<n>` を自動生成 | `:195-205` | イベントのない区間を埋める |

**存在しない種類**: ブランチ開放・投入(`ctx.Ymat` は実行中固定 `odeSimulator.m:184`)、インピーダンス地絡、パラメータ変更。

コンストラクタは `sv_Btag, sv_Ctag, rv_Brep, rv_Crep` を **生成時点の** 系統から取る(`odeEventSet.m:102-122`)。後述のスナップショット問題の原因になる。

### 2.2 時間軸への展開と合成

- `odeEventSet.table` が全イベントの `[開始,終了]` を集め(`:154-162`)、`getTimeSpan` が `[t0, 全時刻, tend]` を `unique` して隣接区間に分割する(`getTimeSpan.m:13-17`)。
- 行=区間、列=イベントの論理表を作る。活性の条件は `(fti<etj)&&(ftj<eti)`、またはスカラーイベントで区間開始と一致すること(`:180-193`)。
- 複数イベントの合成(`setEventCondition`)
  - 同じ機器へのオフセットと入力は名前で照合して加算(`:247-281`、`F6:437-453`)
  - `FaultBus` / `TripUnit` は和集合(`:324-325`)
  - イベント列名は `s_tag`。**重複はエラー** `MATLAB:table:DuplicateVarNames`(同じタグで 2 回の地絡は書けない)。`t1` などの予約名も同じ **[実機]**(`:178-179,207`)
- 関数入力の `t` は「イベント開始からの経過時間」に換算する(`:299-301`)。

### 2.3 範囲外とスカラー

- 完全に範囲外のイベントは `GUILDA:odeEventSet:OutsideTimeSpan` の警告を出し、効果なし(`:164-171`、`F6:737-743`)。判定は `time` が 2 要素以上のときだけ。
- はみ出すイベントは切り詰める(`getTimeSpan.m:15`、`F6:456-468`)。オフセットは開始が `t0` より前でも第 1 区間で適用する(`:229`)。
- **スカラーの fault / trip / input は次の時刻境界まで続く** **[実機]**: `TimeSpan=1, FaultBus="B008"` を `[0,3]` で実行すると `[1,3]` がずっと地絡。`:29-31` の説明からは読み取れない。
- `tend` ちょうどのスカラーイベントは活性にならず、警告も出ない(`:165,189`)。

### 2.4 検証の範囲

`validate_input` は **入力イベントだけ** を検査する(`odeEventSet.m:435-464`)。

| 誤った指定 | 結果 |
|---|---|
| `FaultBus="B999"`, `TripUnit="NOPE"`, `OffsetUnit="NOPE"`, `OffsetState="nope"` | **エラーも警告もなく無外乱の結果を `flag=1` で返す** **[実機]**(`max\|omega\|≈1e-14`) |
| 他の系統のイベント | `PhaseFailed` / 添字エラー **[実機]**。`odeNetwork` と `net` の一致検査はない(`odeSimulator.m:178`、`odeEventSet.m:222`) |
| 機器追加より前に作ったイベント | `MATLAB:innerdim` **[実機]**(`:352-362,377`) |
| ローカル制御器のタグを `TripUnit` に指定 | 受理される。LC の x, u は除去され、右辺は x=0 の出力を親の入力へ流す(`:353-362`、`LC/gda.m:40`、`Comp/gda.m:30`)。`:47` の説明の対象外 |

## 3. 実行フェーズ

### 3.1 `solve` の呼び出し順

1. `tic`、`net.require_equilibrium()`: 古い `f_*` を再構築、平衡点が古ければ `EquilibriumStale`(`odeSimulator.m:166-167`、`PowerNetwork.m:202-207`、`check_edit.m:16-31`)
2. イベントなしなら `NoAction` を生成(`:170-176`)
3. `table` で区間表を作成(`:178`)
4. `initialize_index`: 全変数の添字を割当(`:179,340-409`)
5. `onCleanup` でグローバル制御器の接続を復元する予約(`:180`)
6. `ctx`: `net`, `Ymat`, `rv_odeV`, `absYmat`(`:182-186`)
7. `makeODE`、`odeset`(`:188-189`)
8. `odeProgress` を作り、`OutputFcn` と `EventDefinition` を設定(`:201-203`)
9. **区間ループ**(`:208-293`)
   1. 活性イベント抽出(`:211-213`)
   2. `set_gc_connect`(`:216-217`)
   3. `setEventCondition`: 全機器の `rv_Xoffset`, `rv_Uoffset` を更新(`:222`)
   4. `getInitialCondition`: `l_isFault`, `l_isConnect` を更新し `EM, RM, lv_FBorTC, x0, Mass` を作る(`:224`)
   5. `o` の `InitialValue`, `MassMatrix`, `ODEFcn`, `Jacobian` を設定(`:226-229`)
   6. `solve(o, 0, t2-t1)`。**時刻は区間ごとに 0 から**(`:248`)
   7. `NeedBetterY0` なら §3.5 のフォールバック(`:253-274`)、それ以外は `PhaseFailed`(`:256-259`)
   8. `Event2State` で `EM` 展開と電流計算(`:280`、`odeEventSet.m:388-430`)
   9. 終端未達なら `flag` を決めて脱出(`:281-288`)
   10. `getNextPhase` で次区間の初期値を作成(`:290`)
10. `output` 組み立て(`:295-314`)、`odeSimulationResult` 生成(`:319`)

### 3.2 区間間の状態引き継ぎ

`getNextPhase`(`odeSimulator.m:639-697`):

- `x0 = EM*x_end`、`M0 = EM*M*EM.'` で全次元に戻す(`:642-643`)。**除去された変数の質量は 0 のまま**。
- 解列中の **発電機** の状態を、現在の電圧・電流 0 の平衡値に、質量を `f_Mass` に戻す。ローカル制御器も同様(`:652-676`)。判定は `isa(...,'component.generator.abstract')`。
- 地絡母線の V, I は **事故前の平衡値** に戻す(`:679-684`)。
- 解列中のグローバル制御器は平衡値と `f_Mass` に戻す(`:689-696`)。
- 解列機器の u は 0 のまま(`EM` 由来)で復元しない。残りの不整合は ode15s の初期値補正か §3.5 のフォールバックに任せる。

次の `getInitialCondition` が `x0` にオフセットを加え(`odeEventSet.m:365-376`)、`RM*x0`, `RM*M0*RM.'` で縮約する(`:377,384`)。第 1 区間は平衡点+オフセット、入力は `rv_Uequilibrium + rv_Uoffset(0)` で作る(`:366,498`)。

`getXM` と `rv_V` の計算は **毎区間実行され、第 2 区間以降は `l_isConnect` の設定以外捨てられる**(`:331-342,364-383`)。

### 3.3 DAE の定式化

状態の並び(`odeSimulator.m:344-396`):

```
母線1 { 機器1 {x, u}, LC1 {x, u}, LC2 {x, u}, 機器2 {...} }, 母線2 {...}, ...
グローバル制御器 k の x (u, y は持たず他の添字を参照)
母線 i の V(re, im), I(re, im)
```

- 入力 u も **代数変数** であり、機器の u 方程式は `u_comp - u = 0`、制御器は `u_con - rv_U = 0`(`Comp/gda.m:36`、`LC/gda.m:39`)。
- 母線: `0 = I_i - Σ I_comp`(`:471`、`Comp/gda.m:36`)、`0 = I_i - (Y V)_i`(`:471`)。
- 質量行列: 各モデルの `f_Mass` と u の 0 を `blkdiag`、母線 4 変数は 0(`odeEventSet.m:348,382,500`)。**密行列**。
- 地絡・解列は `EM`(縮約→全体)、`RM`(全体→縮約)、`lg`(残す行)で変数を削除する(`:354-362`、`odeSimulator.m:228,425,484`)。
- 残差の丸め: 項の大きさの `16*eps` 未満の母線残差を 0 にする(`:473-480`)。IEEE68bus が `t=0` で止まった問題の回避策(`F6:696-710`)で、そのために `absYmat*abs(V)` を毎回計算する(`:186,431`)。

### 3.4 右辺 1 回の評価順(`getODEFunction` `:422-486`)

1. `x = EM*x`、`I = Ymat*V`、`absI = absYmat*|V|`(`:425-431`)
2. グローバル制御器ごと: 接続中のみ `f_dx`, `f_Y`。入力は機器の状態 × 接続マスク(`dcellfun` の対角行列)(`:438-451`)
3. 母線ごと、機器ごと:
   1. `ue = 平衡 + y_GC + rv_Uoffset(t)`(`:464-466`)
   2. `Component.get_dx_algebraic`:
      1. 制御器があれば機器の `f_Y` で観測値を作る(`Comp/gda.m:25-26`)
      2. `LC.get_dx_algebraic`(再帰): 入力組立 → ネスト先 LC2 → 名前照合 → 自身の `f_dx`, `f_Y`(`LC/gda.m:15-41`)
      3. **LC の出力で `u` を置換**(`Comp/gda.m:29-30`)
      4. 機器の `f_dx`, `f_I`(`:33-34`)
   3. 母線の項を加算し残差を丸める(`:471-480`)
4. `odeX(lg)` を返す(`:484`)

**置換の帰結**: 入力イベントとグローバル制御器の出力は `ue` に足されたあとで LC 出力に **上書きされる**。AVR 付き発電機の `Vfield` に `InputValue=0.5` を与えても変化量 `1.5e-12`、エラーも警告も出ない **[実機]**。

### 3.5 ソルバーの使い方とフォールバック

- `makeODE` は `ode` の全 public プロパティのうち `sct_options` にあるものをプロパティ順に設定する(`makeODE.m:4-16`)。
- **`Solver` 単独指定は無効** **[実機]**: `Solver` の次に `SolverOptions`(既定 `ODE15s`)を設定するので、`ode` 側が `Solver` を `ode15s` へ戻す(`o.Solver="ode23t"` → `o.SolverOptions=ODE15s` → `o.Solver==ode15s`)。
  - `net.simulate(..., Solver="ode23t")` は既定と **完全に同一の解**(`isequaln`、144 点)。`Solver="ode45"` も特異質量行列なのに `flag=1` で完走する。
  - `SolverOptions=matlab.ode.options.ODE23t` を併記すれば 276 点となり本当に切り替わる。`ODE45` 併記は `PhaseFailed`。
  - `result.options.Solver` は `"ode23t"` のままで **記録が事実と異なる**。`F6:149-151` はこの記録値しか見ていない。
  - `Solver="auto"` 等は `makeODE` の `set.SolverOptions` でエラーになる見込み(`ode` のエラー文 **[実機]**、`simulate` 経由は **[未確認]**)。`makeODE` は `try` の外(`:188`)。
- ヤコビアンは常に関数で与える(`:229`)。`Component` は解析ヤコビアンがなければ数値版を使う(`Component.m:173-189`)。**密行列でパターンの指定もない**(`:495,633`)。
- **解列の開始区間は `NeedBetterY0` に入る** **[実機]**: `MaxStep=1e-3` で解列 `[1,1.2]` の区間だけ `maxdt=0.0157` になる(無視されている)。解列後の復帰区間と、地絡の全区間は `maxdt=0.001` で通常経路だった。IEEE14bus の 1 条件での観測で、他の系統・条件は **[未確認]**。

**フォールバック経路**(`odeSimulator.m:253-274`、`CalculateInitialCondition.m`)は次のとおり。

- `decic` で代数変数のみ解く。失敗すると全変数を自由にして再試行し、微分状態も黙って動かす(`CalculateInitialCondition.m:16-23`)。傾きの初期推定は `xp0_est = x0_est`(`:9`)。
- その失敗は `warning` のみ。`exitFlag` は呼び出し側が捨てる(`:25-27`、`odeSimulator.m:254`)。`x0` が空のまま進み `UnfeasibleDAE` になる。
- 解き直しは `ode15s(ODEfcn, [0,dt], x0, options)` で、`options` は `RelTol, AbsTol, Mass, InitialSlope` のみ(`odeSimulator.m:189,265`、`CalculateInitialCondition.m:6,30`)。したがって以下が **無視される**。

| 無視されるもの | 確認 |
|---|---|
| `Solver`(常に ode15s) | **[事実]** `:265` |
| `SolverOptions`(MaxStep など) | **[実機]** `maxdt=0.040`(指定 `1e-3`) |
| `TimeLimit` | **[実機]** `TimeLimit=1e-9` でも `flag=1, tEnd=1`(通常経路は `flag=0`) |
| 進捗表示 | **[事実]** `OutputFcn` なし |
| 解析ヤコビアン | **[事実]** `Jacobian` を渡さず数値差分 |

### 3.6 ヤコビアンと右辺の不一致

- **解列機器**: 右辺は `l_isConnect * f_I`(`Comp/gda.m:34`)だが、ヤコビアンは `-Div, -Dii` を接続状態によらず母線行へ足す(`odeSimulator.m:618-619`)。
- **グローバル制御器のマスク**: 右辺は `u_connect*u_GC`(`:447-450`)、ヤコビアンは `u_GC` のまま(`:514-515`)。
- **LC による入力上書き**: `-Cyx_GC` は `iv_odeY` 行へ足される(`:517-518`)が、右辺では LC に上書きされて効かない(`Comp/gda.m:30`)。
- **残差の丸め**(`:480`)はヤコビアンに反映されない(影響はごく小さいと **[推測]**)。
- 影響: ニュートン法の収束が悪化するが解の精度には直接影響しない **[推測]**。誤差の大きさは **[未確認]**。

## 4. シミュレーション中の一時データ

### 4.1 モデル側に書くデータ

| 変数 | 宣言 | 書き込み | 読み取り | 後片付け |
|---|---|---|---|---|
| `iv_odeX/U` 機器・LC | `Component.m:93-94`, `LocalController.m:74-75` | `odeSimulator.m:402,405` | 右辺、ヤコビアン、`getNextPhase`、結果生成 | なし(次回上書き) |
| `iv_odeY` LC | `LocalController.m:76` | `:360,367` | `:557,598` | なし |
| `iv_odeY` 機器 | `Component.m:95` | **書かない** | `:536`(未使用変数) | — |
| `iv_odeX/U/Y` グローバル制御器 | `GlobalController.m:60-62` | `:379-387` | 右辺、ヤコビアン | なし |
| `iv_odeX/I` 母線 | `Bus.m:57-58` | `:392,394` | 同上 | なし |
| `iv_odeU` 母線 | `Bus.m:59` | **書かない** | 読まない | — |
| `rv_Xoffset` 機器 | `Component.m:122`(**public 書込み可**) | `odeEventSet.m:245,251` | `:373,498` | なし |
| `rv_Uoffset` 機器 | `Component.m:123`(同上) | `odeEventSet.m:282` | `odeSimulator.m:466`、`odeEventSet.m:498` | **なし**(クロージャが残る **[実機]**) |
| `rv_X/Uoffset` LC, グローバル制御器 | `LocalController.m:78-79`, `GlobalController.m:64-65` | 書かない(定数) | LC は `getXM` のみ | — |
| `l_isConnect` 機器 | `Component.m:119` | `odeEventSet.m:497` | `Comp/gda.m:34`, `odeSimulator.m:447,652` | **なし**(解列中に終わると `false` のまま **[実機]**、次の実行で上書き) |
| `l_isConnect` LC | `LocalController.m:81` | `odeEventSet.m:497` | **読まない** | なし |
| `l_isConnect` グローバル制御器 | `GlobalController.m:67` | `odeSimulator.m:418` | `:440,503,691` | **`onCleanup` で復元**(`:180`、`F6:626`) |
| `l_isFault` 母線 | `Bus.m:37` | `odeEventSet.m:333` | `odeSimulator.m:679` | **なし**(地絡中に終わると `true` のまま **[実機]**) |
| `odeIteration` イベント | `odeEventSet.m:65` | `:287` | **読まない** | なし(イベントオブジェクトを書き換える) |

- エラー・`Ctrl+C` 時も、後片付けはグローバル制御器の接続だけ。機器の `l_isConnect`、母線の `l_isFault`、オフセットは途中の値が残る(**[事実]**、エラー経路で残ることはコードから、正常終了時は実機で確認)。
- 残った値が他の解析に漏れる経路: `l_isConnect`, `l_isFault`, `rv_*offset` の読み手は上表のみで、線形化(`odeLinearizer`)は使わない **[事実]**(grep)。**現状で実害は確認していない**。
- `iv_odeX` などは結果生成(`odeSimulationResult.m:286-296`)が読むが、結果生成後は読まない。

### 4.2 実行ローカルなデータ

`ctx`, `tab_phase`, `c_odeEvnt`, `x0`, `Mass`, `o`, `odeProg`, `c_phase` は `solve` のローカルで、`solver_ODE` に保存されない(`odeSimulator.m:6-7,145`、`F6:141`)。

- `lastwarn` は区間ごとに退避・クリアして復元する(`:243-244,275-278`)。
- 待機バーは `odeProgress.delete` で閉じる(`odeProgress.m:88-93`)。自己参照(`@obj.dispFcn`)があるので、破棄のタイミングは GC 依存 **[推測]**。

### 4.3 制御器の内部状態とサンプル周期

- ローカル制御器・グローバル制御器の内部状態はすべて DAE の状態に含まれ、`persistent` やメモリは持たない。`_GUILDAobject/+controller` と `@*Controller` の grep で `sample/sampling/persistent/discrete` は 0 件 **[事実]**。
- **サンプル周期の概念は存在しない**: 制御器はすべて連続時間。離散制御を書く枠組みもない。
- グローバル制御器の入出力は 1 機あたりスカラー 1 個に限られる(`odeSimulator.m:386-387`)。
- `odeSimulator` のネストは **機器→LC1→LC2 の 2 段に固定**(`:354-369,552,657-672`)だが、`getTM`, `getXM`, `LC/gda.m`, `all_controllers` は再帰で書かれている。`add_local_controller` は AVR→PSS の 2 段しか作らないので現状では矛盾しない(`add_local_controller.m:4-8`)。

## 5. 結果と進捗

### 5.1 `odeSimulationResult`

- 継承 `AnalysisResult < auxiliary < handle`。保持: `flag, output, options, s_solver, r_elapsed, s_network`、Hidden の `a_PowerNetwork`(`AnalysisResult.m:30-53`)。
- 本体(`odeSimulationResult.m:32-62`)

| プロパティ | 内容 |
|---|---|
| `rv_t` | 時刻。**区間境界は 2 回現れる** |
| `tab_variable` | 実行時の変数表 |
| `rm_variable` | 全変数の軌道。列は x(機器+LC)、グローバル制御器の x、V、**機器の** u |
| `rm_I` | `Y*V` で後計算した電流(`odeEventSet.m:422-423`)。DAE の `I` 行そのものではない |
| `sv_bus`, `c_component` | タグ |
| `odeResults`(Dependent) | 初回アクセスで `build_view` し `sct_view` にキャッシュ(`:127-132,218-261`) |

- **結果に残らない変数**: LC の入力、母線 `I` の状態、グローバル制御器の入出力。
- 解列機器の x は NaN(`odeEventSet.m:418-420`)。**u は 0、LC の状態は実行値** のまま。
- 生成の流れ: `Event2State` が行列を `table` に包み(`odeEventSet.m:425-429`)、`cell2mat` で戻し(`odeSimulationResult.m:118-120`)、`simulator_columns` で並べ替える(`:122-124`)。不一致なら `VariableMap` エラー(`:301-304`)。
- `get_point`: 区間内は線形補間、境界は `Side` で選択(`:134-190`)。

### 5.2 `Plot` と `Export`

- `Plot=true` は全母線の `Vabs` を新規 figure に描き、軸は呼び出し側に返さない(`simulate.m:60-62`、`Plot.m:34-39`)。途中停止時はタイトルに明記(`Plot.m:44-50`)。
- `Export`: `.csv/.txt/.xlsx/.xls` は横長テーブル、`.mat` は `odeResults, options, flag, output`(`Export.m:19-27`)。
  - **LC・グローバル制御器の状態はどちらにも含まれない**(`Export.m:35-49`)。`.mat` にも `rm_variable`, `tab_variable` はない。
  - 拡張子の検査はシミュレーション **完了後**。`Export="a.json"` は計算後に `ExportFormat` で落ち、**結果を失う** **[実機]**(`simulate.m:63-67`)。

### 5.3 `odeProgress` と `TimeLimit`

- `OutputFcn` は `time_keeper`("none")、`dispFcn`、`dialogFcn` を切り替える(`odeProgress.m:55-65`)。
- `TimeLimit` の仕組み: `OutputFcn` は常に `f=0` を返し(`:130`)、時間超過で `ToBeContinue=false` にする(`:149-153`)。`odeEvent` のイベント関数がこの値を返し、`Response="stop"` で止まる(`odeSimulator.m:203`)。`isterminal`, `direction` の戻り値は使われない(`odeProgress.m:158-163`)。超過判定は 1 ステップごとで、ステップ内部は中断できない。
- `TimeLimit` は **区間ごと**(`odeProgress.m:137`)。全体で超過し得ることは `notes/status.md:200-203` に未決事項として記載済み。
- `flag=0` は **`Verbose=false` のとき何も表示せず警告も出さない** **[実機]**(evalc の出力 0 文字、`lastwarn` 空。`odeSimulator.m:315-317`)。**既定 `TimeLimit=10` 秒** なので、`sol = net.simulate(...)` だけの利用者は部分解に気づきにくい。
- 細部 **[事実]**
  - `waitbar(t/obj.tspan, ...)` は絶対時刻で計算するので、`t0≠0` で進捗率がずれる(`odeProgress.m:83`)。
  - `dialogFcn` は `break` でも `otherwise` に入り、バーがなければ作る(`:72-80`)。
  - `isinf(timelimit)` では `break` のメッセージ処理まで飛ばされる(`:131-133`)。
  - 中止ボタンはない。

### 5.4 flag / output / 部分結果

| 結末 | flag | result | 通知 |
|---|---|---|---|
| 完了 | 1 | 全区間 | `Verbose` のみ |
| TimeLimit | 0 | 到達点まで | `Verbose` のみ |
| ソルバー停止 | -1 | 到達点まで | ソルバーの警告+`output.message`(`odeSimulator.m:307-313`) |
| 区間内の例外 | — | **なし**(完了済み区間も捨てる) | 例外(`:256-259`) |

判定は `sol.Time(end) < t2-t1` と `ToBeContinue`(`:281-288`)。`output` は `tEnd, nPhases, nPhasesDone, phases, message`(`:295-299`)。`l_success` は flag>0(`AnalysisResult.m:145-146`)。

## 6. エラー処理と拡張性

### 6.1 例外の経路

| 段階 | 例外 | 種類 |
|---|---|---|
| `arguments` / `split_events` | `UnableToConvert` / `SimulateArguments` | MATLAB / GUILDA |
| `resolve_options` | `UnknownName`, `InvalidPairs` | GUILDA |
| `validate_options` | 値の検査 | MATLAB |
| `require_equilibrium` | `EquilibriumStale` | GUILDA |
| `table`(入力の検査) | `UnknownInputUnit/Name`, `InvalidNargin` | GUILDA |
| `getTimeSpan`, `table`(タグ重複) | `badsubscript`, `DuplicateVarNames` | **MATLAB 生** |
| `setEventCondition`, `getInitialCondition` | `innerdim` など | **MATLAB 生**(`try` の外 `:222,224`) |
| `rv_Uoffset(0)` の評価 | ユーザー関数の例外 | **MATLAB 生**(`odeEventSet.m:498` は毎区間 `t=0` で呼ぶ) |
| `solve(o,...)` | `PhaseFailed`(cause 付き) | GUILDA |
| フォールバック | `UnfeasibleDAE`(cause 付き) | GUILDA |
| 結果生成 | `VariableMap` | GUILDA |
| `Plot` / `Export` | `UnknownBus` など | GUILDA、**結果消失** |

### 6.2 追加時に触る箇所

**新しいイベント型**(型の抽象がないので散在する。例: ブランチ開放)

1. `odeEventSet.m:28-60` プロパティ追加(コンストラクタは `opt.?odeEventSet` で自動)
2. `odeEventSet.m:435-464` 検証
3. `odeEventSet.m:210-284` または `:309-386` 区間ごとの反映
4. `odeSimulator.m:422-486`, `:488-635` 右辺とヤコビアン(`ctx.Ymat` の区間別化が必要)
5. `odeSimulator.m:639-697` 次区間の初期値
6. `odeEventSet.m:388-430` 結果(`rm_I` は固定の `Ymat` で計算)
7. `odeSimulator.m:216-217` は Trip 専用の分岐例

**新しいソルバー**

- `ode` の `SolverID` にあるものは Name-Value で渡す想定だが、§3.5 により `SolverOptions` の併記が必須。
- `ode` 以外のソルバー(IDA など)を足すには `solve` のループとフォールバック(`:248,265`)に手を入れる必要があり、抽象化はない。

**新しいモデル**: `sv_x, sv_u, fcn_*`、ヤコビアンは任意(`Component.m:173-189`)。

**解列からの復帰**は `component.generator.abstract` 限定(`odeSimulator.m:652`)。同梱の負荷は状態を持たない(`load/@power/power.m:43`, `load/@impedance/impedance.m:44`)ので今は問題ないが、**状態を持つ非発電機を解列すると復帰後の質量が 0 のまま** になる(`:643`)**[事実・潜在]**。

### 6.3 `F6` のカバー範囲

**カバー済み**: 結果構造、変数表、`get_point`、`flag/output`、Name-Value の非破壊性、`TimeLimit`、v3 名、未知名、`Plot/Export`、地絡、解列(発電機、負荷、グローバル制御器)、オフセット(時刻 0・途中・解列中・1 回限り)、入力(数値、関数、順序、合算)、範囲外、複数イベント、繰り返し実行、AVR/PSS/LQR、AGC(1 台・2 台)、Hz、大系統の静止区間、ソルバー停止、`PhaseFailed`。

**未テスト**

- `Solver` が実際に切り替わること(`F6:151` は記録値のみ)
- `time` の異常形式、`[]`(`F6` は `[t0,tend]` のみ)
- `FaultBus/TripUnit/OffsetUnit/OffsetState` の誤指定、タグ重複、他系統のイベント、古いイベント
- スカラーの fault / trip / input
- フォールバック経路の設定反映、`UnfeasibleDAE`、`decic` 失敗
- 解列・地絡で終わる実行後の内部状態(`F6:626` はグローバル制御器のみ)
- 系統全体で組み立てた `getODEJacobian` の精度(`jacobian_error` はモデル単体のみ、`test_F7_linearization.m:135,149`)。解列・地絡時も含む
- LC が駆動する入力への入力イベント・AGC 出力
- 被制御機解列時のグローバル制御器(`u_connect`)
- `t0≠0` と `Progress="dialog"/"disp"` の表示(F6 は `"none"` が基本)
- `Export` の `.xlsx` と部分結果
- ローカル制御器タグの `TripUnit`

## 7. API 決定事項・コメントと実装の乖離

| # | 決定/コメント | 実装 | 根拠 |
|---|---|---|---|
| 1 | `Solver` で選べる(`simulate.m:19`、例 `odeSimulator.m:19`) | **単独指定は無効、記録だけ変わる** | `makeODE.m:12-16`、§3.5 **[実機]** |
| 2 | 解析は原則モデルを変更しない | `l_isConnect`, `l_isFault`, `rv_*offset` を書き、後片付けもない。`iv_ode*` はキャッシュとして許容範囲 | §4.1 |
| 3 | `solve` の「作業データは iv_odeX, U, Y, I」 | 上記の変数も書く | `odeSimulator.m:146-147` |
| 4 | `TimeLimit` は各区間を制限 | フォールバック区間は無制限 | §3.5 **[実機]** |
| 5 | `SolverOptions` は `Solver` と一致が必要 | 不一致でも黙って `SolverOptions` 側に合わせる | `odeSimulator.m:30-31` **[実機]** |
| 6 | 互換コードのフックは `% COMPAT(v3)` 付き 1 行 | `simulate.m:54` は準拠。`odeSimulator.m:81,108,109` は 3 行(プロパティ+アクセサ)。性質上やむを得ないが例外 | 左記 |
| 7 | fault / trip / input は `t_start` から `t_end` まで | スカラーは次の境界まで | `odeEventSet.m:29-31` **[実機]** |
| 8 | `TripUnit` は機器かグローバル制御器 | LC のタグも受理、未知タグも無視 | `odeEventSet.m:47,354` |
| 9 | `Export` は全軌道(`all trajectories`) | LC・グローバル制御器の状態がない | `odeSimulationResult.m:15-16`, `Export.m:35-49` |
| 10 | 解列機器の状態は NaN | LC の状態と u は対象外 | `odeSimulationResult.m:46`, `odeEventSet.m:409-420` |
| 11 | グローバル制御器の入力は機器の **出力** | 実装は機器の **状態** を名前で読む | `GlobalController.m:3-6,27` vs `odeSimulator.m:386` |
| 12 | グローバル制御器の V, I は `zeros(2,1)` | 実行時は `[]`。ヤコビアンの列順 `[Axx,Bxv,Bxu,Bxi]` は V, I が空のときだけ整合 | `GlobalController.m:34-36` vs `odeSimulator.m:449,514,517` |
| 13 | `time` は `[t0,tend]` | `[]` も可、3 要素以上は黙って先頭 2 個 | `simulate.m:42`, `getTimeSpan.m:13` |
| 14 | `SeparateComplexParts` の説明 | JSON の説明が `'MaxStep' option` のまま | `TimeSim.json:19` |
| 15 | `TimeLimit` の説明「超過で終了」 | 区間ごと・部分結果を返す | `TimeSim.json:34`, `odeSimulator.m:50-52` |
| 16 | JSON は `(1e-15 < tol < 1e-3)` | 実装は両端を含む | `TimeSim.json:5,10`, `odeSimulator.m:36,40` |
| 17 | 公開 Name-Value は `Solver, Tolerance, TimeLimit, Progress, Verbose, Plot, Export` | **準拠** | `odeSimulator.m:68-77` |
| 18 | `[result, flag, output]`、flag 1/0/-1、`odeSimulationResult` | **準拠**(`F6:124-135`) | `simulate.m:1`, `odeSimulator.m:300-314` |
| 19 | 解析の入口 `net.verb_noun()`、互換は `_VersionSupport/` | **準拠** | `simulate.m:1,54` |
| 20 | ソルバーは設定のみ保持 | **準拠** | `odeSimulator.m:6-7`, `F6:141` |

**使われていないコード [事実]**

- `checkSimulationTime.m`(呼び出しなし)
- `odeEventSet` の `mustBeVector.m`(呼び出しなし)
- `getSubJacobian`(`odeSimulator.m:736-752`。呼び出しはコメントアウトされたものだけ)
- `odeIteration`(`odeEventSet.m:65,287`)、`Bus.iv_odeU`(`Bus.m:59`)、`Component.iv_odeY`(`Component.m:95`)
- `RM` 引数(`odeSimulator.m:422,488,639`)
- `odeProgress.Events` の第 2・3 出力(`odeProgress.m:158-163`)

## 8. 非効率に見える箇所(実測は `simulate-review-measurements.md`)

### 8.1 密行列(系統規模に効く)

- `Ymat` と `absYmat` は密(`complex2matrix.m` の `zeros`、`odeSimulator.m:184,186`)。右辺 1 回に O(n_bus²) の積が 2 回(`:430-431`)。
- `EM`, `RM` は `eye` からの密行列(`odeEventSet.m:358-362`)で、右辺・ヤコビアンの冒頭で毎回 `EM*x`(`odeSimulator.m:425,491`)。O(n²) で実質は添字代入で足りる。
- ヤコビアンは密の `zeros(n,n)` を毎回組み立て(`:495`)、`odeJac(lg,lg)` で切り出す(`:633`)。実際は疎だが **`ode15s` の LU は O(n³)** と見込まれる **[推測]**。
- 質量行列も密(`odeEventSet.m:382`、`odeSimulator.m:643`)。

### 8.2 右辺の中(評価回数に効く)

- **文字列 `ismember` を毎回実行**(`Comp/gda.m:29`, `LC/gda.m:27`)。結果は実行中不変なのでキャッシュできる。
- **`rv_Uoffset(t)` が機器ごとに `cellfun`+クロージャ**(`odeSimulator.m:466`、`odeEventSet.m:282`)。入力イベントがなくても実行する。
- `dcellfun` で `blkdiag` を毎回作る(`odeSimulator.m:447`)。
- `f_*` は `obj` を捕まえた無名関数でメソッド呼び出しになる(`Component.m:191-194`)。
- 解列中の機器も `f_dx`, `f_Y`, `f_I` を x=0 で評価して捨てる(`Comp/gda.m:25,33-34`)。
- 母線ループで `a_bus{i}.a_Component` などのプロパティアクセスが多い(`odeSimulator.m:453-482`)。

### 8.3 区間単位

- `getInitialCondition` が毎区間 `getXM` で全機器の平衡値・質量を作って捨てる(`odeEventSet.m:331-342`)。`c_Iequilibrium` の和も計算する(`:335`)。
- `setEventCondition` が毎区間 全機器×全イベント(`:238-283`)。
- `NoAction` イベントの生成ごとに系統を走査(`:102-116,200`)。
- 区間ごとにソルバーを再始動し刻み幅をリセット。無イベントの分割でも同じ(`odeSimulator.m:248`、`F6:381-387`)。

### 8.4 結果生成

- 行列 → `table` → 行列の往復(`odeEventSet.m:425-429`, `odeSimulationResult.m:118-120`)。
- `get_variable_map` を 2 回(`odeSimulationResult.m:122,307`)。
- `build_view` は全列を `array2table` 化して `sct_view` に保持(`:225-226`)。`rm_variable` と二重にメモリを使う。
- ソルバーの全ステップを保存し、出力間引きの手段がない(`odeSimulator.m:248,280`)。

## 9. 気づいた問題点

重要度: **高** = 利用者が気づかず誤った結果を得る / **中** = 誤用時の情報不足や将来の障害 / **低** = 整理事項。

### 高

| # | 問題 | 根拠 | 方向性 |
|---|---|---|---|
| H1 | **`Solver` 単独指定が黙って無視され、`result.options` には指定どおり記録される** | §3.5 **[実機]** | 既定の `SolverOptions` を `Solver` から決め、不一致はエラーにする |
| H2 | **フォールバック経路(解列の開始区間など)で `Solver`, `SolverOptions`, `TimeLimit`, 解析ヤコビアン, 進捗がすべて無視される** | §3.5 **[実機]** | `decic` の結果を `o.InitialValue` に入れて同じ `ode` オブジェクトで解き直す |
| H3 | **`FaultBus/TripUnit/OffsetUnit/OffsetState` の誤記が無外乱の成功結果になる** | §2.4 **[実機]** | `validate_input` を全種類へ拡張する |
| H4 | **LC が駆動する入力へのイベントとグローバル制御器の出力が黙って上書きされる** | §3.4 **[実機]**、`Comp/gda.m:30` | 加算する仕様か、検出してエラーかを決める |
| H5 | **既定 `TimeLimit=10` 秒で停止しても無通知で部分解を返す** | §5.3 **[実機]** | `flag≠1` で警告を出す。既定値の見直し |

### 中

| # | 問題 | 根拠 | 方向性 |
|---|---|---|---|
| M1 | スカラーの fault / trip / input が次の境界まで続く | §2.3 **[実機]** | スカラーは offset 専用にしてエラー化 |
| M2 | `time=[0,2,4]` が黙って `[0,2]`、他の不正形式は MATLAB 生エラー | §1.3 **[実機]** | `simulate` の入口で形式を検証 |
| M3 | イベントが生成時の系統情報を抱え、古いイベント・他系統のイベントが生エラーになる | §2.4 **[実機]** | タグ情報を実行時に作り、`odeNetwork==net` を検査 |
| M4 | イベントのタグ重複がエラーで、同じタグの再利用ができない | §2.2 **[実機]** | 重複を検出して明示エラー、または内部名を分離 |
| M5 | 解列時に右辺とヤコビアンが不一致 | §3.6 | `l_isConnect` とマスクをヤコビアンにも適用 |
| M6 | 機器の `l_isConnect`、母線の `l_isFault`、オフセットが実行後も残る(「モデルを変更しない」原則に反する) | §4.1 **[実機]** | `onCleanup` で全部復元、または `ctx` へ移す |
| M7 | 区間内の例外で完了済み区間を失う | §5.4 | `flag=-1` の部分結果に統一するか、例外に部分結果を添える |
| M8 | `Export` の拡張子エラーが計算後で、結果を失う | §5.2 **[実機]** | 計算前に検査 |
| M9 | `Export` に LC・グローバル制御器の状態がない | §5.2 | `rm_variable` を基に書き出す |
| M10 | 密行列の `EM/RM/Y/J/M` | §8.1 | 実測のうえ疎行列・添字代入へ(性能課題の本命) |
| M11 | 右辺内の `ismember`, `cellfun` | §8.2 | 区間開始時に前計算 |
| M12 | `decic` の失敗が無視され、微分状態も黙って動く | §3.5 | `exitFlag` の確認と、緩和時の通知 |
| M13 | グローバル制御器の入力の説明(出力)と実装(状態)が違い、スカラー前提 | §7 #11, §4.3 | 仕様を決めて統一 |
| M14 | ブランチ開放イベントがなく `Ymat` が固定 | §2.1 | 区間別 `Ymat` の設計(機能追加) |

### 低

| # | 問題 | 根拠 | 方向性 |
|---|---|---|---|
| L1 | モデルに渡る `t` は区間内時刻。同梱の `fcn_*` は `t` を使わないので今は無害(grep)、時変モデルを作ると誤る | `odeSimulator.m:248,449`、`Comp/gda.m:33` | `InitialTime=t1` で解く |
| L2 | 解列からの復帰が発電機限定で、状態を持つ他の機器は質量 0 になる(潜在) | §6.2 | 全機器を同じ処理に |
| L3 | 解列発電機の LC が動き続け、毎区間リセットされる | `Comp/gda.m:25-28`, `odeSimulator.m:657-672` | LC も解列扱いにするか仕様化 |
| L4 | 使われていないコード | §7 末尾 | 削除 |
| L5 | JSON の説明の誤りと末尾カンマ | §7 #14-16 | 修正 |
| L6 | `t0≠0` の待機バーの進捗率 | §5.3 | `t-tlim(1)` に修正 |
| L7 | `get_options` の二重処理、`take_call_options` の 3 重複、値が正規化されない | §1.2 | 共通化 |
| L8 | `odeSimulator` のネスト 2 段固定と再帰実装の混在 | §4.3 | どちらかに統一 |
| L9 | `F6` の未テスト領域 | §6.3 | H1〜H5 と同時にテスト追加 |
