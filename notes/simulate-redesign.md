# `simulate` と `SolverODE` の再設計(仕様案)

ブランチは `docs/simulate-redesign-spec`、基準コミットは `9940b9d6`(`refactor/design-alignment`、2026-11-12)です。**この文書は仕様案で、コードは変えていません。** 利用者が確認してから、§7 の手順でサブセッションに分けて実装します。

**根拠の区別**

- **[事実]** 基準コミットのコードを読んで確認しました(行番号は基準コミットのもの)。
- **[決定]** 利用者が 2026-11-12 に決めた方針です(§0)。
- **[提案]** この文書の提案です。採否は §9 の問いで決めます。
- **[未確認]** 調べていない、または MATLAB で動かしていない事項です。この文書のために MATLAB は実行していません。

**関連ノート:** [simulate-improvements.md](simulate-improvements.md)(以前の改善案)、[variable-connection-map.md](variable-connection-map.md)(DAE の変数の並びと接続表)、[controller-signal-routing.md](controller-signal-routing.md)(GC の観測と出力)、[v4-migration.md](v4-migration.md) §1.11, §1.18、[structural-checks.md](structural-checks.md)(削除した構造の検査)。潮流計算の同じ方針の作業は `refactor/powerflow-structure` の `notes/powerflow-structure.md`(未統合)です。

## 0. 利用者の決定(2026-11-12)

1. **1 回の実行に 1 つのシナリオ。** シナリオは 1 回のシミュレーションのすべて(時間、外乱、説明、判定)を持ちます。呼び出しはタグで 1 つだけ選びます: `net.simulate("case1", Name=Value)`。外乱のない実行も、時間だけを持つシナリオを使います。
2. **シナリオは `net.add_scenario(tag, ...)` で作り、そのシナリオを返します。** `simulate` のタブ補完はシナリオのタグを並べ、arguments ブロックがタグを検査します。
3. **`Scenario` は `LayerPackage` にし、`PowerNetwork` の子にします。** stale のタグはなく、編集は `log_edit` を呼びません。`tab_parameter` は空の表です。タグは系統の子と同じ名前空間です。
4. **設定は `GUILDA.setting`(TimeSimulation)が既定で、呼び出しの Name-Value がその呼び出しだけ上書きします。** `Scenario.Options` は削除します。arguments ブロックだけで受け、既定値を書かないことで「呼び出しで与えたか」を判別します。
5. **v3 互換の削除。** `v3_simulate_args`、`_VersionSupport/ODEevent.m`、`Scenario.l_compat` を削除します。他の `_VersionSupport` のファイルは触りません。
6. **`SolverODE` は系統ではなくデータを受け取ります。** モデルの作業(stale の検査、GC の検査、タグから位置への変換、データの収集)は `simulate` が行います。
7. **出力は `Format` で選びます。** `"GUILDAorigin"`(既定)は `ResultODE`、`"struct"` はソルバーの生データです。

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

### 1.2 `SolverODE` が系統とモデルを読む箇所 [事実]

パスは `_GUILDAsystem/_auxiliary/@SolverODE/` からの相対です。

| ファイル:行 | 読むもの | 新しい置き場所 |
|---|---|---|
| `solve.m:34` | `Scenario.compile(c_events, net, time)` | `simulate`(§3.4) |
| `solve.m:35` | `check_islands(net, ...)` | `simulate`(§4.4) |
| `solve.m:36` | `build_index(net)` | 前半(モデルの収集)は `simulate`、後半(位置の計算)は `SolverODE` |
| `solve.m:37` | `ctx.net = net`(`set_admittance`、`getNextPhase` が読む) | 削除 |
| `solve.m:39` | `net.get_admittance_matrix` | `simulate` が `cm_Y` を渡す |
| `solve.m:231` | `ResultODE(net, obj, ...)` | `simulate` が作る(§5) |
| `solve.m:238-249` (`set_phase`) | `ph.sv_trip`, `ph.sv_fault` のタグを `ctx.sv_comp` などと照合 | 位置で受け取る(§3.4) |
| `build_index.m:19, 164-192` (`check_network`) | `net.sct_stale`, 各機器・制御器の `sct_stale` | `simulate` |
| `build_index.m:21` | `net.get_variable_map()` | `simulate` が表を渡す |
| `build_index.m:22-23, 67, 84` | `net.a_Bus`, `net.a_GlobalController`, `a_Component`, `a_LocalController` | `simulate` |
| `build_index.m:62-63` | `b.c_Vequilibrium`, `b.c_Iequilibrium` | `simulate`(平衡点) |
| `build_index.m:77-79, 89-91, 106-109` | `f_*` のハンドル、`st.comp = comp`, `sl.con`, `sg.gc`(物体そのもの) | ハンドルだけ渡す。物体は渡さない |
| `build_index.m:80-81, 92-93, 110-111` | `rv_Xequilibrium`, `rv_Uequilibrium` | `simulate`(平衡点) |
| `build_index.m:82, 94, 112` | `tools.read_mass(comp)` | `SolverODE` が `f_Mass` を評価 |
| `build_index.m:115-124` | `gc.sv_y`, `gc.controlledUnits`(`GconNoTarget`) | `simulate` |
| `build_index.m:148-151` | `string(a_gc)` で GC の入力の行を探す | 行番号で受け取る |
| `set_admittance.m:18-22` | `ctx.net.a_Branch`, `ctx.net.a_Bus`, `a_br{k}.a_Bus`, `a_br{k}.get_admittance_matrix()` | 枝ごとの母線の位置と 2×2 の行列を受け取る |
| `getNextPhase.m:25-26` | `isa(b.comp, 'component.generator.abstract')`, `b.comp.get_equilibrium(V,0,0,0)` | 再接続のハンドル `f_reconnect`(§3.2) |
| `getNextPhase.m:38` | `ctx.net.a_Bus`(個数だけ) | 母線数はデータから |
| `initial_condition.m:20` | `ctx.sv_owner` と `ph.sv_trip`, `ph.sv_fault` のタグ照合 | 位置で受け取る |
| `initial_condition.m:33-40` | `ph.c_Xoffset`, `ph.c_Uoffset`(機器の順のセル) | 第 1 区間は `simulate` が初期値に含める。第 2 区間以降は位置と値 |
| `phase_result.m:15-21` | `b.s_tag` と `ph.sv_trip` の照合 | 位置で受け取る |
| `private/check_islands.m:5-11` | `net.a_Bus`, `net.a_Branch`, `a_Branch{k}.a_Bus`, `b.a_Component` | `simulate` |

