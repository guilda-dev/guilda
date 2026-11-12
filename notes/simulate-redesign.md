# `simulate` と `SolverODE` の再設計(仕様)

ブランチは `docs/simulate-redesign-spec` です。調査の基準コミットは `9940b9d6` で、2026-11-12 の利用者の回答(§0.2)を反映した版の基準は `78cd96a1`(`refactor/design-alignment`)です。**この文書は仕様で、コードは変えていません。** §7 の手順でサブセッションに分けて実装します。

**根拠の区別**

- **[事実]** 基準コミットのコードを読んで確認しました(行番号は `9940b9d6` のもの。`78cd96a1` でもこれらのファイルは変わっていません)。
- **[決定]** 利用者が 2026-11-12 に決めた方針と、§9 の問いへの回答です(§0)。
- **[提案]** この文書の提案で、決定の具体化です。
- **[要確認]** 利用者の確認を待つ提案です(§9.2)。
- **[未確認]** 調べていない、または MATLAB で動かしていない事項です。この文書のために MATLAB は実行していません。

**関連ノート:** [simulate-improvements.md](simulate-improvements.md)(以前の改善案)、[variable-connection-map.md](variable-connection-map.md)(DAE の変数の並びと接続表)、[controller-signal-routing.md](controller-signal-routing.md)(GC の観測と出力)、[v4-migration.md](v4-migration.md) §1.11, §1.18、[structural-checks.md](structural-checks.md)(削除した構造の検査)。潮流計算の同じ方針の作業は `refactor/powerflow-structure` の `notes/powerflow-structure.md`(未統合)です。

## 0. 利用者の決定

### 0.1 方針(2026-11-12)

1. **1 回の実行に 1 つのシナリオ。** シナリオは 1 回のシミュレーションのすべて(時間、外乱、説明、判定)を持ちます。呼び出しはタグで 1 つだけ選びます: `net.simulate("case1", Name=Value)`。外乱のない実行も、時間だけを持つシナリオを使います。
2. **シナリオは `net.add_scenario(tag, ...)` で作り、そのシナリオを返します。** `simulate` のタブ補完はシナリオのタグを並べ、arguments ブロックがタグを検査します。
3. **`Scenario` は `LayerPackage` にし、`PowerNetwork` の子にします。** stale のタグはなく、編集は `log_edit` を呼びません。`tab_parameter` は空の表です。タグは系統の子と同じ名前空間です。
4. **設定は `GUILDA.setting`(TimeSimulation)が既定で、呼び出しの Name-Value がその呼び出しだけ上書きします。** `Scenario.Options` は削除します。arguments ブロックだけで受け、既定値を書かないことで「呼び出しで与えたか」を判別します。
5. **v3 互換の削除。** `v3_simulate_args`、`_VersionSupport/ODEevent.m`、`Scenario.l_compat` を削除します。他の `_VersionSupport` のファイルは触りません。
6. **`SolverODE` は系統ではなくデータを受け取ります。** モデルの作業(stale の検査、GC の検査、タグから位置への変換、データの収集)は `simulate` 側が行います。
7. **出力は `Format` で選びます。** `"GUILDAorigin"`(既定)は `ResultODE`、`"struct"` は struct です。

### 0.2 §9 の問いへの回答(2026-11-12)

| # | 回答 | 反映した節 |
|---|---|---|
| Q1 | 呼び出しの `Time=[t0 tend]` で時間を上書きできる。既定値のない Name-Value 1 つで、ないときはシナリオの `Time` | §2.1, §3.4, §8 |
| Q2 | シナリオの `Time` の既定は `[0, 10]`。外乱の時間幅から決める規則は廃止 | §2.2, §2.4, §3.4, §6, §8 |
| Q3 | `add_scenario` のタグが系統の子と重なったら、`set.s_tag` と同じ規則で番号を足して改名し、新しいタグを INFO で示す。エラーにしない | §2.2, §6.3, §8 |
| Q4 | `remove_scenario` はシナリオを削除する | §2.3 |
| Q5 | `add_scenario(tag, From=sc)`。`sc.copy()` は削除 | §2.2, §6 |
| Q6 | `SolverOptions` は**残す**(将来、Y 法を手本にした固定刻みの自作ソルバーを加える可能性がある)。`MaxStep` と `InitialStep` も設定に加え、呼び出しで上書きできるようにする | §2.1, §2.7, §3.1 |
| Q7 | `Progress` の true/false は残す | §2.1 |
| Q8 | `ResultODE` は `sct_network` のスナップショットを持つ | §5.2 |
| Q9 | `Format="struct"` はクラスごとに分けた struct で、各物体の応答は変数名を列名とする table。形は §5.3 の案で、**利用者の確認待ち** | §5.3, §9.2 |
| Q10 | `simulate` 側が `f_reconnect` を作って渡す | §3.2 |
| Q11 | Hidden の `PowerNetwork.build_simulation_data` を加える | §2.1, §7, §8 |
| Q12 | `gui` を `LayerPackage` に移す | §2.5 |
| Q13 | シナリオは系統と一緒に管理する。`PowerNetwork.import_csv` の読むフォルダに `scenario/` があれば、シナリオを `<タグ>.json` で読み、`export_csv` も書く。単独のシナリオの読み込み(`Scenario.import_csv`)はなくす | §1.7, §2.8, §6, §7, §8 |
| Q14 | `simulate` の `Export` オプションは削除。利用者は `result.export(...)` を呼ぶ。`ResultODE.Export` は `export` に改名(潮流計算の作業も同じ変更をする) | §1.6, §2.1, §5.4, §6, §7 |

## 1. 現状の構造: `SolverODE` が系統を読む箇所

### 1.1 呼び出しの流れ [事実]

`_GUILDAsystem/@PowerNetwork/simulate.m`

| 行 | 処理 |
|---|---|
| 77-81 | `time` の位置のシナリオを受け付け、`check_time` |
| 82 | `split_events`: 先頭の `Scenario` 引数と Name-Value を分ける |
| 83 | `v3_simulate_args`(`% COMPAT(v3)`) |
| 84 | `scenario_settings`: `sc.Time` と `sc.Options` を取り込む(132-171) |
| 85-86 | `take_call_options` で `Export` を分け、`check_export` |
| 87 | `obj.solver_ODE.get_options(c_nv)` → `tools.resolve_options`(`@SolverODE/get_options.m:18`) |
| 89 | `obj.solver_ODE.solve(obj, time, c_events, sct_options)` |
| 95-99 | `result.Export(...)` |

### 1.2 `SolverODE` が系統とモデルを読む箇所 [事実]

パスは `_GUILDAsystem/_auxiliary/@SolverODE/` からの相対です。

| ファイル:行 | 読むもの | 新しい置き場所 |
|---|---|---|
| `solve.m:34` | `Scenario.compile(c_events, net, time)` | `build_simulation_data`(§3.4) |
| `solve.m:35` | `check_islands(net, ...)` | `build_simulation_data`(§4.4) |
| `solve.m:36` | `build_index(net)` | 前半(モデルの収集)は `build_simulation_data`、後半(位置の計算)は `SolverODE` |
| `solve.m:37` | `ctx.net = net`(`set_admittance`、`getNextPhase` が読む) | 削除 |
| `solve.m:39` | `net.get_admittance_matrix` | `cm_Y` として渡す |
| `solve.m:231` | `ResultODE(net, obj, ...)` | `simulate` が作る(§5) |
| `solve.m:238-249` (`set_phase`) | `ph.sv_trip`, `ph.sv_fault` のタグを `ctx.sv_comp` などと照合 | 位置で受け取る(§3.4) |
| `build_index.m:19, 164-192` (`check_network`) | `net.sct_stale`, 各機器・制御器の `sct_stale` | `build_simulation_data` |
| `build_index.m:21` | `net.get_variable_map()` | 表として渡す |
| `build_index.m:22-23, 67, 84` | `net.a_Bus`, `net.a_GlobalController`, `a_Component`, `a_LocalController` | `build_simulation_data` |
| `build_index.m:62-63` | `b.c_Vequilibrium`, `b.c_Iequilibrium` | 平衡点として渡す |
| `build_index.m:77-79, 89-91, 106-109` | `f_*` のハンドル、`st.comp = comp`, `sl.con`, `sg.gc`(物体そのもの) | ハンドルだけ渡す。物体は渡さない |
| `build_index.m:80-81, 92-93, 110-111` | `rv_Xequilibrium`, `rv_Uequilibrium` | 平衡点として渡す |
| `build_index.m:82, 94, 112` | `tools.read_mass(comp)` | `SolverODE` が `f_Mass` を評価 |
| `build_index.m:115-124` | `gc.sv_y`, `gc.controlledUnits`(`GconNoTarget`) | `build_simulation_data` |
| `build_index.m:148-151` | `string(a_gc)` で GC の入力の行を探す | 行番号で受け取る |
| `set_admittance.m:18-22` | `ctx.net.a_Branch`, `ctx.net.a_Bus`, `a_br{k}.a_Bus`, `a_br{k}.get_admittance_matrix()` | 枝ごとの母線の位置と 2×2 の行列を受け取る |
| `getNextPhase.m:25-26` | `isa(b.comp, 'component.generator.abstract')`, `b.comp.get_equilibrium(V,0,0,0)` | 再接続のハンドル `f_reconnect`(§3.2) |
| `getNextPhase.m:38` | `ctx.net.a_Bus`(個数だけ) | 母線数はデータから |
| `initial_condition.m:20` | `ctx.sv_owner` と `ph.sv_trip`, `ph.sv_fault` のタグ照合 | 位置で受け取る |
| `initial_condition.m:33-40` | `ph.c_Xoffset`, `ph.c_Uoffset`(機器の順のセル) | 第 1 区間は初期値に含める。第 2 区間以降は位置と値 |
| `phase_result.m:15-21` | `b.s_tag` と `ph.sv_trip` の照合 | 位置で受け取る |
| `private/check_islands.m:5-11` | `net.a_Bus`, `net.a_Branch`, `a_Branch{k}.a_Bus`, `b.a_Component` | `build_simulation_data` |

`getODEFunction.m` と `getODEJacobian.m` は `ctx` だけを読みます。ただし `ctx.c_comp{j}.f_dx` などは `set_odefcn` が作るクロージャ(`@(t,x,V,u) obj.fcn_dx(t,x,V,u,array,omega0)`、`_GUILDAsystem/@Component/set_odefcn.m:36-39`)で、パラメータ `array` を値で束縛しています。決定 6(a) の「`set_odefcn` のクロージャ」はこれです。`private/makeODE.m` と `private/CalculateInitialCondition.m` は設定と `ode` オブジェクトだけを読みます。

### 1.3 `Scenario.compile` が系統を読む箇所 [事実]

`_GUILDAsystem/_auxiliary/@Scenario/compile.m`

| 行 | 読むもの |
|---|---|
| 38-48 | `sc.a_PowerNetwork ~= net`(`OtherNetwork`)、`sc.validate(net)` |
| 69-78, 98-110 | 時間が空のときの規則(外乱の時間幅から決める。`private/getTimeSpan.m`) |
| 152-153 | `net.a_Bus` の `a_Component`(機器の順) |
| 195-200, 208-211 | `comp.s_tag`, `comp.sv_x`, `comp.sv_u`(オフセットと入力の対応) |

`compile` の出力 `sct_phase(k)` は、外乱をタグ(`sv_fault`, `sv_trip`, `sv_open`)と機器の順のセル(`c_Xoffset`, `c_Uoffset`)で持ちます。

### 1.4 `ResultODE` が系統を読む箇所 [事実]

| ファイル:行 | 読むもの |
|---|---|
| `@ResultODE/ResultODE.m:88` | `ResultBase(net, ...)`: `a_PowerNetwork` に系統の参照を保持(`@ResultBase/ResultBase.m:61-63`) |
| `@ResultODE/ResultODE.m:93-95` | `net.a_Bus`, 各母線の `a_Component`(`sv_bus`, `c_component`) |
| `@ResultODE/ResultODE.m:97-99` | `net.get_variable_map()`、`simulator_columns(net, ...)` |
| `@ResultODE/private/simulator_columns.m:5-7, 15` | `net.a_Bus`, `net.get_variable_map()` の `c_idxBus`, `a_Component` |
| `@Scenario/out_of_step.m:51-53, 61-71` | `result.a_PowerNetwork` からスラック母線(`l_isSlack`)と機器の慣性 `M`(`tab_parameter.dynamics.M`) |

`Plot`、`get_point`、`Export`、`build_view`、`columns_of` は結果のデータだけを読みます。**系統の参照が必要なのは `out_of_step` の `Reference="slack"` と `"COI"` だけです。** `SolverLIN` の `Point={sim, t}` は `sim.get_point` だけを呼びます(`@SolverLIN/point_vector.m:43-52`)。

### 1.5 GC の他系統の機器の検査 [事実]

決定 6 の「GC の他系統の機器の検査」(`GUILDA:SolverODE:ForeignControlledUnit`)は、Issue #119 の構造の検査の整理で**削除済み**です([structural-checks.md](structural-checks.md) の「削除した検査」)。`GlobalController` のコンストラクタが制御対象を確かめ、制御対象は制御器がある間は削除も置換もできないためです。`build_index` に残る GC の検査は `GconNoTarget`(出力の行き先がない。追加の後にローカル制御器を外すと起きえる)だけで、これを `build_simulation_data` に移します。

### 1.6 `Export` の置き場所 [事実]

`Export` は `ResultBase` の約束です。`@ResultBase/ResultBase.m:85` が `varargout = Export(obj, varargin)` を宣言し、既定の `@ResultBase/Export.m` は `error_unsupported("Export")`(`GUILDA:ResultBase:Unsupported`)で止まります。`ResultPF`, `ResultOPF`, `ResultCPF`, `ResultODE` がそれぞれ `Export.m` で上書きし、`calculate_powerflow`, `optimize_powerflow`, `calculate_continuation_powerflow`, `simulate` が `Export` オプションから呼びます。共有の補助関数はありません。**したがって `ResultODE.Export` だけを `export` に改名すると、継承した `Export`(エラー)と `export` の両方が残ります。** 改名は `ResultBase` と全結果クラスで揃える必要があります(§5.4、§7 の注意)。

### 1.7 系統のフォルダとシナリオの CSV [事実]

- `PowerNetwork.export_csv(path)` は `<path>/network/parameter.csv`、`bus/parameter.csv`、`branch/parameter.csv`、`component/<key>/main.csv`・`dynamics.csv`・`opf.csv` を書き、`Overwrite=true` ではこの 4 つのサブフォルダとクラスファイルを消してから書きます(`@PowerNetwork/export_csv.m:53-90`)。制御器は書かず `ControllersNotSaved` を警告します。
- `PowerNetwork.import_csv(path, Network=, Initialize=)` は同じ配置を読み、母線・ブランチ・機器を作ってから `initialize` します(`@PowerNetwork/import_csv.m`)。同梱の系統クラスはコンストラクタでこれを呼びます。
- シナリオは `Scenario.import_csv` / `export_csv` が 1 つの CSV に複数のシナリオを 1 行 1 外乱で読み書きします。これを使うのは `test_F31_scenario` と `_GUILDAverification` の IEEJ の比較スクリプト 3 つ(`table4_3_scenarios.csv`, `table4_5_scenarios.csv`, `table4_9_scenarios.csv` を `Scenario.import_csv(..., Network=net)` で読む。例 `IEEJ_EAST10/compare_table4_3.m:67`)です。

## 2. 新しい公開 API

### 2.1 `PowerNetwork.simulate`

```matlab
function [result, flag, output] = simulate(obj, s_scenario, opt)
    arguments (Input)
        obj
        s_scenario (1,1) string {mustBeScenarioOf(obj, s_scenario)}   % Tag of the scenario to run (net.add_scenario).
        opt.Time (1,2) double {mustBeSimulationTime}   % [s] Simulation time [t0, tend] of this call. Default: the Time of the scenario.
        opt.Solver (1,1) string {mustBeMember(opt.Solver, ["ode15s","ode23t"])}   % Solver of the MATLAB ode object. Default: GUILDA.setting.
        opt.SolverOptions (1,1) matlab.ode.Options   % Options of the solver (e.g. MaxOrder); its class must match Solver. Default: the options of the Solver.
        opt.Tolerance (1,1) double {mustBeInRange(opt.Tolerance, 1e-15, 1e-3)}   % Relative error tolerance. Default: GUILDA.setting.
        opt.AbsoluteTolerance (1,1) double {mustBeInRange(opt.AbsoluteTolerance, 1e-15, 1e-3)}   % Absolute error tolerance. Default: GUILDA.setting.
        opt.MaxStep (1,1) double {mustBePositiveOrNaN}   % [s] Largest step of the solver; NaN for the solver default. Default: GUILDA.setting.
        opt.InitialStep (1,1) double {mustBePositiveOrNaN}   % [s] First step of each phase; NaN for the solver default. Default: GUILDA.setting.
        opt.SeparateComplexParts (1,1) logical   % SeparateComplexParts of the ode object. Default: GUILDA.setting.
        opt.TimeLimit (1,1) double {mustBePositive}   % [s] Wall-clock limit of the whole run; Inf for none. Default: GUILDA.setting.
        opt.Progress {mustBeProgress}   % "dialog", "disp" or "none" (true: "dialog", false: "none"). Default: GUILDA.setting.
        opt.Verbose (1,1) logical   % Print the phases and the outcome. Default: GUILDA.setting.
        opt.PlotFcn {mustBePlotFcn}   % Live display during the run: "none". Default: GUILDA.setting.
        opt.Format (1,1) string {mustBeMember(opt.Format, ["GUILDAorigin","struct"])} = "GUILDAorigin"   % Form of the first output.
    end
    arguments (Output)
        result   % ResultODE (Format "GUILDAorigin") or a struct of tables per bus, component and controller (Format "struct").
        flag     % 1 completed, 0 stopped by TimeLimit, -1 stopped by the solver.
        output   % Details: message, tEnd, phases, nPhases, nPhasesDone, isSparse, exception.
    end
```

- **既定値を書かない [決定 4]。** `Time` と設定の名前の引数には既定値を書かないので、呼び出しで与えなかった名前は `opt` のフィールドになりません。`Format` は設定ではないので既定値を書きます。
- **時間 [決定 Q1]:** `time = sc.Time`、`isfield(opt, "Time")` なら `opt.Time`。`sc.Time` は変えません。追加は arguments の 1 行と、この 2 行です。
- **設定の合成 [提案]:**

  ```matlab
  sct_options = struct();
  sct_cfg = GUILDA.config("TimeSimulation");
  for s_name = string(fieldnames(sct_cfg)).'
      sct_options.(s_name) = sct_cfg.(s_name).Value;
  end
  if isfield(opt, "SolverOptions")       % the call's object keeps its own step sizes
      sct_options.MaxStep = NaN;
      sct_options.InitialStep = NaN;
  end
  for s_name = setdiff(string(fieldnames(opt)).', ["Time","Format"])
      sct_options.(s_name) = opt.(s_name);      % this call only
  end
  sct_options.Progress = progress_mode(sct_options.Progress);   % true/false -> "dialog"/"none"
  check_solver_options(sct_options);          % SolverOptions must match Solver (today validate_options)
  ```

  `TimeLimit` の設定値が正でないときは `Inf` にします(現行 `get_options.m:38-40` と同じ)。設定ファイルの値は `GUILDA.setting` の検査(type、options)に任せます。
- **`SolverOptions` と `MaxStep`, `InitialStep` の優先順位 [提案]:** 呼び出しの `MaxStep` / `InitialStep` > 呼び出しの `SolverOptions` の値 > `GUILDA.setting` の `MaxStep` / `InitialStep` > ソルバーの既定。呼び出しで `SolverOptions` を渡したときは、設定ファイルの `MaxStep` / `InitialStep` を当てません(利用者が渡したオブジェクトの値を設定ファイルが黙って変えないため)。`SolverOptions` のクラスが `Solver` と合わないときは現行どおり止まります(`@SolverODE/private/validate_options.m` の検査を `simulate` へ移す)。
- **将来の固定刻みソルバー [決定 Q6 の背景]:** Y 法を手本にした自作ソルバーを加えるときは、`Solver` の選択肢を増やし、`SolverODE.solve` の中で `ode` オブジェクトの代わりにそのソルバーを使います。`sct_dae` などのデータの約束(§3)は MATLAB の `ode` に依存しないように作るので、モデル側の変更は要りません。そのソルバーの設定を `SolverOptions` で渡すかどうかは、そのときに決めます(`opt.SolverOptions` の型を `matlab.ode.Options` から広げる)。
- **検証関数の置き場所 [提案]:** `mustBeScenarioOf`、`mustBePositiveOrNaN`、`mustBeProgress`、`mustBePlotFcn` は `@PowerNetwork/private/` に置きます。`mustBeSimulationTime` は今 `@Scenario/private/` にあり、`PowerNetwork` からは呼べないので、`_GUILDAsystem/_auxiliary/SystemTools/` 直下へ移して両方から使います。`mustBePlotFcn` は `refactor/powerflow-structure` の `calculate_powerflow` も使う名前なので、統合の順で重複しないよう、後から入る側が既存のものを使います(§7 の注意)。
- **`mustBeScenarioOf` のエラー [提案]:** `GUILDA:PowerNetwork:ScenarioNotFound`(既存のキー)。本文に系統のシナリオのタグを最大 10 個並べ、`net.add_scenario` を案内します。シナリオがない系統では「`net.add_scenario("name")` で作る(`Time` の既定は `[0, 10]`)」と案内します。
- **`output` の内容**は現行と同じです(`message`, `tEnd`, `phases`, `nPhases`, `nPhasesDone`, `isSparse`, `exception`)。`output.phases` の列名は外乱のタグです。
- **警告:** `flag ~= 1` のとき `GUILDA:PowerNetwork:SimulationIncomplete` を出すのは現行と同じです。
- **`Export` オプションは削除 [決定 Q14]。** 書き出しは `result.export(...)` です(§5.4)。

**`simulate` の処理順 [提案]**

1. `sc = obj.a_Scenario{...}`(タグで選ぶ)。`time` を決める。
2. 設定を合成する。
3. `[sct_dae, sct_event, rv_x0, tab_phase] = obj.build_simulation_data(s_scenario, time)`(Hidden、下記)。
4. `[sct_sol, flag, output] = obj.solver_ODE.solve(sct_dae, sct_event, rv_x0, sct_options)`。`output.phases = tab_phase`。
5. `Format` に応じて返す(§5)。

**`PowerNetwork.build_simulation_data` [決定 Q11]**