`getODEFunction.m` と `getODEJacobian.m` は `ctx` だけを読みます。ただし `ctx.c_comp{j}.f_dx` などは `set_odefcn` が作るクロージャ(`@(t,x,V,u) obj.fcn_dx(t,x,V,u,array,omega0)`、`_GUILDAsystem/@Component/set_odefcn.m:36-39`)で、パラメータ `array` を値で束縛しています。決定 6(a) の「`set_odefcn` のクロージャ」はこれです。`private/makeODE.m` と `private/CalculateInitialCondition.m` は設定と `ode` オブジェクトだけを読みます。

### 1.3 `Scenario.compile` が系統を読む箇所 [事実]

`_GUILDAsystem/_auxiliary/@Scenario/compile.m`

| 行 | 読むもの |
|---|---|
| 38-48 | `sc.a_PowerNetwork ~= net`(`OtherNetwork`)、`sc.validate(net)` |
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

決定 6 の「GC の他系統の機器の検査」(`GUILDA:SolverODE:ForeignControlledUnit`)は、Issue #119 の構造の検査の整理で**削除済み**です([structural-checks.md](structural-checks.md) の「削除した検査」)。`GlobalController` のコンストラクタが制御対象を確かめ、制御対象は制御器がある間は削除も置換もできないためです。`build_index` に残る GC の検査は `GconNoTarget`(出力の行き先がない。追加の後にローカル制御器を外すと起きえる)だけで、これを `simulate` に移します。

## 2. 新しい公開 API

### 2.1 `PowerNetwork.simulate`

```matlab
function [result, flag, output] = simulate(obj, s_scenario, opt)
    arguments (Input)
        obj
        s_scenario (1,1) string {mustBeScenarioOf(obj, s_scenario)}   % Tag of the scenario to run (net.add_scenario).
        opt.Solver (1,1) string {mustBeMember(opt.Solver, ["ode15s","ode23t"])}   % Solver of the MATLAB ode object. Default: GUILDA.setting.
        opt.Tolerance (1,1) double {mustBeInRange(opt.Tolerance, 1e-15, 1e-3)}   % Relative error tolerance. Default: GUILDA.setting.
        opt.AbsoluteTolerance (1,1) double {mustBeInRange(opt.AbsoluteTolerance, 1e-15, 1e-3)}   % Absolute error tolerance. Default: GUILDA.setting.
        opt.MaxStep (1,1) double {mustBePositiveOrNaN}   % [s] Largest step of the solver; NaN for the solver default. Default: GUILDA.setting.
        opt.InitialStep (1,1) double {mustBePositiveOrNaN}   % [s] First step of each phase; NaN for the solver default. Default: GUILDA.setting.
        opt.SeparateComplexParts (1,1) logical   % SeparateComplexParts of the ode object. Default: GUILDA.setting.
        opt.TimeLimit (1,1) double {mustBePositive}   % [s] Wall-clock limit of the whole run; Inf for none. Default: GUILDA.setting.
        opt.Progress {mustBeProgress}   % "dialog", "disp" or "none" (true: "dialog", false: "none"). Default: GUILDA.setting.
        opt.Verbose (1,1) logical   % Print the phases and the outcome. Default: GUILDA.setting.
        opt.PlotFcn {mustBePlotFcn}   % Live display during the run: "none". Default: GUILDA.setting.
        opt.Export {mustBeExport} = false   % true for the default file name of result.Export, or the file name.
        opt.Format (1,1) string {mustBeMember(opt.Format, ["GUILDAorigin","struct"])} = "GUILDAorigin"   % Form of the first output.
    end
    arguments (Output)
        result   % ResultODE (Format "GUILDAorigin") or the raw solver data (Format "struct").
        flag     % 1 completed, 0 stopped by TimeLimit, -1 stopped by the solver.
        output   % Details: message, tEnd, phases, nPhases, nPhasesDone, isSparse, exception.
    end
```

- **既定値を書かない [決定 4]。** 設定の名前の引数には既定値を書かないので、呼び出しで与えなかった名前は `opt` のフィールドになりません。`Export` と `Format` は設定ではないので既定値を書きます。
- **設定の合成 [提案]:**

  ```matlab
  sct_options = struct();
  sct_cfg = GUILDA.config("TimeSimulation");
  for s_name = string(fieldnames(sct_cfg)).'
      sct_options.(s_name) = sct_cfg.(s_name).Value;
  end
  for s_name = setdiff(string(fieldnames(opt)).', ["Export","Format"])
      sct_options.(s_name) = opt.(s_name);      % this call only
  end
  sct_options.Progress = progress_mode(sct_options.Progress);   % true/false -> "dialog"/"none"
  ```

  `TimeLimit` の設定値が正でないときは `Inf` にします(現行 `get_options.m:38-40` と同じ)。設定ファイルの値は検査しないので、`GUILDA.setting` の検査(type、options)に任せます。
- **検証関数の置き場所 [提案]:** `mustBeScenarioOf`、`mustBePositiveOrNaN`、`mustBeProgress`、`mustBeExport`、`mustBePlotFcn` は `@PowerNetwork/private/` に置きます。`mustBePlotFcn` と `mustBeExport` は `refactor/powerflow-structure` の `calculate_powerflow` も使う名前なので、統合の順で重複しないよう、後から入る側が既存のものを使います(§7 の注意)。
- **`mustBeScenarioOf` のエラー [提案]:** `GUILDA:PowerNetwork:ScenarioNotFound`(既存のキー)。本文に系統のシナリオのタグを最大 10 個並べ、`net.add_scenario` を案内します。シナリオがない系統では「`net.add_scenario("name", Time=[0 10])` で作る」と案内します。
- **時間は呼び出しで変えない [提案、Q1]。** 時間はシナリオの `Time` だけです。`simulate([0 5], ...)` の形はなくなります。
- **`output` の内容**は現行と同じです(`message`, `tEnd`, `phases`, `nPhases`, `nPhasesDone`, `isSparse`, `exception`)。`output.phases` の列名は外乱のタグです。
- **警告:** `flag ~= 1` のとき `GUILDA:PowerNetwork:SimulationIncomplete` を出すのは現行と同じです。
- **`Export` [提案、Q14]:** `Format="struct"` でも、`Export` を指定したら書き出しのためだけに `ResultODE` を作ります(`calculate_powerflow` と同じ判断)。拡張子の検査は積分の前です(`mustBeExport`)。

**`simulate` の処理順 [提案]**

1. `sc = obj.a_Scenario{...}`(タグで選ぶ)。
2. stale と入力の編集の検査(現行 `build_index.m:164-192` の `check_network` をそのまま移す。エラー ID は `GUILDA:PowerNetwork:SimulateStale`, `SimulateInputEdited` に改名。§6.3)。
3. `[tab_map, ~, ~, tab_conn] = obj.get_variable_map()`。
4. `sct_dae` を集める(§3.2)。`GconNoTarget` の検査。
5. シナリオを位置に変換する: `[tab_phase, sct_event] = sc.compile(sct_dae)`(§3.4)。島の検査(§4.4)。
6. 初期値 `rv_x0` を作る(§3.5)。
7. `[sct_sol, flag, output] = obj.solver_ODE.solve(sct_dae, sct_event, rv_x0, sct_options)`。
8. `Format` に応じて返す(§5)。`Export`。

### 2.2 `PowerNetwork.add_scenario`

```matlab
function sc = add_scenario(obj, s_tag, opt)
    arguments (Input)
        obj
        s_tag (1,1) string {mustBeNonzeroLengthText}   % Tag of the new scenario; unique among the children of the network.
        opt.Time double   % [s] Simulation time [t0, tend], or [] for the time span of the disturbances. Default: From.Time, else [].
        opt.Description (1,1) string   % Free text. Default: From.Description, else "".
        opt.Judge (1,1) function_handle   % verdict = Judge(result). Default: From.Judge, else @Scenario.out_of_step.
        opt.From Scenario {mustBeScalarOrEmpty}   % Scenario to copy the disturbances and settings from (of this or another network).
    end
    arguments (Output)
        sc Scenario   % The new scenario, a child of the network.
    end
```

- `Time` は arguments ブロックでは検査せず、`sc.Time` への代入でプロパティの検証関数 `mustBeSimulationTime`(`@Scenario/private/`、`@PowerNetwork` からは呼べない)が検査します。
- タグが系統の子(母線、ブランチ、GC、シナリオ、`Parameter` の `base`)のどれかと同じなら `GUILDA:PowerNetwork:ScenarioTagInUse` で止まり、何も作りません [提案、Q3]。他の `add_*` は番号を足して改名しますが、シナリオは利用者がタグで `simulate` を呼ぶので、黙って改名しません。
- `From` の外乱は、この系統に対して `validate` します(失敗すると何も作りません)。`From` は変わりません。**移動**は `net2.add_scenario(tag, From=sc)` と `net1.remove_scenario(tag)` の 2 つの呼び出しです [提案、Q5]。
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
- 外したシナリオは `delete` します [提案、Q4]。Issue #119 の「外した物体は削除する」と同じで、`Scenario.a_PowerNetwork` は常に空でなくなります。外したシナリオを持つ変数は無効なハンドル(`isvalid` が false)になります。

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
        Time double {mustBeSimulationTime} = []                 % (unchanged)
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
                s_tag (1,1) string    % Tag (checked by add_scenario).
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
    % add_fault, add_trip, add_open_branch, add_offset, add_input, add_disturbance,
    % remove_disturbance, judge, out_of_step, import_csv, export_csv: unchanged signatures
    % compile: new signature (section 3.4)