```matlab
function [sct_dae, sct_event, rv_x0, tab_phase] = build_simulation_data(obj, s_scenario, time)
% (Hidden) Data of one run of simulate for SolverODE.solve: for tests and debugging.
    arguments (Input)
        obj
        s_scenario (1,1) string {mustBeScenarioOf(obj, s_scenario)}   % Tag of the scenario.
        time (1,2) double {mustBeSimulationTime}   % [s] Simulation time [t0, tend].
    end
    arguments (Output)
        sct_dae   (1,1) struct   % Section 3.2.
        sct_event (:,1) struct   % Section 3.4.
        rv_x0     (:,1) double   % Section 3.5.
        tab_phase table          % output.phases.
    end
```

`methods (Hidden)` に置きます。処理は (1) stale と入力の編集の検査(現行 `build_index.m:164-192` の `check_network` を移す。エラー ID は §6.3)、(2) `get_variable_map`、(3) ブロックの収集と `GconNoTarget`、(4) `sc.compile(sct_dae, time)`、(5) 島の検査(§4.4)、(6) 初期値、です。`time` を必須にするのは、`simulate` と同じ時間の決め方をここに重ねないためです(テストは `sc.Time` を渡す)。

### 2.2 `PowerNetwork.add_scenario`

```matlab
function sc = add_scenario(obj, s_tag, opt)
    arguments (Input)
        obj
        s_tag (1,1) string {mustBeNonzeroLengthText}   % Tag of the new scenario; a number is added when a child of the network has it.
        opt.Time (1,2) double {mustBeSimulationTime}   % [s] Simulation time [t0, tend]. Default: From.Time, else [0, 10].
        opt.Description (1,1) string   % Free text. Default: From.Description, else "".
        opt.Judge (1,1) function_handle   % verdict = Judge(result). Default: From.Judge, else @Scenario.out_of_step.
        opt.From Scenario {mustBeScalarOrEmpty}   % Scenario to copy the disturbances and settings from (of this or another network).
    end
    arguments (Output)
        sc Scenario   % The new scenario, a child of the network.
    end
```

- **タグの重なり [決定 Q3]:** タグが系統の子(母線、ブランチ、GC、シナリオ、`Parameter` の `base`)と重なると、`LayerPackage.set.s_tag`(`@LayerPackage/LayerPackage.m:88-106`)と同じ規則で番号を足して改名し、そのメッセージ(`Info : Tag changed due to overlaps detected[ "case1" >> "case1002"]`)を表示します。[事実] この規則の最初の番号は `002` です(`id = 2` から `%.3d`)。エラーにはしません。利用者は戻り値の `sc.s_tag` で新しいタグを知ります。実装は、`Scenario` のコンストラクタで親 `a_PowerNetwork` を先に設定してから `s_tag` を代入すれば、`set.s_tag` がそのまま改名します(コンストラクタでの最初の代入は改名の `log_edit` を呼びません。`LayerPackage.m:109-112`)。
- `From` の外乱は、この系統に対して `validate` します(失敗すると何も作りません)。`From` は変わりません。**移動**は `net2.add_scenario(tag, From=sc)` と `net1.remove_scenario(tag)` の 2 つの呼び出しです [決定 Q5]。
- 平衡点は古くならず、`log_edit` も呼びません。
- 現行の `add_scenario(sc)`(物体またはセルを受ける)はなくなります。

### 2.3 `PowerNetwork.remove_scenario`

```matlab
function remove_scenario(obj, sr_tag)
    arguments (Input)
        obj
        sr_tag (1,:) string   % Tags of the scenarios to remove.
    end
```

- 存在しないタグは `GUILDA:PowerNetwork:ScenarioNotFound`(現行どおり、何も外さない)。
- 外したシナリオは `delete` します [決定 Q4]。Issue #119 の「外した物体は削除する」と同じで、`Scenario.a_PowerNetwork` は常に空でなくなります。外したシナリオを持つ変数は無効なハンドル(`isvalid` が false)になります。

### 2.4 `Scenario`

```matlab
classdef (Sealed) Scenario < LayerPackage
    properties (SetAccess=private) % Layer Structure
        a_PowerNetwork   % Network the scenario belongs to (set by net.add_scenario; never empty). <@Type> PowerNetwork
    end
    properties (SetAccess=private) % Disturbances
        tab_disturbance table = table()   % Disturbances, one row each (n x 11). (unchanged)
    end
    properties (Access=public) % Settings
        Time (1,2) double {mustBeSimulationTime} = [0, 10]      % [s] Simulation time [t0, tend] of net.simulate.
        Judge (1,1) function_handle = @Scenario.out_of_step     % (unchanged)
        Description (1,1) string = ""                           % (unchanged)
    end
    properties (Dependent) % Parameter
        tab_parameter   % Empty table: a scenario has no parameters.
    end
    properties (Dependent, Access=protected) % Layer structure
        parent     % {a_PowerNetwork}
        children   % {} (no children)
    end
    properties (SetAccess=private, Hidden) % Version
        Ver (1,1) double = 3.0
    end

    methods (Access={?PowerNetwork})
        function obj = Scenario(net, s_tag)
        % Create an empty scenario of net (net.add_scenario).
            arguments (Input)
                net PowerNetwork      % Parent network.
                s_tag (1,1) string    % Tag (renamed with a number when a child of net has it).
            end
            arguments (Output)
                obj   % New scenario without disturbances.
            end
        end
    end
    methods (Access=protected)
        log_edit(obj, log, tag)        % No-op: editing a scenario makes nothing stale.
        sct_page = gui_content(obj)    % Pages of the model GUI: Disturbances, Settings.
    end
    methods (Access={?PowerNetwork})
        sct = to_json_struct(obj)                 % Content of <tag>.json (section 2.8).
        add_from_json_struct(obj, sct, s_file)    % Settings and disturbances from <tag>.json.
    end
    % add_fault, add_trip, add_open_branch, add_offset, add_input, add_disturbance,
    % remove_disturbance, judge, out_of_step: unchanged signatures
    % compile: new signature (section 3.4)
end
```