end
```

- **作り方は `add_scenario` だけ** [提案]。コンストラクタは `Access={?PowerNetwork}` です(#119 のモデルの物体と同じ)。`Scenario("x")` の直接の作成は `MATLAB:class:MethodRestricted` になります。
- **`Options`、`l_compat`、`copy`、`string.m`(`LayerPackage.string` と同じ)、`validate(obj, net)` の `net` 引数を削除します。** `validate` は `obj.a_PowerNetwork` に対して検査します。
- **改名:** `sc.s_tag = "new"` は `LayerPackage.set.s_tag` を通り、兄弟と重なれば番号を足します(他の層と同じ)。`log_edit` は何もしないので、`PowerNetwork.handle_edit` の `n_revOPF`(タグの編集で増える、`@PowerNetwork/handle_edit.m:66`)も増えません。
- **`LayerPackage.log_edit` の上書き [提案]:** `log_edit` は `LayerPackage` の protected メソッド(`@LayerPackage/LayerPackage.m:74`)なので、`Scenario` が同じ名前の protected メソッドを定義して上書きします。[未確認] MATLAB で `@LayerPackage/log_edit.m` の上書きと `set.s_tag` からの呼び出しが `Scenario` 版になることは、実装時に確かめます。
- **`import_csv(path, Network=net)` は `Network` を必須にします** [提案、Q13]。シナリオは系統なしで存在しないためです。読んだシナリオは `net.add_scenario(tag, Time=..., Description=...)` で作ってから外乱を足します。
- **`export_csv` の `Options` [提案]:** `Options` がなくなるので、`GUILDA:Scenario:CsvNotSaved` は既定以外の `Judge` だけを警告します。

### 2.5 `children` を使う箇所の扱い [提案]

`PowerNetwork.children` を `[a_Bus; a_Branch; a_GlobalController; a_Scenario; a_Parameter]` にします(`@PowerNetwork/PowerNetwork.m:213-215`)。

| 使う箇所 | 扱い |
|---|---|
| `LayerPackage.set.s_tag`(`LayerPackage.m:88-106`) | シナリオも兄弟になります。母線などのタグとシナリオのタグは同じ名前空間です [決定 3] |
| `LayerPackage.disp_tree`(`disp_tree.m:23`) | 既定の `sr_ignore = "Parameter"` のままでシナリオを表示します。行は `case1 @Scenario` |
| `LayerPackage.struct`(`struct.m`) | `a_Scenario` はこれまで `auxiliary` で `"out of target."` でした。`LayerPackage` になると再帰して `class`, `s_tag`, `a_PowerNetwork`(訪問済みのパス), `tab_disturbance`, `Time`, `Judge`, `Description`, `tab_parameter` を持ちます。関数ハンドルはそのまま入ります。`ResultPF` のスナップショット `struct(net, false)` にも入ります |
| `LayerPackage.table` | `tab_parameter`(空の表) |
| `LayerPackage.string` | `s_tag`。`Scenario/string.m` は削除 |
| `PowerSystemModel.gui`(`@PowerSystemModel/gui.m`) | `gui` を `LayerPackage` へ移し、`gui_content` の既定(空のページ)を `LayerPackage` に置きます [Q12]。`f_model` が `Scenario` の protected の `parent`, `children`, `gui_content` を読めるようにするためと、カードの「Open in new window」(`build_navigation.m:32`、`UserData.gui()`)がシナリオでも動くようにするためです |
| `DrawerModelGUI/render.m:76-85` | `build_parameter_tab` を `a_Parameter` を持つ物体だけで作ります(`isprop(a_target, "a_Parameter")`)。シナリオはパラメータのタブなしで、`gui_content` のページ(Disturbances: `tab_disturbance`、Settings: Time, Description, Judge)だけを表示します |
| `DrawerModelGUI/private/build_navigation.m:18` | `sv_kind` に `"Scenario"` を加え、`gui_palette.m` に色を加えます |
| `PowerNetwork.gui_content`(Summary の表) | `Item` に `"Scenario"` と個数を加えます |
| `PowerNetwork.export_csv` / `import_csv` | 変更なし(シナリオは書きません。シナリオは `Scenario.export_csv`) |
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

生成される `simulate` の項の形(`method_entry` が arguments ブロックから作る。`purpose` は省略):

```json
"PowerNetwork.simulate": {
  "inputs": [
    {"name":"obj","kind":"required","type":"PowerNetwork"},
    {"name":"s_scenario","kind":"required","type":[["string","choices=cellstr(string(obj.a_Scenario))"],["string"]]},
    {"name":"Solver","kind":"namevalue","type":["string","choices=cellstr([\"ode15s\",\"ode23t\"])"]},
    {"name":"Tolerance","kind":"namevalue","type":["double"]},
    {"name":"AbsoluteTolerance","kind":"namevalue","type":["double"]},
    {"name":"MaxStep","kind":"namevalue","type":["double"]},
    {"name":"InitialStep","kind":"namevalue","type":["double"]},
    {"name":"SeparateComplexParts","kind":"namevalue","type":["logical"]},
    {"name":"TimeLimit","kind":"namevalue","type":["double"]},
    {"name":"Progress","kind":"namevalue"},
    {"name":"Verbose","kind":"namevalue","type":["logical"]},
    {"name":"PlotFcn","kind":"namevalue"},
    {"name":"Export","kind":"namevalue"},
    {"name":"Format","kind":"namevalue","type":["string","choices=cellstr([\"GUILDAorigin\",\"struct\"])"]}
  ],
  "outputs": [{"name":"result"},{"name":"flag"},{"name":"output"}]
}
```

`remove_scenario` は `remove_branch` と同じ形、`add_scenario` は `From` の型 `Scenario` を持つ項になります。既定値のない引数は `purpose` に "Default:" が付かないので、ヘルプのコメントに "Default: GUILDA.setting." を書きます(上の arguments ブロックのとおり)。`test_F34_signatures` の「build or remove a model」の一覧に `add_scenario`, `remove_scenario` を加えます。

### 2.7 設定(`DefaultTimeSimulation.json`)[提案]

| キー | 変更 |
|---|---|
| `MaxStep` | 追加。`"Value": NaN`(ソルバーの既定)、type double |
| `InitialStep` | 追加。`"Value": NaN`、type double |
| その他(`Solver`, `Tolerance`, `AbsoluteTolerance`, `SeparateComplexParts`, `Progress`, `TimeLimit`, `Verbose`, `PlotFcn`) | 変更なし |
| `version` | 1 → 2(利用者の設定ファイルは INFO とともに既定に戻ります) |

`SolverOptions`(`matlab.ode.Options` を呼び出しか `sc.Options` で渡す)は削除します [Q6]。`MaxStep` と `InitialStep` が NaN でなければ `makeODE` が `o.SolverOptions.MaxStep` / `InitialStep` に入れます。NaN のときは何も設定しないので、既定の数値は現行と同じです。

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

`solve` は `PowerNetwork`、`Bus`、`Branch`、`Component`、制御器、`Scenario` の物体と、その `a_*` を一切読みません。読むのは引数と、ブロックのハンドルの呼び出しだけです。`ProgressODE` と MATLAB の `ode` は使います。

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
| `lv_busHasUnit` | logical, n_bus × 1 | 母線に機器があるか(島の検査は `simulate` で済ませるので、ソルバーは使いません。結果の確認用) |
| `rv_equilibrium` | double, n_var × 1 | 変数の行の平衡点(x, Vre, Vim, u, uc。`build_index.m:61-112` で組み立てている値) |
| `rv_Iequilibrium` | double, 2 n_bus × 1 | 母線電流の平衡点 `[Re; Im]` の並び(`c_Iequilibrium`)。現行と同じ値から始めるため(§8.3) |
| `c_comp` | cell, n_comp × 1 | 機器のブロック(下表)。`a_Bus` の順、各母線の `a_Component` の順 |
| `c_lc` | cell, n_lc × 1 | ローカル制御器のブロック。深さ優先(`get_variable_map` の順) |
| `c_gc` | cell, n_gc × 1 | グローバル制御器のブロック(`a_GlobalController` の順) |
| `sv_bus`, `sv_comp`, `sv_gc` | string 列 | メッセージと出力の列名だけに使うタグ。照合には使いません |

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
| `f_reconnect` | 発電機だけ | — | — | `@(V) comp.get_equilibrium(V,0,0,0)`。解列から戻るときの状態。発電機以外は `[]`(§4.1、Q10) |
| `s_tag` | ○ | ○ | ○ | メッセージ用 |

- `f_Mass` は `SolverODE` が `f_Mass([],[],[],[])` で 1 回評価します。大きさが合わないか評価に失敗すると `GUILDA:SolverODE:MassNotConstant`(ブロックの `s_tag` を本文に)で止まります。現行の `tools.read_mass` と同じ検査です。
- **ソルバーが表から作るもの:** `z` の並び(`[x; V; I; u; uc]`)、`iv_V`, `iv_I`, `iv_in`, `iv_lin`、入力の右辺 `rv_e`, `S_sig`, `S_var`、GC の入力のゲート(`iv_gateIn`, `iv_gateComp`)、質量行列。これは現行 `build_index.m:26-49, 130-160` の計算そのもので、`tab.Owner` との照合は、ブロックの行番号から作る「行 → ブロック」の対応に置き換えます(GC のゲートの `ismember(tab.Owner(...), string(a_gc))`、`build_index.m:148-151`)。

### 3.3 `build_index` の分割 [提案]

| 現行 `build_index.m` | 移す先 |
|---|---|
| 19, 164-192 `check_network` | `simulate`(`@PowerNetwork/private/check_simulation.m`) |
| 21-23, 66-125 モデルを読む部分(ハンドル、平衡点、`GconNoTarget`) | `simulate`(`@PowerNetwork/private/simulation_blocks.m`) |
| 26-58, 126-160 位置と接続の行列 | `SolverODE.build_index(sct_dae)`(引数を系統からデータへ) |

### 3.4 イベントの表し方(`sct_event`)[提案]

`Scenario.compile` を次のシグネチャに変えます。区間の分け方(`phase_table`, `getTimeSpan`)は現行のままで、出力をタグから位置にします。

```matlab
function [tab_phase, sct_event] = compile(obj, sct_dae)
    arguments (Input)
        obj                  % Scenario (validated against its network).
        sct_dae (1,1) struct % Blocks and maps of the run (positions of the units, buses, branches).
    end
    arguments (Output)
        tab_phase table      % output.phases: t1, t2, one logical column per disturbance tag.
        sct_event (:,1) struct  % One element per phase (below).
    end