- **作り方は `add_scenario` だけ** [提案]。コンストラクタは `Access={?PowerNetwork}` です(#119 のモデルの物体と同じ)。`Scenario("x")` の直接の作成は `MATLAB:class:MethodRestricted` になります。
- **`Time` [決定 Q2]:** 既定は `[0, 10]` で、空は許しません。外乱の時間幅から決める規則(`compile.m:69-78`、`private/getTimeSpan.m` の時間が空の分岐)はなくします。時間の外にある外乱の警告 `GUILDA:Scenario:OutsideTimeSpan` は残します。
- **削除:** `Options`, `set.Options`, `l_compat`, `copy`, `string.m`(`LayerPackage.string` と同じ)、`import_csv`, `export_csv`(§2.8)、`validate(obj, net)` の `net` 引数。`validate` は `obj.a_PowerNetwork` に対して検査します。
- **改名:** `sc.s_tag = "new"` は `LayerPackage.set.s_tag` を通り、兄弟と重なれば番号を足します(他の層と同じ)。`log_edit` は何もしないので、`PowerNetwork.handle_edit` の `n_revOPF`(タグの編集で増える、`@PowerNetwork/handle_edit.m:66`)も増えません。
- **`LayerPackage.log_edit` の上書き [提案]:** `log_edit` は `LayerPackage` の protected メソッド(`@LayerPackage/LayerPackage.m:74`)なので、`Scenario` が同じ名前の protected メソッドを定義して上書きします。[未確認] `set.s_tag` からの呼び出しが `Scenario` 版になることは、実装時に確かめます。

### 2.5 `children` を使う箇所の扱い [提案]

`PowerNetwork.children` を `[a_Bus; a_Branch; a_GlobalController; a_Scenario; a_Parameter]` にします(`@PowerNetwork/PowerNetwork.m:213-215`)。

| 使う箇所 | 扱い |
|---|---|
| `LayerPackage.set.s_tag`(`LayerPackage.m:88-106`) | シナリオも兄弟になります。母線などのタグとシナリオのタグは同じ名前空間です [決定 3] |
| `LayerPackage.disp_tree`(`disp_tree.m:23`) | 既定の `sr_ignore = "Parameter"` のままでシナリオを表示します。行は `case1 @Scenario` |
| `LayerPackage.struct`(`struct.m`) | `a_Scenario` はこれまで `auxiliary` で `"out of target."` でした。`LayerPackage` になると再帰して `class`, `s_tag`, `a_PowerNetwork`(訪問済みのパス), `tab_disturbance`, `Time`, `Judge`, `Description`, `tab_parameter` を持ちます。関数ハンドルはそのまま入ります。`ResultPF` と `ResultODE` のスナップショット `struct(net, false)` にも入ります |
| `LayerPackage.table` | `tab_parameter`(空の表) |
| `LayerPackage.string` | `s_tag`。`Scenario/string.m` は削除 |
| `PowerSystemModel.gui`(`@PowerSystemModel/gui.m`) | `gui` を `LayerPackage` へ移し、`gui_content` の既定(空のページ)を `LayerPackage` に置きます [決定 Q12]。`f_model` が `Scenario` の protected の `parent`, `children`, `gui_content` を読めるようにするためと、カードの「Open in new window」(`build_navigation.m:32`、`UserData.gui()`)がシナリオでも動くようにするためです。`Parameter` も `gui` を持ちますが、カードに出ないので影響はありません |
| `DrawerModelGUI/render.m:76-85` | `build_parameter_tab` を `a_Parameter` を持つ物体だけで作ります(`isprop(a_target, "a_Parameter")`)。シナリオはパラメータのタブなしで、`gui_content` のページ(Disturbances: `tab_disturbance`、Settings: Time, Description, Judge)だけを表示します |
| `DrawerModelGUI/private/build_navigation.m:18` | `sv_kind` に `"Scenario"` を加え、`gui_palette.m` に色を加えます |
| `PowerNetwork.gui_content`(Summary の表) | `Item` に `"Scenario"` と個数を加えます |
| `PowerNetwork.export_csv` / `import_csv` | `scenario/` サブフォルダを読み書きします(§2.8) |
| 系統の複製 | `PowerNetwork` に複製のメソッドはありません [事実]。シナリオの複製は `add_scenario(tag, From=sc)` |
| `PowerNetwork.handle_edit` | 呼ばれません(`Scenario.log_edit` が何もしない) |
| `get_variable_map`、解析 | `a_Bus` などを直接読むので影響なし |

### 2.6 `functionSignatures.json`

`@GUILDA/update_keymap.m` の `sig_methods`(80-99 行)に次を加え、`GUILDA.update_keymap(Signature=true)` で作り直します [提案]。

```matlab
"PowerNetwork", "add_scenario",    cell(0,3)
"PowerNetwork", "remove_scenario", {"sr_tag",     "string(obj.a_Scenario)", "string"}
"PowerNetwork", "simulate",        {"s_scenario", "string(obj.a_Scenario)", "string"}
```

`build_simulation_data` は Hidden なので加えません。生成される `simulate` の項の形(`method_entry` が arguments ブロックから作る。`purpose` は省略):

```json
"PowerNetwork.simulate": {
  "inputs": [
    {"name":"obj","kind":"required","type":"PowerNetwork"},
    {"name":"s_scenario","kind":"required","type":[["string","choices=cellstr(string(obj.a_Scenario))"],["string"]]},
    {"name":"Time","kind":"namevalue","type":["double"]},
    {"name":"Solver","kind":"namevalue","type":["string","choices=cellstr([\"ode15s\",\"ode23t\"])"]},
    {"name":"SolverOptions","kind":"namevalue","type":["matlab.ode.Options"]},
    {"name":"Tolerance","kind":"namevalue","type":["double"]},
    {"name":"AbsoluteTolerance","kind":"namevalue","type":["double"]},
    {"name":"MaxStep","kind":"namevalue","type":["double"]},
    {"name":"InitialStep","kind":"namevalue","type":["double"]},
    {"name":"SeparateComplexParts","kind":"namevalue","type":["logical"]},
    {"name":"TimeLimit","kind":"namevalue","type":["double"]},
    {"name":"Progress","kind":"namevalue"},
    {"name":"Verbose","kind":"namevalue","type":["logical"]},
    {"name":"PlotFcn","kind":"namevalue"},
    {"name":"Format","kind":"namevalue","type":["string","choices=cellstr([\"GUILDAorigin\",\"struct\"])"]}
  ],
  "outputs": [{"name":"result"},{"name":"flag"},{"name":"output"}]
}
```

`remove_scenario` は `remove_branch` と同じ形、`add_scenario` は `From` の型 `Scenario` を持つ項になります。既定値のない引数は `purpose` に "Default:" が付かないので、ヘルプのコメントに "Default: GUILDA.setting." などを書きます(上の arguments ブロックのとおり)。`test_F34_signatures` の「build or remove a model」の一覧に `add_scenario`, `remove_scenario` を加えます。

### 2.7 設定(`DefaultTimeSimulation.json`)[決定 Q6、提案]

| キー | 変更 |
|---|---|
| `MaxStep` | 追加。`"Value": NaN`(ソルバーの既定)、type double、"[s] Largest step of the solver; NaN for the solver default" |
| `InitialStep` | 追加。`"Value": NaN`、type double、"[s] First step of each phase; NaN for the solver default" |
| その他(`Solver`, `Tolerance`, `AbsoluteTolerance`, `SeparateComplexParts`, `Progress`, `TimeLimit`, `Verbose`, `PlotFcn`) | 変更なし |
| `version` | 1 → 2(利用者の設定ファイルは INFO とともに既定に戻ります) |

`SolverOptions` は設定ファイルには入れず、呼び出しだけで渡します(`matlab.ode.Options` は JSON に書けないため。`Scenario.Options` がなくなるので、保存する場所は呼び出しだけになります)。`makeODE` は、`SolverOptions` があればそれを使い、`MaxStep` / `InitialStep` が NaN でなければそのフィールドに入れます(優先順位は §2.1)。どれも与えないときは何も設定しないので、数値は現行と同じです。[未確認] JSON の `NaN` の読み書き(`TimeLimit` の `Infinity` と同じく `jsondecode` が受けるか)は実装時に確かめます。

### 2.8 シナリオのファイル(`scenario/<タグ>.json`)[決定 Q13、提案]

**フォルダ:** `PowerNetwork.export_csv(path)` が書くフォルダに `scenario/` を加えます。

```
<path>/network/parameter.csv
<path>/bus/parameter.csv
<path>/branch/parameter.csv
<path>/component/<key>/main.csv, dynamics.csv, opf.csv
<path>/scenario/<scenario tag>.json      ← 追加: シナリオ 1 つに 1 ファイル
```

- `export_csv` は `net.a_Scenario` の各シナリオを `scenario/<s_tag>.json` に書きます。シナリオがなければ `scenario/` を作りません。`Overwrite=true` で消すサブフォルダに `scenario` を加えます(`export_csv.m:57`)。タグは `isvarname` なので、そのままファイル名に使えます。
- `import_csv(path, ...)` は、母線・ブランチ・機器を作った後、`initialize` の前に、`scenario/*.json` を名前の順に読み、`net.add_scenario(<ファイル名>, Time=, Description=, Judge=)` で作ってから外乱を足します。外乱の検査(タグがこの系統にあるか)は `add_disturbance` と同じです。JSON の構文と項目の検査は、ほかの表と同じく系統を変える前に行います。外乱のタグの検査は機器を作った後でないとできないので、そこで失敗すると系統は途中まで作られた状態で止まります(`import_csv` の既存の説明「A later failure ... can leave obj partly built」と同じ扱い)。
- **同梱の系統:** 同梱の系統クラスはコンストラクタで `import_csv(..., Network=obj)` を呼ぶので、そのフォルダに `scenario/` を置けば、系統を作るとシナリオも付きます。
- **順序:** シナリオの順(`a_Scenario`)はファイル名の順になり、追加した順は保存しません。
- **単独の読み込みはなくします。** `Scenario.import_csv` と `Scenario.export_csv` は削除し、読み書きは `@PowerNetwork/private/read_scenarios.m`・`write_scenarios.m`(`Scenario` の `to_json_struct` / `add_from_json_struct` を呼ぶ)にします。

**JSON の内容 [要確認]**

```json
{
  "Format": "GUILDAscenario",
  "version": 1,
  "Description": "fault B008, EL003 opened",
  "Time": [0, 20],
  "Judge": "Scenario.out_of_step",
  "Disturbances": [
    {"Tag": "fault",  "TimeSpan": [0.10, 0.17], "FaultBus": ["B008"]},
    {"Tag": "open",   "TimeSpan": [0.17, 20],   "OpenBranch": ["EL003"]},
    {"Tag": "trip",   "TimeSpan": [1, 2],       "TripUnit": ["B002SG1"]},
    {"Tag": "offset", "TimeSpan": 0,            "OffsetUnit": "B001SG1", "OffsetState": ["delta"], "OffsetValue": [0.1]},
    {"Tag": "step",   "TimeSpan": [1, 1.5],     "InputUnit": "B002SG1", "InputName": ["Pmech", "Vfield"], "InputValue": [0.05, 0.01]}
  ]
}
```

- タグはファイル名だけに持ち、JSON には書きません(2 か所で食い違わないため)。
- `Disturbances` の各要素は `add_disturbance` の Name-Value と同じ名前で、空の項目は書きません。読むときは要素ごとに `sc.add_disturbance(Tag, 項目...)` を呼びます。リストは 1 つでも配列で書き、読むときは `string(...)` で列にします(`jsonencode` の 1 要素の扱いに依らないため)。
- **`Judge`:** 名前のある関数(`func2str` が `@(` で始まらない。例 `"Scenario.out_of_step"`, `"my_judge"`)は名前だけを書き、読むときは `str2func` で戻します。項目がなければ既定(`@Scenario.out_of_step`)です。**無名関数は書かず**、`GUILDA:PowerNetwork:ScenarioJudgeNotSaved` を警告します(関数の中身と束縛した変数を保存できないため)。
- **`InputValue` の関数ハンドル:** 書けないので、現行の CSV(`GUILDA:Scenario:CsvFunctionHandle`)と同じく `GUILDA:PowerNetwork:ScenarioFunctionHandle` で止めます(書き出しの前に全シナリオを検査し、何も書かない)。
- 未知の項目は警告(`GUILDA:import_csv:UnknownScenarioField`)して無視します(CSV の未知の列と同じ)。`version` が読める値より大きければ止めます。

**`_GUILDAverification` への影響 [要確認]:** IEEJ の比較スクリプト 3 つは、1 つの CSV の多数のシナリオを `Scenario.import_csv` で読んでいます(§1.7)。単独の読み込みがなくなるので、(a) それぞれの CSV を同梱の系統のフォルダの `scenario/<tag>.json` に変換するか、(b) スクリプト内の小さな読み込み関数(`_GUILDAverification` のローカル関数で、GUILDA の API ではない)で CSV から `add_scenario` と `add_disturbance` を呼ぶか、のどちらかにします。推奨は (b) です。検証の表は 1 つの CSV のほうが比べやすく、(a) では同梱の系統を作るたびに数十のシナリオが付くためです。

## 3. `SolverODE.solve` のデータの約束

### 3.1 シグネチャ [提案]

```matlab
function [sct_sol, flag, output] = solve(obj, sct_dae, sct_event, rv_x0, sct_options)
    arguments (Input)
        obj
        sct_dae     (1,1) struct   % Blocks, maps, admittance and equilibrium of the network (section 3.2).
        sct_event   (:,1) struct   % One element per phase, disturbances as positions (section 3.4).
        rv_x0       (:,1) double   % Initial value in the order of the variable rows of tab_variable (section 3.5).
        sct_options (1,1) struct   % Settings of the run (section 2.1).
    end
    arguments (Output)
        sct_sol (1,1) struct   % Raw trajectories (section 5.1).
        flag    (1,1) double   % 1, 0, -1 (unchanged).
        output  (1,1) struct   % Details (unchanged).
    end
```

`solve` は `PowerNetwork`、`Bus`、`Branch`、`Component`、制御器、`Scenario` の物体と、その `a_*` を一切読みません。読むのは引数と、ブロックのハンドルの呼び出しだけです。`ProgressODE` と MATLAB の `ode` は使います。`sct_options` の `Solver`, `SolverOptions`, `MaxStep`, `InitialStep` から `ode` オブジェクトを作るのは `solve`(`makeODE`)で、将来の固定刻みソルバーもここで選びます(§2.1)。

**潮流計算との対応:** `refactor/powerflow-structure` の `SolverPF.solve(obj, cm_Y, tab_PFcondition, sct_options)` と同じく、系統がデータを組み立て、ソルバーは数値計算だけをします。アドミタンス行列の名前は同じ `cm_Y`(母線の順の複素行列)にします。違いは、時間応答ではブロックのハンドル、2 つの表、イベントがあるので、位置引数を増やさず `sct_dae` にまとめることです。

### 3.2 `sct_dae` [提案]

`n_bus` = 母線数、`n_br` = ブランチ数、`n_map` = `get_variable_map` の行数、`n_var` = その変数の行(Role が `"variable"`: x, Vre, Vim, u, uc)の数。行番号はすべて `tab_variable` の行番号(1 始まり)です。DAE ベクトル `z` での位置(母線電流 I を挿入した位置)は `SolverODE` が計算します。

| フィールド | 型・大きさ | 内容 |
|---|---|---|
| `tab_variable` | table, n_map × 7 | `get_variable_map()` の第 1 出力そのもの |
| `tab_connection` | table | `get_variable_map()` の第 4 出力そのもの |
| `cm_Y` | complex double, n_bus × n_bus(疎) | 全ブランチを閉じた母線アドミタンス行列(`get_admittance_matrix`、`a_Bus` の順) |
| `im_branchBus` | double, n_br × 2 | 各ブランチの両端の母線の位置(`a_Branch` の順) |
| `c_branchY` | cell, n_br × 1 | 各ブランチの 2×2 複素行列(`a_br.get_admittance_matrix()`)。開放でこれを `cm_Y(iv,iv)` から引きます |
| `rv_equilibrium` | double, n_var × 1 | 変数の行の平衡点(x, Vre, Vim, u, uc。`build_index.m:61-112` で組み立てている値) |
| `rv_Iequilibrium` | double, 2 n_bus × 1 | 母線電流の平衡点 `[Re; Im]` の並び(`c_Iequilibrium`)。現行と同じ値から始めるため(§8.3) |
| `c_comp` | cell, n_comp × 1 | 機器のブロック(下表)。`a_Bus` の順、各母線の `a_Component` の順 |
| `c_lc` | cell, n_lc × 1 | ローカル制御器のブロック。深さ優先(`get_variable_map` の順) |
| `c_gc` | cell, n_gc × 1 | グローバル制御器のブロック(`a_GlobalController` の順) |
| `sv_bus`, `sv_branch`, `sv_comp`, `sv_lc`, `sv_gc` | string 列 | メッセージと `Format="struct"` の名前に使うタグ。`SolverODE` は照合に使いません |

**ブロック(struct)**

| フィールド | 機器 | LC | GC | 内容 |
|---|---|---|---|---|
| `iv_x` | ○ | ○ | ○ | 状態の行 |
| `iv_u` | ○ (u) | ○ (uc) | ○ (uc) | 入力の行 |
| `iv_y` | ○ (y) | ○ (yc) | ○ (yc) | 出力(信号)の行 |
| `i_bus` | ○ | ○ | — | 母線の位置。LC は親の機器の母線。GC はすべての母線電圧を読む |
| `i_comp` | — | ○ | — | 付いている機器の位置(`c_comp` の番号) |
| `iv_lc` | ○ | — | — | その機器のローカル制御器(`c_lc` の番号、子孫を含む) |
| `f_dx`, `f_Y`, `f_Mass`, `f_JacobiDx`, `f_JacobiY` | ○ | ○ | ○ | `set_odefcn` が作るハンドル(パラメータを値で束縛したクロージャ)。`@obj.method` は渡しません |
| `f_I`, `f_JacobiI` | ○ | — | — | 同上 |
| `f_reconnect` | 発電機だけ | — | — | `@(V) comp.get_equilibrium(V,0,0,0)`。解列から戻るときの状態。発電機以外は `[]`(§4.1)[決定 Q10] |
| `s_tag` | ○ | ○ | ○ | メッセージ用 |

- `f_reconnect` は、戻る時刻の電圧で決まるので前もって計算できません。モデルのメソッドを呼ぶクロージャですが、1 回の実行の間はパラメータが変わらないので結果は同じです。「`@obj.method` を渡さない」の唯一の例外として、`build_simulation_data` が作ります。
- `f_Mass` は `SolverODE` が `f_Mass([],[],[],[])` で 1 回評価します。大きさが合わないか評価に失敗すると `GUILDA:SolverODE:MassNotConstant`(ブロックの `s_tag` を本文に)で止まります。現行の `tools.read_mass` と同じ検査です。
- **ソルバーが表から作るもの:** `z` の並び(`[x; V; I; u; uc]`)、`iv_V`, `iv_I`, `iv_in`, 記録する行(§5.1)、入力の右辺 `rv_e`, `S_sig`, `S_var`、GC の入力のゲート(`iv_gateIn`, `iv_gateComp`)、質量行列。これは現行 `build_index.m:26-49, 130-160` の計算そのもので、`tab.Owner` との照合は、ブロックの行番号から作る「行 → ブロック」の対応に置き換えます(GC のゲートの `ismember(tab.Owner(...), string(a_gc))`、`build_index.m:148-151`)。

### 3.3 `build_index` の分割 [提案]

| 現行 `build_index.m` | 移す先 |
|---|---|
| 19, 164-192 `check_network` | `build_simulation_data`(`@PowerNetwork/private/check_simulation.m`) |
| 21-23, 66-125 モデルを読む部分(ハンドル、平衡点、`GconNoTarget`) | `build_simulation_data`(`@PowerNetwork/private/simulation_blocks.m`) |
| 26-58, 126-160 位置と接続の行列 | `SolverODE.build_index(sct_dae)`(引数を系統からデータへ) |

### 3.4 イベントの表し方(`sct_event`)[提案]

`Scenario.compile` を次のシグネチャに変えます。区間の分け方(`phase_table`)は現行のままで、出力をタグから位置にします。

```matlab
function [tab_phase, sct_event] = compile(obj, sct_dae, time)
    arguments (Input)
        obj                  % Scenario (validated against its network).
        sct_dae (1,1) struct % Blocks and maps of the run (positions of the units, buses, branches).
        time    (1,2) double % [s] Simulation time [t0, tend] (sc.Time or the Time of the call).
    end
    arguments (Output)
        tab_phase table      % output.phases: t1, t2, one logical column per disturbance tag.
        sct_event (:,1) struct  % One element per phase (below).
    end
```

時間は必ず `[t0, tend]` で渡ります [決定 Q1, Q2]。外乱がないシナリオは `t0` に空の外乱 `NoAction` を置く現行の扱い(`compile.m:69-78`)のうち、時間が空の分岐を削ります。`private/getTimeSpan.m` の時間が空のときの規則(`[0, 30·ceil(tmax/10)]`)も削ります。

| フィールド | 型・大きさ | 内容 |
|---|---|---|
| `t1`, `t2` | double | 区間の開始と終了 [s] |
| `iv_tripComp` | double 列 | 解列中の機器(`c_comp` の番号) |
| `iv_tripGC` | double 列 | 解列中の GC(`c_gc` の番号) |
| `iv_faultBus` | double 列 | 地絡中の母線(位置) |
| `iv_openBranch` | double 列, 昇順 | 開放中のブランチ(位置) |
| `iv_offset`, `rv_offset` | double 列 ×2 | この区間の開始で状態に足す値。行は `tab_variable` の x の行。**第 1 区間は空**(初期値に含める、§3.5) |
| `c_input` | cell, k × 2 | `{iv_row, f}`: 入力の行(`tab_variable` の u の行)と、区間の開始からの時刻の関数 `f(t)`(列ベクトル)。同じ入力の複数の外乱は合計済み |
| `sr_event` | string 列 | 有効な外乱のタグ(進捗の表示用) |

- タグから位置への変換に使うのは `sct_dae.sv_bus`, `sv_branch`, `sv_comp`, `sv_gc` です。状態と入力の名前は `tab_variable` の `Owner` と `Name` で行に変えます(現行 `compile.m:194-242` の `comp.sv_x`, `comp.sv_u` の照合と同じ結果)。
- LC の解列は現行どおり不可(`UnknownTripUnit`)です。

### 3.5 初期値 `rv_x0` [決定 6(e)、提案]

`build_simulation_data` が作ります。

```
rv_x0 = sct_dae.rv_equilibrium
rv_x0(x の行)  += 第 1 区間で有効なオフセット(開始時刻にかかわらず全部。現行 compile.m:185 の Iteration == 1)
rv_x0(u の行)  += 第 1 区間の入力関数の t = 0 の値(現行 initial_condition.m:36-39)
```

母線電流 I の初期値は `sct_dae.rv_Iequilibrium` から `SolverODE` が入れます(`rv_x0` は `tab_variable` の変数の行だけ)。

## 4. `SolverODE` の中のイベントの扱い

### 4.1 区間ごとの DAE [提案、現行の動作を保つ]

| イベント | 縮約(EM, RM) | 右辺・ヤコビアンの遮断 | 区間の終わり(次の区間の初期値) |
|---|---|---|---|
| 機器の解列 `iv_tripComp` | その機器の x と u の行を外す(LC は残す。現行 `initial_condition.m:20` は所有者が機器のタグの行だけ) | 母線への電流 `f_I` を足さない(`lv_compOn`)。その機器を観測する GC の入力の接続を 0 にする(`S_sig`, `S_var` の行に重み 0、現行 `solve.m:242-245`) | 戻るとき、発電機は `f_reconnect(V)` の状態、その LC は平衡点(現行 `getNextPhase.m:24-35`)。発電機以外は外れたときの値のまま |
| GC の解列 `iv_tripGC` | GC の x と uc の行を外す | `f_dx`, `f_Y` を評価しない(出力 0) | 戻るとき平衡点(`getNextPhase.m:48-54`) |
| 地絡 `iv_faultBus` | 母線の Vre, Vim と Ire, Iim の行を外す(電圧は 0 に固定) | — | 戻るとき平衡点の V と I(`getNextPhase.m:38-44`) |
| 開放 `iv_openBranch` | — | `Y = cm_Y - Σ c_branchY{k}` を `im_branchBus(k,:)` の位置に。集合が変わったときだけ作り直す(現行 `set_admittance.m:13-15`) | 次の区間の集合で作り直す |
| オフセット `iv_offset` | — | — | 区間の開始で `x0(iv_offset) += rv_offset` |
| 入力 `c_input` | — | `e(iv_row) += f(t)`(現行 `getODEFunction.m:77-80`) | — |

### 4.2 区間の初期化と整合する初期条件 [事実、変更なし]

区間の境界では微分状態をそのまま引き継ぎ、代数変数だけをその区間の網で解き直します(`CalculateInitialCondition`、解析的なヤコビアンのニュートン法)。解けなければ `InitialConditionFailed`、ソルバーが微分状態を動かしたら止めます(`solve.m:106-170`)。疎行列が拒まれたら密行列で解き直します(`use_dense`)。これらは位置だけで動くので、データの約束の変更で変わりません。

### 4.3 区間の結果 [提案]

`phase_result` は `iv_tripComp`, `iv_tripGC` のブロックの `iv_x` を NaN にし、`I = Y*V` を記録します。タグの照合(`phase_result.m:15-21`)は位置に変わります。記録する行は、現行の x, Vre, Vim, u(`iv_lin`)に**制御器の入力 uc を加えた全変数の行**にします(`Format="struct"` の制御器の表に要るため、§5.3)。`ResultODE` は従来どおり x, Vre, Vim, u の列だけを持ちます。

### 4.4 島の検査 [提案]

現行 `check_islands(net, ...)`(`private/check_islands.m`)は `build_simulation_data` 側(`@PowerNetwork/private/check_islands.m` に移す)で、`compile` の後、積分の前に全区間を検査します。メッセージはブランチと母線のタグを示すので、モデル側が適しています。エラー ID は `GUILDA:PowerNetwork:OpenBranchIsland` に改名します(§6.3)。

## 5. 出力の約束

### 5.1 `sct_sol`(`solve` の第 1 出力)[提案]

| フィールド | 型・大きさ | 内容 |
|---|---|---|
| `rv_t` | double, n_t × 1 | 時刻。区間の境界は 2 回(現行と同じ) |
| `rm_variable` | double, n_t × n_var | 変数 x, Vre, Vim, u, uc の値(`tab_variable` の変数の行の順)。解列中の状態は NaN |
| `rm_I` | double, n_t × 2 n_bus | 母線電流 Ire, Iim |
| `rv_phase` | double, n_t × 1 | 各時刻の区間の番号(`Format="struct"` の出力の評価で、区間の開始からの時刻を作るため) |

`flag` と `output` は 2 番目、3 番目の出力です(どの `Format` でも同じ)。

### 5.2 `ResultODE` のコンストラクタ [決定 Q8、提案]

`ResultPF(tab_powerflow, cm_Y, sct_network, sct_solver)` に揃えます。

```matlab
function obj = ResultODE(sct_sol, tab_variable, sct_network, sct_solver)
    arguments (Input)
        sct_sol      struct = struct()   % Raw solver data (section 5.1).
        tab_variable table  = table()    % Variable rows of get_variable_map (x, Vre, Vim, u, uc), the columns of sct_sol.rm_variable.
        sct_network  struct = struct()   % Snapshot of the network: struct(net, false).
        sct_solver   struct = struct()   % solver, options, flag, output, elapsed.
    end
```

- `ResultODE.tab_variable` と `rm_variable` は x, Vre, Vim, u の行・列だけにします(現行と同じ。`get_point` が uc を `UnknownVariable` にする説明もそのまま)。
- `sv_bus`, `c_component` は `sct_network`(`a_Bus{i}.s_tag`、`a_Bus{i}.a_Component{j}.s_tag`)から、`c_index` は `tab_variable` の `Kind`, `Owner`, `Bus` から作ります(`get_variable_map` の `c_idxBus` を使わない)。`simulator_columns.m` の検査 `GUILDA:ResultODE:VariableMap` は不要になります。
- `ResultBase` には `[]` を渡し、`s_network` は `ResultODE` が設定します(`ResultPF` と同じ)。`a_PowerNetwork` は空です。
- 新しいプロパティ: `sct_network`(SetAccess=private)。
- **系統の情報が要る理由:** 結果のメソッド(`Plot`, `get_point`, `export`, `odeResults`)は系統を読みません。読むのは `Scenario.out_of_step` の基準(スラック母線、慣性 `M`)だけで、`out_of_step` はスナップショットから `l_isSlack` と `tab_parameter.dynamics.M` を読みます。[未確認] `struct(net, false)` の時間(IEEE68 など)は計っていません。S3 で計り、§8.2 のとおり記録します。

### 5.3 `Format="struct"` の形 [決定 Q9、**形は要確認**]

`Format="struct"` の第 1 出力は、クラスごとに分けた struct です。各物体の応答は MATLAB の table で、列名は変数名です。`build_simulation_data` のデータと `sct_sol` から `simulate` が作ります(`@PowerNetwork/private/struct_result.m`)。

```matlab
sol = net.simulate("case1", Format="struct");
sol.Bus.B001              % table: Time, Vre, Vim, Ire, Iim
sol.Component.B001SG1     % table: Time, <states>, <inputs>, <outputs>
sol.Controller.B001SG1AVR1  % table: Time, <states>, <inputs>, <outputs>   (local)
sol.Controller.AGC1       % table: Time, <states>, <inputs>, <outputs>   (global)
sol.Variable              % table: the variable rows of get_variable_map (x, Vre, Vim, u, uc)
sol.Phase                 % table: output.phases (t1, t2, one column per disturbance)
sol.Disturbance           % table: tab_disturbance of the scenario
sol.Scenario              % string: tag of the scenario
```

| 部分 | 列 | 値の出どころ |
|---|---|---|
| `Bus.<母線タグ>` | `Time`, `Vre`, `Vim`, `Ire`, `Iim` | `rv_t`, `rm_variable` の Vre・Vim の列, `rm_I` |
| `Component.<機器タグ>` | `Time`, 状態(`sv_x`), 入力(`sv_u`), 出力(`sv_y`) | 状態と入力は `rm_variable`。出力は記録しないので、`f_Y(t, x, V)` を各時刻で評価します(t は区間の開始からの時刻、ソルバーと同じ規約。`rv_phase` から作る)。解列中は状態と出力が NaN |
| `Controller.<LC タグ>` | `Time`, 状態, 入力(uc), 出力(yc) | uc は `rm_variable`。出力は `f_Y(t, x, V, u)` を評価(V は親の機器の母線) |
| `Controller.<GC タグ>` | `Time`, 状態, 入力 `<名前>_<機器タグ>`, 出力 `<名前>_<機器タグ>` | GC の uc・yc は制御対象ごとにあるので、列名に機器のタグを付けます(`get_variable_map` の `Label` から GC のタグを除いた形)。出力は `f_Y(t, x, V_all, u)`。解列中の GC は状態と出力が NaN |

- **列名の重なり [要確認]:** 状態・入力・出力に同じ名前があると table を作れません(例: 出力 `omega` と状態 `omega` を持つ機器)。案: 出力の列に限り、重なるときだけ `y_<名前>` にします。全部の出力の列に `y_` を付けると規則は単純になりますが、名前が長くなります。
- **タグの名前空間:** LC のタグは親を先頭に付けた自動のタグ(`B001SG1AVR1` など)、GC のタグは系統の子のタグです。[未確認] 利用者が付けたタグで LC と GC が重なりうるかは S5 で確かめ、重なりうるなら `Controller.Local` と `Controller.Global` に分けます。
- **区間の境界:** 時刻が 2 回現れる行は、どの表でもそのまま 2 行です(`ResultODE.rv_t` と同じ)。
- **計算量:** 出力の評価は時刻 × ブロックの数だけ `f_Y` を呼ぶので、`Format="struct"` のときだけ行います。

### 5.4 `export` への改名 [決定 Q14]

- `simulate` の `Export` オプションを削除し、利用者は `result.export(filename)` を呼びます。拡張子の検査(現行 `simulate.m:103-112` の `check_export`、`SimulateExport`)は `ResultODE.export` の先頭へ移します(積分の後ですが、結果は失われません)。
- `ResultODE.Export` を `export` に改名します。§1.6 のとおり `Export` は `ResultBase` の約束なので、**`ResultBase.Export` → `export`(既定の `error_unsupported("export")`)と、全結果クラス(`ResultPF`, `ResultOPF`, `ResultCPF`, `ResultODE`)の改名を揃える**必要があります。だれが先に行うかは §7 の注意に書きます。
- `Format="struct"` の結果は `export` を持ちません。書き出すときは `Format="GUILDAorigin"` で実行します。

## 6. 削除・改名の一覧と移行

### 6.1 ファイル

| ファイル | 扱い |
|---|---|
| `_GUILDAsystem/_VersionSupport/v3_simulate_args.m` | 削除 |
| `_GUILDAsystem/_VersionSupport/ODEevent.m` | 削除 |
| `_GUILDAsystem/_auxiliary/@Scenario/copy.m` | 削除(`add_scenario(tag, From=sc)`) |
| `_GUILDAsystem/_auxiliary/@Scenario/string.m` | 削除(`LayerPackage.string`) |
| `_GUILDAsystem/_auxiliary/@Scenario/import_csv.m`, `export_csv.m` | 削除(`PowerNetwork.import_csv` / `export_csv` の `scenario/*.json`) |
| `_GUILDAsystem/_auxiliary/@Scenario/private/getTimeSpan.m` | 時間が空のときの規則を削除(`phase_table` に吸収してもよい) |
| `_GUILDAsystem/_auxiliary/@Scenario/private/mustBeSimulationTime.m` | `SystemTools/` 直下へ移す(`PowerNetwork` からも使う)。`[]` を受けない形に |
| `_GUILDAsystem/_auxiliary/@SolverODE/get_options.m` | 削除(設定の合成は `simulate`) |
| `_GUILDAsystem/_auxiliary/@SolverODE/progress_mode.m` | `@PowerNetwork/private/progress_mode.m` へ移す |
| `_GUILDAsystem/_auxiliary/@SolverODE/private/validate_options.m` | `SolverOptions` と `Solver` の照合を `@PowerNetwork/private/check_solver_options.m` へ移し、削除 |
| `_GUILDAsystem/_auxiliary/@SolverODE/private/mustBeProgress.m` | `@PowerNetwork/private/` へ移す |
| `_GUILDAsystem/_auxiliary/@SolverODE/private/check_islands.m` | `@PowerNetwork/private/` へ移す |
| `_GUILDAsystem/_auxiliary/@SolverODE/private/checkSimulationTime.m` | 削除(未使用、simulate-improvements ST2) [事実: 呼び出しなし] |
| `_GUILDAsystem/_auxiliary/@ResultODE/private/simulator_columns.m` | `tab_variable` から作る形に書き換え |
| `_GUILDAsystem/_auxiliary/@ResultODE/Export.m` | `export.m` に改名 |
| `_GUILDAsystem/_auxiliary/@ResultBase/Export.m` | `export.m` に改名(§5.4、§7 の注意) |
| `_GUILDAsystem/_auxiliary/@PowerSystemModel/gui.m` | `@LayerPackage/gui.m` へ移す [決定 Q12] |
| `@PowerNetwork/build_simulation_data.m`, `@PowerNetwork/private/read_scenarios.m`, `write_scenarios.m`, `struct_result.m`, `check_simulation.m`, `simulation_blocks.m`, 検証関数 | 新規 |

### 6.2 メンバー

| メンバー | 扱い |
|---|---|
| `Scenario.Options`, `set.Options` | 削除 |
| `Scenario.l_compat` | 削除 |
| `Scenario.copy` | 削除 |
| `Scenario.import_csv`, `Scenario.export_csv`(Static) | 削除 |
| `Scenario(tag, opt)`(公開コンストラクタ) | `Scenario(net, s_tag)`、`Access={?PowerNetwork}` |
| `Scenario.Time` | 既定 `[]` → `[0, 10]`、`(1,2)` に固定 |
| `Scenario.validate(obj, net)` | `validate(obj)` |
| `Scenario.compile(c_scenario, net, time)`(Static) | `compile(obj, sct_dae, time)`(§3.4) |
| `Scenario.to_json_struct`, `add_from_json_struct` | 追加(`Access={?PowerNetwork}`) |
| `Scenario.Ver` | 2.0 → 3.0、「1.x: ODEevent」の説明を削除 |
| `Scenario` の親クラス `auxiliary` | `LayerPackage` |
| `PowerNetwork.add_scenario(sc)` | `sc = add_scenario(s_tag, Time=, Description=, Judge=, From=)` |
| `PowerNetwork.simulate(time, sc..., NV)` | `simulate(s_scenario, Time=, ..., Format=)` |
| `PowerNetwork.build_simulation_data` | 追加(Hidden)[決定 Q11] |
| `PowerNetwork.children` | `a_Scenario` を含める |
| `PowerNetwork.import_csv` / `export_csv` | `scenario/<tag>.json` を読み書き |
| `LayerPackage.gui`, `LayerPackage.gui_content`(既定) | 追加(`PowerSystemModel.gui` から移す) |
| `SolverODE.OptionMap`, `get_options`, `progress_mode` | 削除 |
| `SolverODE.solve(net, time, c_events, sct_options)` | `solve(sct_dae, sct_event, rv_x0, sct_options)` |
| `SolverODE.build_index(net)` | `build_index(sct_dae)` |
| `SolverODE.set_admittance(ctx, sv_open, l_force)` | `set_admittance(ctx, iv_open, l_force)` |
| `ctx.net`, `ctx.c_comp{j}.comp`, `ctx.c_lc{k}.con`, `ctx.c_gc{k}.gc`, `ctx.sv_owner` | 削除(位置と `f_reconnect`) |
| `ResultODE(net, solver, options, flag, output, elapsed, c_phase)` | `ResultODE(sct_sol, tab_variable, sct_network, sct_solver)` |
| `ResultODE` の `a_PowerNetwork` | 空。`sct_network` を追加 |
| `ResultBase.Export` と各結果クラスの `Export` | `export` |
| simulate の `Export` オプション | 削除 [決定 Q14] |
| simulate の `SolverOptions` オプション | **残す**(呼び出しだけ)[決定 Q6] |
| simulate の `Time`, `MaxStep`, `InitialStep`, `Format` オプション | 追加 |
| `PhaseProbe`(`sct_options` のテスト用フィールド、`solve.m:86-88`) | 残す(テストは `build_simulation_data` のデータで `solve` を直接呼ぶ) |

### 6.3 メッセージ

| ID | 扱い |
|---|---|
| `GUILDA:Deprecated:ODEevent`, `GUILDA:Deprecated:SimulateOptionName`(`Deprecated.xml`) | 削除 |
| `GUILDA:PowerNetwork:SimulateArguments` | 削除(arguments ブロック) |
| `GUILDA:PowerNetwork:SimulateTime` | 削除(`Time` は `mustBeSimulationTime` が検査) |
| `GUILDA:PowerNetwork:SimulateExport` | `GUILDA:ResultODE:ExportExtension` に改名(`export` の検査) |
| `GUILDA:PowerNetwork:ScenarioTimeConflict`, `ScenarioOptionConflict` | 削除(1 回に 1 つのシナリオ) |
| `GUILDA:PowerNetwork:NotScenario` | 削除(`add_scenario` はタグを受ける) |
| `GUILDA:PowerNetwork:ScenarioTagInUse` | 削除(重なりは改名、§2.2) |
| `GUILDA:Scenario:UnknownOption` | 削除 |
| `GUILDA:Scenario:OtherNetwork`, `ScenarioArray`, `DuplicateRunTag` | 削除(シナリオは常に系統の子、1 回に 1 つ) |
| `GUILDA:Scenario:Csv*`(`CsvFileExists`, `CsvFunctionHandle`, `CsvMissingColumn`, `CsvUnknownColumn`, `CsvInvalidNetwork`, `CsvNotSaved` など) | 削除 |
| `GUILDA:PowerNetwork:ScenarioFunctionHandle`, `ScenarioJudgeNotSaved`, `GUILDA:import_csv:ScenarioJson`, `UnknownScenarioField` | 追加(§2.8) |
| `GUILDA:resolve_options:UnknownName`(simulate の経路) | MATLAB の arguments ブロックのエラーに変わる |
| `GUILDA:SolverODE:Stale`, `InputEdited`, `GconNoTarget`, `OpenBranchIsland` | `GUILDA:PowerNetwork:SimulateStale`, `SimulateInputEdited`, `GconNoTarget`, `OpenBranchIsland` に改名(モデル側の検査になるため。`msg` は呼び出し元のクラスの ID しか受け付けない、powerflow-structure と同じ理由) |
| 現行 `validate_options` の `SolverOptions` の不一致の ID | `GUILDA:PowerNetwork:` の ID に改名 [未確認: 現行の ID 名は実装時に確認] |
| `GUILDA:ResultODE:VariableMap` | 削除 |
| `GUILDA:ResultBase:Unsupported` | 本文の "Export" を "export" に |
| `GUILDA:SolverODE:MassNotConstant` | 追加(現行 `GUILDA:read_mass:NotConstant` の経路を置き換え) |
| `GUILDA:PowerNetwork:ScenarioNotFound` | 本文を「`simulate` のタグにも使う」形に。シナリオの一覧を示す |

### 6.4 利用者の移行(v4-migration §1.11, §1.18 に書く内容)

| 旧 | 新 |
|---|---|
| `sc = Scenario("f"); sc.add_fault(...); net.add_scenario(sc)` | `sc = net.add_scenario("f"); sc.add_fault(...)`(`Time` は `[0, 10]`) |
| `net.simulate([0 20], sc)` | `net.simulate("f", Time=[0 20])`、または `sc.Time = [0 20]; net.simulate("f")` |
| `net.simulate([0 10])`(外乱なし) | `net.add_scenario("free"); net.simulate("free")` |
| `net.simulate(sc)` で外乱の時間幅から時間を決めていた | `Time` を明示する(既定は `[0, 10]`) |
| `net.simulate(t, sc1, sc2)` | 1 つのシナリオに外乱をまとめる: `net.add_scenario("both", From=sc1)` の後に `sc2` の外乱を足す |
| `sc.Options = struct("Tolerance",1e-6)` | 呼び出しで `net.simulate("f", Tolerance=1e-6)`、または `GUILDA.setting("TimeSimulation", Tolerance=1e-6)` |
| `SolverOptions=matlab.ode.options.ODE15s(MaxStep=0.01)` | そのまま使える。`MaxStep=0.01` だけでもよい |
| `net.simulate(..., Export="sim.csv")` | `res = net.simulate(...); res.export("sim.csv")` |
| `res.Export(...)`(全結果クラス) | `res.export(...)` |
| `other.add_scenario(sc.copy())` | `other.add_scenario("f", From=sc)` |
| `Scenario.import_csv(file, Network=net)` / `Scenario.export_csv(file, net.a_Scenario)` | `net.export_csv(folder)` が `folder/scenario/<tag>.json` を書き、`PowerNetwork.import_csv(folder)` が読む。単独の読み書きはない |
| `ODEevent(tag, net, ...)` | `net.add_scenario(tag).add_disturbance(tag, ...)` |
| `simulate(..., "Reporter", v)` / `"RelativeTolerance", v` | `Progress=v` / `Tolerance=v` |
| `res.a_PowerNetwork` | `res.sct_network`(スナップショット)。系統そのものは呼び出し側の変数 |
| `net.solver_ODE.solve(net, time, events, options)` | `[d, e, x0] = net.build_simulation_data(tag, time); net.solver_ODE.solve(d, e, x0, options)`(上級者向け) |

## 7. 実装の手順

各手順は 1 つのサブセッションの大きさです。各コミットで `DebugScript.run_all('Level','small','FailOnUnexpected',true)`、統合の前に medium を 1 回実行します。

| 手順 | 内容 | 主なファイル | テスト | 依存 |
|---|---|---|---|---|
| **S0** 基準の記録 | 軌道の比較用の基準を保存する(§8.3)。コードは変えない | `+DebugScript/+helper/simulate_baseline.m`(新規)、基準の MAT は作業用フォルダ(コミットしない) | 基準の作成だけ | なし |
| **S1** v3 の削除 | `v3_simulate_args.m`, `ODEevent.m`, `Deprecated.xml` の 2 項目, `Scenario.l_compat`, `simulate.m:83`、v4-migration の表 | `_VersionSupport/` の 2 ファイル, `Deprecated.xml`, `Scenario.m`(l_compat の 2 行), `simulate.m`(1 行) | F6「Deprecated option names still work」、F31「Compatibility」の節と `test_levels` の該当行を削除 | S0 |
| **S2** `Scenario` を `LayerPackage` に | §2.2-2.5: `add_scenario(tag)`(改名と INFO), `remove_scenario`(delete), `From`, `copy` の削除, `Time` の既定 `[0, 10]` と時間の規則の削除, `children`, `log_edit` の上書き, `gui` の移動, GUI の描画, `disp_tree`, `sig_methods` の add/remove | `@Scenario/*`(`compile.m` の時間の分岐を含む。`out_of_step.m`, `import_csv.m`, `export_csv.m` を除く), `@Scenario/private/getTimeSpan.m`, `mustBeSimulationTime.m`(SystemTools へ), `@PowerNetwork/PowerNetwork.m`, `add_scenario.m`, `remove_scenario.m`, `gui_content.m`, `@LayerPackage/`, `@PowerSystemModel/gui.m`, `@DrawerModelGUI/`, `@GUILDA/update_keymap.m`, `functionSignatures.json`, `+DebugScript/+helper/scenario.m`, `noop_event.m` | F31 の書き換え(CSV の節を除く)、F32/F33(GUI のシナリオのカード)、F24(タグの名前空間)、F34、I53, I54(時間の規則)、新規は §8.2 | S1 |
| **S3** `ResultODE` をデータから、`export` | §5.2, §5.4: 新しいコンストラクタ, `sct_network`, `simulator_columns` の書き換え, `out_of_step` のスナップショット読み, `ResultODE.Export` → `export`(`ResultBase` の改名が統合済みであること、下記) | `@ResultODE/*`, `@Scenario/out_of_step.m`, `@SolverODE/solve.m`(231 行の 1 か所だけ。暫定で `net` から入力を作る), `simulate.m`(`Export` の呼び出し 95-99 行を `export` に) | F6 の結果の節、F31 の判定、I63(export)、新規: 系統を消した後(`delete(net)`)も `Plot`, `get_point`, `export`, 判定が動く | S1、`ResultBase.export` |
| **S4** `simulate` の引数と設定 | §2.1, §2.7: タグの引数, `Time` の上書き, arguments ブロック, 設定の合成, `SolverOptions` と `MaxStep`/`InitialStep` の優先順位, `Format`(`"struct"` は S5 で完成。S4 では `"GUILDAorigin"` だけ受け付けてもよい), `Export` オプションの削除, `Scenario.Options` の削除, `get_options` 等の削除, `sig_methods` の simulate, 呼び出し元(`_GUILDAobject` のヘルプの例 20 ファイル、`_GUILDAverification` の 4 ファイルの simulate の行) | `simulate.m`, `@PowerNetwork/private/`(検証関数, `progress_mode`, `check_solver_options`), `@SolverODE/SolverODE.m`, `get_options.m`, `progress_mode.m`, `private/makeODE.m`, `validate_options.m`, `mustBeProgress.m`, `@Scenario/Scenario.m`(Options), `DefaultTimeSimulation.json`, `update_keymap.m`, `functionSignatures.json`, `+DebugScript/*`(simulate の呼び出し約 230 か所) | 全 simulate テストの書き換え、I54(時間の検査)、I63(`Export` オプションの節を `export` に)、新規は §8.2 | S2(`Scenario.m`, `update_keymap.m`), S3(`simulate.m` の export の行) |
| **S5** `SolverODE` のデータの約束、`Format="struct"` | §3, §4, §5.1, §5.3: `build_simulation_data`, `compile` の位置化, 初期値, `check_islands` の移動, `build_index` の分割, `set_phase`/`set_admittance`/`initial_condition`/`getNextPhase`/`phase_result` の位置化(uc も記録), `solve` のシグネチャ, `struct_result`, S3 の暫定の除去 | `simulate.m`, `@PowerNetwork/PowerNetwork.m`(Hidden の宣言), `@PowerNetwork/build_simulation_data.m`, `@PowerNetwork/private/`(収集, `struct_result`), `@Scenario/compile.m`, `@SolverODE/*` | F6, F29, F35(`PhaseProbe` で `solve` を直接呼ぶ箇所を `build_simulation_data` に)、I50-I64、§8.3 の軌道の一致、新規は §8.2 | S3, S4 |
| **S6** シナリオの JSON | §2.8: `export_csv` / `import_csv` の `scenario/`, `read_scenarios`/`write_scenarios`, `to_json_struct`/`add_from_json_struct`, `Scenario.import_csv`/`export_csv` の削除, `_GUILDAverification` の 3 スクリプトのシナリオの読み込み | `@PowerNetwork/import_csv.m`, `export_csv.m`, `@PowerNetwork/private/read_scenarios.m`, `write_scenarios.m`, `@Scenario/import_csv.m`, `export_csv.m`, `Scenario.m`(2 メソッドの宣言), `_GUILDAverification/IEEJ_*/compare_table*.m` | F16(CSV の往復)にシナリオを追加、F31 の CSV の節を JSON に置き換え、新規は §8.2 | S4(`Scenario.m`、検証スクリプト) |
| **S7** 文書 | `feature-simulation.html`(シーケンス図、SIM-xx の手順、オプション表)、`feature-data-io.html`(`scenario/` の JSON)、`api-design.html`, `class-design.html`, Update log, `v4-migration.md`, `status.md`、ヘルプの `<@Examples>` の残り | `_GUILDAdoc/`, `notes/` | 文書の検査スクリプト(あれば) | S5, S6(利用者向けの部分は S4 の後に並行可) |

**並行できる組 [提案]**

- S2 と S3 は並行できます(重なるファイルはありません。S3 は `@Scenario/out_of_step.m` だけ、S2 はそれ以外の `@Scenario/*` のうち CSV と `out_of_step` 以外)。ただし S3 は `ResultBase` の改名の統合を待ちます(下記)。
- S5 と S6 は並行できます(S5 は `compile.m`, `simulate.m`, `build_simulation_data.m`, `@SolverODE/*`、S6 は `import_csv.m`, `export_csv.m`, `@Scenario/import_csv.m`・`export_csv.m`, 検証スクリプト。`Scenario.m` は S6 だけ、`PowerNetwork.m` は S5 だけが触る。`@PowerNetwork/private/` は別のファイル名)。
- S7 の利用者向け(Tutorial 以外のページ、v4-migration)は S4 の後、S5 と並行できます。`feature-simulation.html` は S5 の後、`feature-data-io.html` は S6 の後です。
- `_GUILDAtutorial/*.mlx` はチュートリアルの保留(#113)に含まれるため、この計画では変えません。

**注意(他の作業との重なり)**

- **`Export` → `export` の改名:** `ResultBase.Export` は全結果クラスの共有の約束です(§1.6)。潮流計算の作業(`refactor/powerflow-structure`)が `ResultPF` で同じ改名をするので、**その作業が `ResultBase`(`ResultBase.m:85`, `Export.m`, `error_unsupported.m` の本文)と `ResultPF`, `ResultOPF`, `ResultCPF` とその呼び出し元をまとめて先に改名する**ことを推奨します。S3 はその統合の後に始め、`ResultODE` だけを改名します。潮流計算の作業が `ResultBase` を触らない場合は、S3 の前に小さな手順「S2.5 `ResultBase` と OPF・CPF の `export`」を挟みます(どちらが行うかはコーディネーターが決める)。
- `refactor/powerflow-structure`(未統合)も `@PowerNetwork/private/` に `mustBePlotFcn` を置く可能性があります。S4 の開始時に統合済みならそれを使い、未統合なら S4 で作り、後から統合する側が片方を消します。
- `update_keymap.m` と `functionSignatures.json` は S2 と S4 が触るので、S4 は S2 の統合後に始めます。
- `PowerNetwork.import_csv` / `export_csv` は S6 だけが触ります。§9.3 の「接続を JSON、パラメータを CSV」の設計を行う場合は、S6 の後にします。

## 8. テスト計画

### 8.1 書き換える既存テスト [事実: grep の件数、基準コミット]

| 検索 | ファイル(件数) |
|---|---|
| `simulate(` | F6 (63), F31 (27), F3_initialize (13), I51 (13), I54 (13), F3_edit_handling (10), I60 (9), F30 (8), I61 (7), I63 (7), F29 (6), F7 (6), I64 (6), F35 (5), F8 (5), I53 (5), I55 (5), I56 (4), F22, F28, I105, I111, I50, I58 (各 2-3), その他 10 ファイル (各 1) |
| `Scenario(` | F29, F31, F36, F6, I53 |
| `add_scenario` | F31 (19), F29, F36, F6 |
| `ODEevent`, `l_compat` | F31, `test_levels.m:97` |
| `.Options` / `Options=` | F31 (66, 75, 325 行) |
| `Scenario.import_csv`, `export_csv` | F31 (182-218 行) |
| `solver_ODE.solve(` | F29 (52, 192 行), F35 (300 行) |
| `SolverOptions=` | F6(残る。`MaxStep` との優先順位の節を加える) |
| `.Export(` / `Export=` | I63, F6, I62, F2, F4, F5, F10(33 か所。`ResultBase` の改名と一緒に) |

**補助関数:** 多くのテストは `DebugScript.helper.noop_event(net, tspan)` と `DebugScript.helper.scenario(tag, net, ...)` でシナリオを作り、`net.simulate(tspan, ev)` で実行します。S2 で `helper.scenario` を `net.add_scenario` に、`noop_event` が `Time=tspan` を設定する形にし、S4 で `net.simulate(tspan, ev)` を `net.simulate(ev.s_tag)` に置き換えます。シナリオと違う時間で実行する箇所は `net.simulate(ev.s_tag, Time=tspan)` にします。

### 8.2 新しいテスト

- タブ補完: `functionSignatures.json` の `PowerNetwork.simulate` の `s_scenario` が `choices=cellstr(string(obj.a_Scenario))`(F34)。
- `simulate("nope")` が `ScenarioNotFound` で止まり、本文にタグの一覧がある。
- `Time`: `simulate("f", Time=[0 2])` が `[0, 2]` で計算し、`sc.Time` は変わらない。`Time` を与えなければ `sc.Time`。`add_scenario("f")` の `Time` は `[0, 10]`。外乱の時間幅は時間を変えない。
- 呼び出しの `Tolerance` が `result.options` に入り、`GUILDA.config("TimeSimulation","Tolerance")` は変わらない。与えない名前は設定の値。
- `MaxStep=1e-3` で出力の時間間隔が 1e-3 以下。設定の `MaxStep` も効く(`GUILDA.setting` を一時的に変え、`onCleanup` で戻す)。呼び出しの `SolverOptions` があるとき設定の `MaxStep` は当たらず、呼び出しの `MaxStep` は当たる。`MaxStep` も `SolverOptions` も与えない実行は基準と `isequaln`。
- `Format="struct"`: `sol.Bus.<tag>.Vre` が `ResultODE` の同じ列と `isequaln`。`sol.Component.<tag>` の出力の列が `f_Y` の値と一致。GC の列名が `<名前>_<機器タグ>`。解列中の行が NaN。
- `simulate(..., Export=...)` が MATLAB の未知の名前のエラーになる。`result.export("x.foo")` が `ExportExtension` で止まる。
- `Scenario` の改名・外乱の追加が `net.sct_stale` と `n_revOPF` を変えない。
- `disp_tree` の出力にシナリオの行がある。GUI のシナリオのカードとページ(F32/F33 の形で、表示を開いて閉じる)。
- `add_scenario` のタグが母線のタグと重なると番号を足した `sc.s_tag` になり、INFO が出る(`evalc` で確かめる)。
- `remove_scenario` の後、その変数の `isvalid` が false。`From` で別の系統へ複製すると元は残る。
- JSON: `export_csv` → `import_csv` の往復で、各シナリオの `Time`, `Description`, `tab_disturbance`、名前のある `Judge` が一致。無名の `Judge` は `ScenarioJudgeNotSaved` を警告して既定に戻る。関数の `InputValue` は `ScenarioFunctionHandle` で止まり何も書かない。`scenario/` のないフォルダは従来どおり読める。壊れた JSON は系統を変える前に止まる。
- `solve` が系統を読まない: `build_simulation_data` の後で系統を `delete` し、`solve` が同じ結果を返す(S5)。
- `ResultODE` が系統を読まない: 系統を `delete` した後で `Plot`, `get_point`, `odeResults`, `export`, `Scenario.out_of_step(result)`(`Reference="slack"`, `"COI"`)が動く(S3。シナリオは系統と一緒に消えるので、判定は `out_of_step` を直接呼ぶ)。`struct(net, false)` の時間を IEEE68 で記録する。

### 8.3 軌道が変わらないことの確認 [提案]

S0 で、基準コミットのコードで次の実行の `rv_t`, `rm_variable`, `rm_I`, `output.phases`, `flag` を MAT ファイルに保存します(作業用フォルダ、コミットしない)。すべて時間を明示します(Q2 で時間の自動の規則がなくなるため)。

| 例 | 外乱 |
|---|---|
| IEEE68bus(既定) | B008 などの地絡 `[1, 1.07]`、`[0, 10]` |
| IEEE68bus(`LocalController=false`) | 外乱なし `[0, 5]`(t = 0 の停止の回帰) |
| IEEE14bus(AVR+PSS) | SG1B003 の解列 `[1, 1.2]`(再接続)、`[0, 5]` |
| IEEE14bus | EL003 の開放 `[1, 3]`、`[0, 5]` |
| IEEE9bus | オフセット(`delta` +0.1)と入力(`Pmech` 0.05、関数入力)、`[0, 5]` |
| AGC 付きの系統(F18 の構成) | GC の解列、GC が観測する機器の解列、`[0, 5]` |

各手順の後に同じ実行をして比べます。

- **S1-S4, S6:** 数値の経路を変えないので `isequaln` で一致することを求めます。
- **S5:** 評価の順序と初期値(`rv_Iequilibrium` を含む)を保つので、`isequaln` を目標にします。一致しない場合は差の最大値を記録し、`Tolerance` 以内で、原因(例: 行列の組み立ての順)を特定してから統合します。
- 比較は `DebugScript.helper.simulate_baseline(Mode="compare")` のように 1 つの関数で行い、F6 に常設はしません(基準の MAT をリポジトリに入れないため)。常設するなら、短い区間の小さな例で、基準値を数値でテストに書きます。

## 9. 問いと回答

### 9.1 回答済み(2026-11-12)

§0.2 の表のとおりです。回答の前の推奨と違う決定は Q1(時間の上書きを許す)、Q2(既定 `[0, 10]`)、Q3(改名と INFO)、Q6(`SolverOptions` を残す)、Q9(クラスごとの table)、Q13(系統のフォルダの JSON)、Q14(`Export` オプションの削除と `export` への改名)です。

### 9.2 利用者の確認を待つ事項

| # | 事項 | 推奨 |
|---|---|---|
| R1 | `Format="struct"` の形(§5.3): `Bus`, `Component`, `Controller`, `Variable`, `Phase`, `Disturbance`, `Scenario` | §5.3 の案。LC と GC を `Controller` にまとめる(LC と GC のタグが重なりうるなら `Controller.Local` / `Controller.Global` に分ける) |
| R2 | `Format="struct"` で状態と出力の名前が重なるとき | 重なる出力の列だけ `y_<名前>` |
| R3 | シナリオの JSON(§2.8): タグはファイル名だけ、`Judge` は名前だけ(無名関数は警告して保存しない)、関数の `InputValue` はエラー | 案のとおり |
| R4 | `_GUILDAverification` の IEEJ のシナリオ(§2.8 末) | 検証スクリプトのローカル関数で CSV を読み、`add_scenario` と `add_disturbance` を呼ぶ |
| R5 | `Export` → `export` の改名をだれが行うか(§7 の注意) | 潮流計算の作業が `ResultBase` と PF・OPF・CPF をまとめて先に行い、S3 は `ResultODE` だけ |

### 9.3 別の設計課題: 系統の接続を JSON、パラメータを CSV に

利用者は、系統の接続の構造を JSON に、パラメータを CSV に分けて保存することを検討しています。**S0-S7 とは別の設計課題**として扱い、この再設計では `PowerNetwork.import_csv` / `export_csv` の既存の配置に `scenario/` を足すだけにします。

現状は、すべてが CSV で、表どうしを ID の列で結んでいます [事実]。母線は `bus/parameter.csv` の行番号で番号付けされ、ブランチの `From`・`To` と機器の `Bus` がその番号を指します。機器は `component/<key>/main.csv` の `ParameterID`・`OpfID` で `dynamics.csv`・`opf.csv` の行を指します。タグは `FullTag` 列で保存します。制御器は保存しません(`ControllersNotSaved`)。

- **JSON にする利点:** 階層(母線 → 機器 → ローカル制御器、GC と制御対象)をそのまま書けるので、いまは保存できない制御器を自然に保存できます。番号や ID の列による間接の参照がタグによる参照になり、行の並べ替えや追加で参照が壊れません。シナリオ(§2.8)と同じ形式になり、`Format` と `version` の項目で版を管理できます。
- **JSON にする欠点:** 表計算ソフトで多数の母線や機器を一覧して編集する使い方(いまの CSV の主な利点)が、接続の部分では失われます。接続とパラメータが 2 種類のファイルに分かれるので、両者の対応(タグ)の検査が新たに要ります。既存の CSV フォルダ(同梱の系統、利用者のフォルダ)の移行と、旧形式の読み込みを当面残すかの判断が要ります。
- **中間の案:** 接続(母線の並び、ブランチの両端、機器の母線と key、制御器の階層)を 1 つの JSON に、パラメータを key ごとの CSV(いまの `dynamics.csv` など、`FullTag` で結ぶ)に残すと、制御器の保存と表計算での編集を両立できます。