```

時間は `obj.Time`、空なら外乱の時間幅から現行と同じ規則で決めます(`compile.m:69-78, 98-110`)。

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

- タグから位置への変換に使うのは `sct_dae.sv_bus`, `sv_comp`, `sv_gc` とブランチのタグ(`simulate` が `compile` に渡す `sct_dae` にだけ `sv_branch` を持たせ、ソルバーには渡しません)です。状態と入力の名前は `tab_variable` の `Owner` と `Name` で行に変えます(現行 `compile.m:194-242` の `comp.sv_x`, `comp.sv_u` の照合と同じ結果)。
- LC の解列は現行どおり不可(`UnknownTripUnit`)です。

### 3.5 初期値 `rv_x0` [決定 6(e)、提案]

`simulate` が作ります。

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

`phase_result` は `iv_tripComp`, `iv_tripGC` のブロックの `iv_x` を NaN にし、`I = Y*V` を記録します。タグの照合(`phase_result.m:15-21`)は位置に変わります。

### 4.4 島の検査 [提案]

現行 `check_islands(net, ...)`(`private/check_islands.m`)は `simulate` 側(`@PowerNetwork/private/check_islands.m` に移す)で、`compile` の後、積分の前に全区間を検査します。メッセージはブランチと母線のタグを示すので、モデル側が適しています。エラー ID は `GUILDA:PowerNetwork:OpenBranchIsland` に改名します(§6.3)。

## 5. 出力の約束

### 5.1 `sct_sol`(`Format="struct"` の最初の出力)[提案]

| フィールド | 型・大きさ | 内容 |
|---|---|---|
| `rv_t` | double, n_t × 1 | 時刻。区間の境界は 2 回(現行と同じ) |
| `rm_variable` | double, n_t × n_lin | 変数 x, Vre, Vim, u の値(`tab_variable` の先頭 n_lin 行の順)。解列中の状態は NaN |
| `rm_I` | double, n_t × 2 n_bus | 母線電流 Ire, Iim |
| `tab_variable` | table, n_lin × 7 | 列の意味(`simulate` が `sct_dae.tab_variable` の先頭 n_lin 行を入れる)[Q9] |
| `tab_phase` | table | `output.phases` と同じ |

`flag` と `output` は 2 番目、3 番目の出力です(どの `Format` でも同じ)。

### 5.2 `ResultODE` のコンストラクタ [提案]

`ResultPF(tab_powerflow, cm_Y, sct_network, sct_solver)` に揃えます。

```matlab
function obj = ResultODE(sct_sol, sct_network, sct_solver)
    arguments (Input)
        sct_sol     struct = struct()   % Raw solver data (section 5.1).
        sct_network struct = struct()   % Snapshot of the network: struct(net, false).
        sct_solver  struct = struct()   % solver, options, flag, output, elapsed.
    end
```

- `sv_bus`, `c_component` は `sct_network`(`a_Bus{i}.s_tag`、`a_Bus{i}.a_Component{j}.s_tag`)から、`c_index` は `tab_variable` の `Kind`, `Owner`, `Bus` から作ります(`get_variable_map` の `c_idxBus` を使わない)。`simulator_columns.m` の検査 `GUILDA:ResultODE:VariableMap` は不要になります。
- `ResultBase` には `[]` を渡し、`s_network` は `ResultODE` が設定します(`ResultPF` と同じ)。`a_PowerNetwork` は空です。
- 新しいプロパティ: `sct_network`(SetAccess=private)。
- **系統の参照が要る理由と最小案 [Q8]:** 結果のメソッド(`Plot`, `get_point`, `Export`, `odeResults`)は系統を読みません。読むのは `Scenario.out_of_step` の基準(スラック母線、慣性 `M`)だけです。`ResultPF` と揃えて `sct_network` のスナップショットを持ち、`out_of_step` はそこから `l_isSlack` と `tab_parameter.dynamics.M` を読みます。最小案は、スナップショットの代わりに `sv_slackBus` と機器ごとの `M` だけを持つことです。[未確認] `struct(net, false)` の時間(IEEE68 など)は計っていません。

### 5.3 `Format` と `Export` [提案]

| `Format` | 最初の出力 |
|---|---|
| `"GUILDAorigin"`(既定) | `ResultODE(sct_sol, struct(obj,false), sct_solver)` |
| `"struct"` | `sct_sol` |

`Export` は `ResultODE.Export` で書きます。`"struct"` のときは書き出しのためだけに `ResultODE` を作ります。

## 6. 削除・改名の一覧と移行

### 6.1 ファイル

| ファイル | 扱い |
|---|---|
| `_GUILDAsystem/_VersionSupport/v3_simulate_args.m` | 削除 |
| `_GUILDAsystem/_VersionSupport/ODEevent.m` | 削除 |
| `_GUILDAsystem/_auxiliary/@Scenario/copy.m` | 削除(`add_scenario(tag, From=sc)`) |
| `_GUILDAsystem/_auxiliary/@Scenario/string.m` | 削除(`LayerPackage.string`) |
| `_GUILDAsystem/_auxiliary/@SolverODE/get_options.m` | 削除(設定の合成は `simulate`) |
| `_GUILDAsystem/_auxiliary/@SolverODE/progress_mode.m` | `@PowerNetwork/private/progress_mode.m` へ移す |
| `_GUILDAsystem/_auxiliary/@SolverODE/private/validate_options.m`, `mustBeProgress.m` | 削除(arguments ブロック) |
| `_GUILDAsystem/_auxiliary/@SolverODE/private/check_islands.m` | `@PowerNetwork/private/` へ移す |
| `_GUILDAsystem/_auxiliary/@SolverODE/private/checkSimulationTime.m` | 削除(未使用、simulate-improvements ST2) [事実: 呼び出しなし] |
| `_GUILDAsystem/_auxiliary/@ResultODE/private/simulator_columns.m` | `tab_variable` から作る形に書き換え |
| `_GUILDAsystem/_auxiliary/@PowerSystemModel/gui.m` | `@LayerPackage/gui.m` へ移す [Q12] |

### 6.2 メンバー

| メンバー | 扱い |
|---|---|
| `Scenario.Options`, `set.Options` | 削除 |
| `Scenario.l_compat` | 削除 |
| `Scenario.copy` | 削除 |
| `Scenario(tag, opt)`(公開コンストラクタ) | `Scenario(net, s_tag)`、`Access={?PowerNetwork}` |
| `Scenario.validate(obj, net)` | `validate(obj)` |
| `Scenario.compile(c_scenario, net, time)`(Static) | `compile(obj, sct_dae)`(§3.4) |
| `Scenario.Ver` | 2.0 → 3.0、「1.x: ODEevent」の説明を削除 |
| `Scenario` の親クラス `auxiliary` | `LayerPackage` |
| `PowerNetwork.add_scenario(sc)` | `sc = add_scenario(s_tag, Time=, Description=, Judge=, From=)` |
| `PowerNetwork.simulate(time, sc..., NV)` | `simulate(s_scenario, NV)` |
| `PowerNetwork.children` | `a_Scenario` を含める |
| `SolverODE.OptionMap`, `get_options`, `progress_mode` | 削除 |
| `SolverODE.solve(net, time, c_events, sct_options)` | `solve(sct_dae, sct_event, rv_x0, sct_options)` |
| `SolverODE.build_index(net)` | `build_index(sct_dae)` |
| `SolverODE.set_admittance(ctx, sv_open, l_force)` | `set_admittance(ctx, iv_open, l_force)` |
| `ctx.net`, `ctx.c_comp{j}.comp`, `ctx.c_lc{k}.con`, `ctx.c_gc{k}.gc`, `ctx.sv_owner` | 削除(位置と `f_reconnect`) |
| `ResultODE(net, solver, options, flag, output, elapsed, c_phase)` | `ResultODE(sct_sol, sct_network, sct_solver)` |
| `ResultODE` の `a_PowerNetwork` | 空。`sct_network` を追加 |
| simulate の `SolverOptions` オプション | 削除 [Q6] |
| simulate の `MaxStep`, `InitialStep`, `Format` オプション | 追加 |
| `PhaseProbe`(`sct_options` のテスト用フィールド、`solve.m:86-88`) | 残す(テストは `solve` を直接呼ぶ、Q11) |

### 6.3 メッセージ

| ID | 扱い |
|---|---|
| `GUILDA:Deprecated:ODEevent`, `GUILDA:Deprecated:SimulateOptionName`(`Deprecated.xml`) | 削除 |
| `GUILDA:PowerNetwork:SimulateArguments` | 削除(arguments ブロック) |
| `GUILDA:PowerNetwork:SimulateTime` | 削除(呼び出しで時間を渡さない。`sc.Time` の検査は `mustBeSimulationTime`) |
| `GUILDA:PowerNetwork:ScenarioTimeConflict`, `ScenarioOptionConflict` | 削除(1 回に 1 つのシナリオ) |
| `GUILDA:PowerNetwork:NotScenario` | 削除(`add_scenario` はタグを受ける) |
| `GUILDA:Scenario:UnknownOption` | 削除 |
| `GUILDA:Scenario:OtherNetwork`, `ScenarioArray`, `DuplicateRunTag` | 削除(シナリオは常に系統の子、1 回に 1 つ) |
| `GUILDA:resolve_options:UnknownName`(simulate の経路) | MATLAB の arguments ブロックのエラーに変わる |
| `GUILDA:SolverODE:Stale`, `InputEdited`, `GconNoTarget`, `OpenBranchIsland` | `GUILDA:PowerNetwork:SimulateStale`, `SimulateInputEdited`, `GconNoTarget`, `OpenBranchIsland` に改名(モデル側の検査になるため。`msg` は呼び出し元のクラスの ID しか受け付けない、powerflow-structure と同じ理由) |
| `GUILDA:ResultODE:VariableMap` | 削除 |
| `GUILDA:SolverODE:MassNotConstant` | 追加(現行 `GUILDA:read_mass:NotConstant` の経路を置き換え) |
| `GUILDA:PowerNetwork:ScenarioNotFound` | 本文を「`simulate` のタグにも使う」形に。シナリオの一覧を示す |
| `GUILDA:PowerNetwork:ScenarioTagInUse` | 本文を「系統の子と重なる」に |

### 6.4 利用者の移行(v4-migration §1.11, §1.18 に書く内容)

| 旧 | 新 |
|---|---|
| `sc = Scenario("f"); sc.add_fault(...); net.add_scenario(sc)` | `sc = net.add_scenario("f", Time=[0 10]); sc.add_fault(...)` |
| `net.simulate([0 10], sc)` | `sc.Time = [0 10]; net.simulate("f")` |
| `net.simulate([0 10])`(外乱なし) | `net.add_scenario("free", Time=[0 10]); net.simulate("free")` |
| `net.simulate(t, sc1, sc2)` | 1 つのシナリオに外乱をまとめる: `net.add_scenario("both", From=sc1)` の後に `sc2` の外乱を足す |
| `sc.Options = struct("Tolerance",1e-6)` | 呼び出しで `net.simulate("f", Tolerance=1e-6)`、または `GUILDA.setting("TimeSimulation", Tolerance=1e-6)` |
| `SolverOptions=matlab.ode.options.ODE15s(MaxStep=0.01)` | `MaxStep=0.01` |
| `other.add_scenario(sc.copy())` | `other.add_scenario("f", From=sc)` |
| `ODEevent(tag, net, ...)` | `net.add_scenario(tag).add_disturbance(tag, ...)` |
| `simulate(..., "Reporter", v)` / `"RelativeTolerance", v` | `Progress=v` / `Tolerance=v` |
| `res.a_PowerNetwork` | `res.sct_network`(スナップショット)。系統そのものは呼び出し側の変数 |
| `net.solver_ODE.solve(net, time, events, options)` | `net.solver_ODE.solve(sct_dae, sct_event, rv_x0, options)`(上級者向け、データは §3) |

## 7. 実装の手順

各手順は 1 つのサブセッションの大きさです。各コミットで `DebugScript.run_all('Level','small','FailOnUnexpected',true)`、統合の前に medium を 1 回実行します。

| 手順 | 内容 | 主なファイル | テスト | 依存 |
|---|---|---|---|---|
| **S0** 基準の記録 | 軌道の比較用の基準を保存する(§8.3)。コードは変えない | `+DebugScript/+helper/simulate_baseline.m`(新規)、基準の MAT は作業用フォルダ(コミットしない) | 基準の作成だけ | なし |
| **S1** v3 の削除 | `v3_simulate_args.m`, `ODEevent.m`, `Deprecated.xml` の 2 項目, `Scenario.l_compat`, `simulate.m:83`、v4-migration の表 | `_VersionSupport/` の 2 ファイル, `Deprecated.xml`, `Scenario.m`(l_compat の 2 行), `simulate.m`(1 行) | F6「Deprecated option names still work」、F31「Compatibility」の節と `test_levels` の該当行を削除 | S0 |
| **S2** `Scenario` を `LayerPackage` に | §2.2-2.5: `add_scenario(tag)`, `remove_scenario`(delete), `From`, `children`, `log_edit` の上書き, `gui` の移動, GUI の描画, `disp_tree`, `import_csv` の `Network` 必須, `sig_methods` の add/remove | `@Scenario/*`(`compile.m`, `out_of_step.m` を除く), `@PowerNetwork/PowerNetwork.m`, `add_scenario.m`, `remove_scenario.m`, `gui_content.m`, `@LayerPackage/`, `@PowerSystemModel/gui.m`, `@DrawerModelGUI/`, `@GUILDA/update_keymap.m`, `functionSignatures.json`, `+DebugScript/+helper/scenario.m` | F31 の書き換え、F32/F33(GUI のシナリオのカード)、F24(タグの名前空間)、F34、新規: `disp_tree` にシナリオが出る、改名で何も stale にならない、`n_revOPF` が増えない、外したシナリオの `isvalid` が false | S1 |
| **S3** `ResultODE` をデータから | §5.2: 新しいコンストラクタ, `sct_network`, `simulator_columns` の書き換え, `out_of_step` のスナップショット読み | `@ResultODE/*`, `@Scenario/out_of_step.m`, `@SolverODE/solve.m`(231 行の 1 か所だけ。暫定で `net` から入力を作る) | F6 の結果の節、F31 の判定、I63(Export)、新規: 系統を消した後(`delete(net)`)も `Plot`, `get_point`, `judge` が動く | S1 |
| **S4** `simulate` の引数と設定 | §2.1, §2.7: タグの引数, arguments ブロック, 設定の合成, `Format`, `Scenario.Options` の削除, `MaxStep`/`InitialStep`, `SolverOptions` の削除, `get_options` 等の削除, `sig_methods` の simulate, 呼び出し元(`_GUILDAobject` のヘルプの例 20 ファイル、`_GUILDAverification` の 4 ファイル) | `simulate.m`, `@PowerNetwork/private/`(検証関数), `@SolverODE/SolverODE.m`, `get_options.m`, `progress_mode.m`, `private/makeODE.m`, `validate_options.m`, `mustBeProgress.m`, `@Scenario/Scenario.m`(Options), `export_csv.m`, `DefaultTimeSimulation.json`, `update_keymap.m`, `functionSignatures.json`, `+DebugScript/*`(simulate の呼び出し約 230 か所) | 全 simulate テストの書き換え、I54(時間の検査は `sc.Time` へ)、新規: 呼び出しの設定が設定ファイルを変えない、未知の名前のエラー、`Format="struct"`、タブ補完の choices | S2(`Scenario.m`, `update_keymap.m` が重なるため) |
| **S5** `SolverODE` のデータの約束 | §3, §4: `sct_dae` の収集, `compile` の位置化, 初期値, `check_islands` の移動, `build_index` の分割, `set_phase`/`set_admittance`/`initial_condition`/`getNextPhase`/`phase_result` の位置化, `solve` のシグネチャ, `S3` の暫定の除去 | `simulate.m`, `@PowerNetwork/private/`(収集), `@Scenario/compile.m`, `@SolverODE/*` | F6, F29, F35(`PhaseProbe` で `solve` を直接呼ぶ箇所)、I50-I64、§8.3 の軌道の一致、新規: `solve` が系統なしで動く(`sct_dae` だけで、`net` を `delete` した後に `solve` を呼ぶ) | S3, S4 |
| **S6** 文書 | `feature-simulation.html`(シーケンス図、SIM-xx の手順、オプション表)、`api-design.html`, `class-design.html`, Update log, `v4-migration.md`, `status.md`、ヘルプの `<@Examples>` の残り | `_GUILDAdoc/`, `notes/` | 文書の検査スクリプト(あれば) | S5(利用者向けの部分は S4 の後に並行可) |

**並行できる組 [提案]**

- S2 と S3 は並行できます(重なるファイルはありません。S3 は `@Scenario/out_of_step.m` だけ、S2 はそれ以外の `@Scenario/*`)。
- S3 と S4 も並行できます(S3 の `solve.m` は 231 行だけ、S4 は `solve.m` を触りません)。
- S6 の利用者向け(Tutorial 以外のページ、v4-migration)は S4 の後、S5 と並行できます。`feature-simulation.html` は S5 の後です。
- `_GUILDAtutorial/*.mlx` はチュートリアルの保留(#113)に含まれるため、この計画では変えません。

**注意(他の作業との重なり)**

- `refactor/powerflow-structure`(未統合)も `@PowerNetwork/private/` に `mustBeExport`, `mustBePlotFcn` を置く可能性があります。S4 の開始時に統合済みならそれを使い、未統合なら S4 で作り、後から統合する側が片方を消します。`ResultBase` は両方とも変えません。
- `update_keymap.m` と `functionSignatures.json` は S2 と S4 が触るので、S4 は S2 の統合後に始めます。

## 8. テスト計画

### 8.1 書き換える既存テスト [事実: grep の件数、基準コミット]

| 検索 | ファイル(件数) |
|---|---|
| `simulate(` | F6 (63), F31 (27), F3_initialize (13), I51 (13), I54 (13), F3_edit_handling (10), I60 (9), F30 (8), I61 (7), I63 (7), F29 (6), F7 (6), I64 (6), F35 (5), F8 (5), I53 (5), I55 (5), I56 (4), F22, F28, I105, I111, I50, I58 (各 2-3), その他 10 ファイル (各 1) |
| `Scenario(` | F29, F31, F36, F6, I53 |
| `add_scenario` | F31 (19), F29, F36, F6 |
| `ODEevent`, `l_compat` | F31, `test_levels.m:97` |
| `.Options` / `Options=` | F31 (66, 75, 325 行) |
| `solver_ODE.solve(` | F29 (52, 192 行), F35 (300 行) |
| `SolverOptions=` | F6 |

**補助関数:** 多くのテストは `DebugScript.helper.noop_event(net, tspan)` と `DebugScript.helper.scenario(tag, net, ...)` でシナリオを作り、`net.simulate(tspan, ev)` で実行します。S2 で `helper.scenario` を `net.add_scenario` に、S4 で `noop_event` が `Time=tspan` を設定する形にし、`net.simulate(tspan, ev)` を `net.simulate(ev.s_tag)` に置き換えます。時間が `noop_event` と違う呼び出し(`sc` を作った後で別の時間で実行する箇所)は `ev.Time = ...` を前に書きます。

### 8.2 新しいテスト

- タブ補完: `functionSignatures.json` の `PowerNetwork.simulate` の `s_scenario` が `choices=cellstr(string(obj.a_Scenario))`(F34)。
- `simulate("nope")` が `ScenarioNotFound` で止まり、本文にタグの一覧がある。
- 呼び出しの `Tolerance` が `result.options` に入り、`GUILDA.config("TimeSimulation","Tolerance")` は変わらない。与えない名前は設定の値。
- `MaxStep=1e-3` で出力の時間間隔が 1e-3 以下。`MaxStep` を与えない実行は基準と `isequaln`。
- `Format="struct"` の `rm_variable` が `Format="GUILDAorigin"` の `result.rm_variable` と `isequaln`。
- `Scenario` の改名・外乱の追加が `net.sct_stale` と `n_revOPF` を変えない。
- `disp_tree` の出力にシナリオの行がある。GUI のシナリオのカードとページ(F32/F33 の形で、表示を開いて閉じる)。
- `add_scenario` のタグが母線のタグと重なると `ScenarioTagInUse`。
- `remove_scenario` の後、その変数の `isvalid` が false。`From` で別の系統へ複製すると元は残る。
- `solve` が系統を読まない: `sct_dae` などを作った後で系統を `delete` し、`solve` が同じ結果を返す(S5、Q11 の取得方法による)。
- `ResultODE` が系統を読まない: 系統を `delete` した後で `Plot`, `get_point`, `odeResults`, `Export`, `sc.judge`(`Reference="slack"`, `"COI"`)が動く(S3)。

### 8.3 軌道が変わらないことの確認 [提案]

S0 で、基準コミットのコードで次の実行の `rv_t`, `rm_variable`, `rm_I`, `output.phases`, `flag` を MAT ファイルに保存します(作業用フォルダ、コミットしない)。

| 例 | 外乱 |
|---|---|
| IEEE68bus(既定) | B008 などの地絡 `[1, 1.07]`、`[0, 10]` |
| IEEE68bus(`LocalController=false`) | 外乱なし `[0, 5]`(t = 0 の停止の回帰) |
| IEEE14bus(AVR+PSS) | SG1B003 の解列 `[1, 1.2]`(再接続) |
| IEEE14bus | EL003 の開放 `[1, 3]` |
| IEEE9bus | オフセット(`delta` +0.1)と入力(`Pmech` 0.05、関数入力)|
| AGC 付きの系統(F18 の構成) | GC の解列、GC が観測する機器の解列 |

各手順の後に同じ実行をして比べます。

- **S1-S4:** 数値の経路を変えないので `isequaln` で一致することを求めます。`time` をシナリオの `Time` に移すだけです。
- **S5:** 評価の順序と初期値(`rv_Iequilibrium` を含む)を保つので、`isequaln` を目標にします。一致しない場合は差の最大値を記録し、`Tolerance` 以内で、原因(例: 行列の組み立ての順)を特定してから統合します。
- 比較は `DebugScript.helper.simulate_baseline(Mode="compare")` のように 1 つの関数で行い、F6 に常設はしません(基準の MAT をリポジトリに入れないため)。常設するなら、短い区間の小さな例で、基準値を数値でテストに書きます。

## 9. 利用者への問い

| # | 問い | 推奨 |
|---|---|---|
| Q1 | 呼び出しで時間を上書きできるようにするか(`simulate("f", Time=[0 5])`) | **しない。** 決定 1 の「時間はシナリオに」に従い、`sc.Time` を変えます。上書きを許すと、シナリオと実行の時間がずれる経路が残ります |
| Q2 | `Time` の既定 `[]`(外乱の時間幅から `[0, 30·ceil(tmax/10)]`、外乱なしは `[0, 10]`)を残すか、必須にするか | **残す。** 現行の規則とテストを保てます。外乱のないシナリオは `[0, 10]` になります |
| Q3 | `add_scenario` のタグが系統の子と重なったとき | **エラー(`ScenarioTagInUse`)。** 他の `add_*` の自動改名(`B001002` など)は、タグで `simulate` を呼ぶシナリオでは混乱を招きます。改名(`sc.s_tag = ...`)は他の層と同じ自動改名です |
| Q4 | `remove_scenario` でシナリオを `delete` するか | **する。** #119 と同じで、親のないシナリオの状態がなくなり、`OtherNetwork` の検査が要らなくなります |
| Q5 | 複製と移動の形 | **`add_scenario(tag, From=sc)`。** 別の系統へは複製、移動は複製と `remove_scenario`。`sc.copy()` は親のない物体を作るので廃止します |
| Q6 | `SolverOptions` を残すか | **削除し、`MaxStep` と `InitialStep` を設定に加える。** 決定 4 の「設定は GUILDA.setting」に合います。他のオプション(`MaxOrder` など)は要望が出たら設定に加えます |
| Q7 | `Progress` の true/false を残すか | **残す。** v3 互換ではなく現行の v4 の形で、テストが使っています |
| Q8 | `ResultODE` が持つ系統の情報 | **`ResultPF` と同じ `sct_network = struct(net, false)`。** `out_of_step` の基準に必要です。IEEE68 などで時間が問題なら、`sv_slackBus` と `M` だけを持つ最小案にします(S3 で計測) |
| Q9 | `Format="struct"` に `tab_variable` を含めるか | **含める。** 列の意味がないと生データを読めません(`calculate_powerflow` の `"powerflow(tab)"` が行名を持つのと同じ) |
| Q10 | 解列から戻る発電機の状態 | **`f_reconnect = @(V) comp.get_equilibrium(V,0,0,0)` を `simulate` が作って渡す。** 戻る時刻の電圧で決まるため前もって計算できません。モデルのメソッドを呼ぶクロージャですが、1 回の実行の間はパラメータが変わらないので結果は同じです。代わりに「解列の直前の状態から戻る」にすると動作が変わります |
| Q11 | テストが `solve` を直接呼ぶためのデータの取り方(F29, F35 の `PhaseProbe`) | **Hidden の `PowerNetwork.build_simulation_data(s_scenario)` を加え、`[sct_dae, sct_event, rv_x0, tab_phase]` を返す。** `simulate` もこれを使います。Name-Value の隠しオプションは `functionSignatures.json` に出るので避けます |
| Q12 | `gui` を `LayerPackage` に移すか | **移す。** シナリオのカードの「Open in new window」とページの表示に必要です。`Parameter` も `gui` を持ちますが、カードに出ないので影響はありません。[未確認] `PowerSystemModel` に `gui` を残し `Scenario` に別の `gui` を置く案もありますが、同じコードが 2 か所になります |
| Q13 | `Scenario.import_csv` の `Network` を必須にするか | **必須にする。** 系統のないシナリオがなくなるためです |
| Q14 | `Format="struct"` と `Export` を一緒に指定したとき | **書き出しのためだけに `ResultODE` を作る。** `calculate_powerflow` の判断と同じです |
