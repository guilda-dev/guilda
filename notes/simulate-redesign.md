# `simulate` と `SolverODE` の再設計(仕様)

ブランチは `docs/simulate-redesign-spec` です。調査の基準コミットは `9940b9d6` で、2026-11-12 の利用者の回答(§0.2-§0.5)を反映した版の基準は `514cde71`(`refactor/design-alignment`、潮流計算の再設計の統合を含む)です。**この文書は仕様で、コードは変えていません。** 問いはすべて閉じ(§0.5)、§7 の手順でサブセッションに分けて実装します。

**根拠の区別**

- **[事実]** 基準コミットのコードを読んで確認しました(行番号は `9940b9d6` のもの。`78cd96a1` でもこれらのファイルは変わっていません)。
- **[決定]** 利用者が 2026-11-12 に決めた方針と、§9 の問いへの回答です(§0)。
- **[提案]** この文書の提案で、決定の具体化です。
- **[要確認]** 利用者の確認を待つ提案です(§0.5 の時点で該当なし)。
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
| Q6 | **§0.4 で変更: `SolverOptions` は削除。** 以下は当初の回答: `SolverOptions` は残す(将来、Y 法を手本にした固定刻みの自作ソルバーを加える可能性がある)。`MaxStep` と `InitialStep` も設定に加え、呼び出しで上書きできるようにする | §2.1, §2.7, §3.1 |
| Q7 | `Progress` の true/false は残す | §2.1 |
| Q8 | `ResultODE` は `sct_network` のスナップショットを持つ | §5.2 |
| Q9 | `Format="struct"` はモデルの階層を写した struct(`sol.a_Bus{i}.a_Component{j}.x` など)で、各物体の応答は変数名を列名とする table。形は追加の回答(2026-11-12)で確定。出力 y は `ResultODE` だけが持つ(R1、§0.3) | §5.1, §5.3, §8.2, §9.2 |
| Q10 | `simulate` 側が `f_reconnect` を作って渡す | §3.2 |
| Q11 | Hidden の `PowerNetwork.build_simulation_data` を加える | §2.1, §7, §8 |
| Q12 | `gui` を `LayerPackage` に移す | §2.5 |
| Q13 | シナリオは系統と一緒に管理する。`PowerNetwork.import_csv` の読むフォルダに `scenario/` があれば、シナリオを `<タグ>.json` で読み、`export_csv` も書く。単独のシナリオの読み込み(`Scenario.import_csv`)はなくす | §1.7, §2.8, §6, §7, §8 |
| Q14 | `simulate` の `Export` オプションは削除。利用者は `result.export(...)` を呼ぶ。`ResultODE.Export` は `export` に改名(潮流計算の作業も同じ変更をする) | §1.6, §2.1, §5.4, §6, §7 |

### 0.3 追加の回答(2026-11-12)

| # | 回答 | 反映した節 |
|---|---|---|
| R1 | 出力 y は DAE の変数ではないので計算し直す。`ResultODE` のコンストラクタが計算してプロパティに持つ。`Format="struct"` は繰り返し実行の負担を減らすためのものなので、y を計算せず、`.y` も持たない | §5.2, §5.3, §8.2 |
| R2 | `Format="struct"` の table に `Time` の列は置かない。時間は `sol.t` だけ | §5.3 |
| R3 | **シナリオは関数ハンドルを一切持たない。** 持つのは外乱の種類、時間、対象、時系列のデータだけ。`Judge` を削除し、関数の `InputValue` は時系列のデータ(`[t, 値]`、`SolverODE` が補間)か一定値に置き換える。シナリオの JSON は単純なデータだけになり、`Judge` の項目、`ScenarioJudgeNotSaved`、`ScenarioFunctionHandle` はなくなる | §2.2, §2.4, §2.8, §2.9, §2.10, §3.4, §4.1, §6, §7, §8 |
| 改名 | `PowerNetwork.import_csv` → `PowerNetwork.import`、`export_csv` → `export`(データが CSV だけではなくなるため)。`import` は MATLAB の組み込み関数なので、実装の最初に R2026a で定義と呼び出しを確かめ、だめなら代わりの名前にする | §2.11, §6, §7, §8 |
| 説明 | `SolverOptions` とは何か、`Method` はあるか、の説明を加える | §2.1, §2.7 |

### 0.4 追加の決定(2026-11-12)

| # | 決定 | 反映した節 |
|---|---|---|
| SolverOptions | **`SolverOptions` を削除する**(Q6 の回答を取り消す)。`MaxStep` と `InitialStep` は設定のまま、呼び出しで上書きできる | §2.1, §2.6, §2.7, §3.1, §6, §8 |
| 停止条件 | 回転子角の差がしきい値を超えたら実行を止める `StopOnOutOfStep`(logical)と `StopAngle`([deg])を、設定と呼び出しの上書きで加える | §2.1, §2.7, §2.12, §3.2, §4.5, §8 |
| 出力の時刻 | 結果を一定の時間間隔で記録する `SampleTime` を、設定と呼び出しの上書きで加える。NaN か 0 はソルバーの刻み(既定) | §2.1, §2.7, §2.13, §5, §8 |
| R4 | 推奨どおり: IEEJ の検証スクリプトはローカル関数で CSV を読み、`add_scenario` と `add_disturbance` を呼ぶ | §2.8 |
| R5 | 推奨どおり。[事実] 潮流計算の作業(`514cde71` に統合)が `ResultBase` とすべての結果クラス(`ResultODE` を含む)の `Export` を `export` に改名済み | §1.6, §5.4, §7 |
| R6 | 推奨どおり: 判定は `ResultODE.judge_out_of_step` | §2.9 |
| R7 | 入力の時系列の補間は、外乱を加えるときに `Method` で選ぶ: `"zoh"`(0 次ホールド)、`"foh"`(1 次、線形)、`"spline"`。最後の点の後は値を保ち、時刻は外乱の開始から | §2.10, §2.8, §3.4, §4.1, §8 |
| R8 | 推奨どおり: 静的メソッド `import` を使えないときの代わりの名前は `import_network` / `export_network` | §2.11, §9.2 |
| R9 | 推奨どおり: `ResultODE` はコンストラクタで出力 y をいつも計算する。IEEE68 で遅ければ、初めて読んだときに計算する形に変える | §5.2, §9.2 |

### 0.5 最後の決定と実装の開始(2026-11-12)

| # | 決定 | 反映した節 |
|---|---|---|
| R10 | 推奨どおり: 停止条件の基準はスラック母線の発電機だけ | §2.12 |
| R11 | 推奨どおり: `StopOnOutOfStep` で止めたら `flag = 2`、`SimulationIncomplete` の警告は出さない | §2.1, §2.12 |
| R12 | 推奨どおり: `"zoh"` の各点を区間の境界にし、点の多い `"zoh"` が遅くなることをヘルプに書く | §2.10, §3.4 |

**問いはすべて閉じました。** この文書が実装の仕様です。実装は §7 の **S0(基準の記録)と S1(v3 の削除)** から始めます。

### 0.6 実装の状況

| 手順 | 状況 | コミット |
|---|---|---|
| S0 | 済(2026-11-12) | `da12bc4e`(`refactor/simulate-redesign-s1`) |
| S1 | 済(2026-11-12) | `938f3b81`(`refactor/simulate-redesign-s1`) |
| S2 | 済(2026-11-12) | `10c5e5ff`, `99d3e179`(`refactor/simulate-redesign-s2`、`22565858` で統合) |
| S3 | 済(2026-11-12) | `4434b396`, `c931880d`, `fac24132`(`refactor/simulate-redesign-s3`) |
| S4-S7 | 未着手 | |

- **S0:** `+DebugScript/+helper/simulate_baseline.m` を加えました。§8.3 の 6 例(IEEE68 の地絡 `[0,10]`、IEEE68 `LocalController=false` の外乱なし、IEEE14 AVR+PSS の母線 3 の発電機の解列、IEEE14 の 3 番目のブランチの開放、IEEE9 のオフセットと一定値の入力、F18 の構成の AGC 付き IEEE14 の GC の解列と観測機器の解列。いずれも `[0,5]`、IEEE68 の地絡だけ `[0,10]`)を計算し、`rv_t`, `rm_variable`, `rm_I`, `output.phases`, `flag` を `Mode="record"` で保存、`Mode="compare"` で `isequaln` で比べ、違えば例ごとに差の最大値を示します。タグは系統から読みます。API に触れるのはローカル関数 `new_scenario` と `run_case` だけで、S2-S6 はこの 2 つの数行を書き換えます。
- **基準:** `/Users/taku/GUILDA/simulate-baseline/baseline_s0.mat`(リポジトリの外、コミットしない)。基準のコードは `refactor/design-alignment` の `7bc4cd45`(`7bc4cd457b99f23e37b9f195f0e73a798c7f47f2`、MAT の `sct_meta.commit` にも記録)、R2026a。6 例とも `flag = 1`。
- **S1:** `v3_simulate_args.m`, `_VersionSupport/ODEevent.m`, `Deprecated.xml` の `SimulateOptionName` と `ODEevent`, `Scenario.l_compat`(と `Ver` の「1.x: ODEevent」の説明), `simulate.m` の `v3_simulate_args` の行を削除しました。テストは F6「Deprecated option names still work」、F31「Compatibility」の節と `test_levels` の行を削除し、F31 の最初の節の `ODEevent` は `DebugScript.helper.scenario` に置き換えました。§7 に挙げていなかった箇所: F10 の COMPAT フックの数(`simulate.m` 1 → 0、合計 15 → 14)、`add_disturbance.m` のヘルプの「deprecated ODEevent」、開発者ページ `feature-simulation.html`(ODEevent と `v3_simulate_args` の項目)と `folder-structure.html`(`_VersionSupport` の例)。旧名 `Reporter` などは `GUILDA:resolve_options:UnknownName` で止まります(v4-migration に記載)。`Scenario.Ver` の 3.0 への変更は S2 で行います。
- **確認:** S1 の後の `simulate_baseline(Mode="compare")` は 6 例すべて `isequaln`。small は S0 で 512 件(PASS 510 / KNOWN 1 / SKIP 1)、S1 で 511 件(PASS 509 / KNOWN 1 / SKIP 1)、FAIL 0。medium は S1 の後に 1 回、685 件(PASS 683 / KNOWN 1 / SKIP 1、FAIL 0)。
- **S3:** `ResultODE(sct_sol, sct_dae, sct_network, sct_solver)` をデータから作り、系統を参照しません(`a_PowerNetwork` は空、`sct_network` は `struct(net, false)`)。出力 `tab_output` / `rm_output` をコンストラクタで計算し(`private/output_trajectory.m`)、`odeResults` の `Y`、`export` の表の出力の列と MAT の `rm_output`, `tab_output` を加えました。`simulator_columns` は `tab_variable`, `tab_output`, `sv_bus`, `c_component` から列を作ります(`GUILDA:ResultODE:VariableMap` は削除)。`@Scenario/out_of_step.m` を `@ResultODE/judge_out_of_step.m` へ移し(`flag = 2` は角が `Threshold` を超えれば `"out-of-step"`、超えなければ `"incomplete"`)、スラック母線と慣性 `M` はスナップショットから読みます。メッセージ `NoRotorAngle`, `NoSlackGenerator`, `NoInertia`, `UnknownReference` を `GUILDA:ResultODE:` へ移しました。`SolverODE.solve` は暫定の `@SolverODE/private/result_data.m` で `net` から入力を作ります(S5 で `build_simulation_data` に置き換えて削除)。`_GUILDAverification` の 4 スクリプトと README の判定は `result.judge_out_of_step(...)`。テストは新規 F38(F31 の判定の 2 節を移し、`flag = 2`、`delete(net)` の後の動作、出力の値、判定のエラーを加えた)、I63 は出力の列。
- **S3 で仕様と違った点:**
  - 制御器の出力 `f_Y(t, x, V, u)` に uc が要りますが、uc の記録は S5(§4.3)の予定でした。S3 で `phase_result.m` を変え、全変数の行(x, Vre, Vim, u, uc)を記録します。`ResultODE.rm_variable` は従来どおり x, Vre, Vim, u だけです。
  - コンストラクタの入力に解列の情報がないため、状態が NaN のブロック(解列中の機器と GC)の出力を NaN にします。状態を持たない機器の解列は検出できません。
  - §6.3 の改名に `GUILDA:Scenario:UnknownReference` がありませんでしたが、`msg` の制約で `GUILDA:ResultODE:UnknownReference` にしました。
  - `struct(net, false)` はモデルの `f_*` のクロージャを含みます(「ハンドルなし」ではない)。
  - §5.4 の `ExportExtension` と既存の `GUILDA:ResultODE:ExportFormat` が重なります(S3 では変えていない)。
  - `Scenario.m` の静的メソッド `out_of_step` の宣言は S2 の統合の後に削除しました。`@Scenario/export_csv.m` は削除済みの `sc.Judge` を読みます(S6 でファイルごと削除)。
- **S3 の時間(R9、§5.2):** IEEE68 の地絡 `[0,10]`(648 時刻、出力 48 列)で、コンストラクタは 0.033-0.04 s(変更前のコンストラクタは約 0.05 s)、暫定の `result_data` は 0.03-0.06 s で、出力 y の計算は安いので遅延計算には変えません。**`struct(net, false)` は約 0.6 s で、`simulate` 全体が約 0.7 s から約 1.3 s になります。** スナップショットの作り方(または持ち方)は別に判断が要ります。
- **S3 の確認:** S2 の統合(`22565858`)の後、`simulate_baseline(Mode="compare")` は 6 例すべて `isequaln`。small は 514 件(PASS 512 / KNOWN 1 / SKIP 1、FAIL 0)、medium は 1 回、691 件(PASS 689 / KNOWN 1 / SKIP 1、FAIL 0)。

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

`Export` は `ResultBase` の約束です。`@ResultBase/ResultBase.m:85` が `varargout = Export(obj, varargin)` を宣言し、既定の `@ResultBase/Export.m` は `error_unsupported("Export")`(`GUILDA:ResultBase:Unsupported`)で止まります。`ResultPF`, `ResultOPF`, `ResultCPF`, `ResultODE` がそれぞれ `Export.m` で上書きし、`calculate_powerflow`, `calculate_optimal_powerflow`, `calculate_continuation_powerflow`, `simulate` が `Export` オプションから呼びます。共有の補助関数はありません。**したがって `ResultODE.Export` だけを `export` に改名すると、継承した `Export`(エラー)と `export` の両方が残ります。** 改名は `ResultBase` と全結果クラスで揃える必要がありました。

**`514cde71` での状態 [事実]:** 潮流計算の作業が、`ResultBase`(`@ResultBase/export.m`)と `ResultPF`, `ResultOPF`, `ResultCPF`, `ResultODE` の `Export` をすべて `export` に改名し、`calculate_powerflow` の `Export` オプションを削除しました。`simulate` には `Export` オプションが残り、`result.export(...)` を呼んでいます(`simulate.m:86, 95-98`)。この再設計で残るのは、`simulate` の `Export` オプションの削除だけです(§5.4)。

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
        opt.Tolerance (1,1) double {mustBeInRange(opt.Tolerance, 1e-15, 1e-3)}   % Relative error tolerance. Default: GUILDA.setting.
        opt.AbsoluteTolerance (1,1) double {mustBeInRange(opt.AbsoluteTolerance, 1e-15, 1e-3)}   % Absolute error tolerance. Default: GUILDA.setting.
        opt.MaxStep (1,1) double {mustBePositiveOrNaN}   % [s] Largest step of the solver; NaN for the solver default. Default: GUILDA.setting.
        opt.InitialStep (1,1) double {mustBePositiveOrNaN}   % [s] First step of each phase; NaN for the solver default. Default: GUILDA.setting.
        opt.SeparateComplexParts (1,1) logical   % SeparateComplexParts of the ode object. Default: GUILDA.setting.
        opt.SampleTime (1,1) double {mustBeNonnegative}   % [s] Interval of the recorded times; NaN or 0 for the solver steps. Default: GUILDA.setting.
        opt.StopOnOutOfStep (1,1) logical   % Stop the run when a rotor angle from the reference exceeds StopAngle. Default: GUILDA.setting.
        opt.StopAngle (1,1) double {mustBePositive}   % [deg] Threshold of StopOnOutOfStep. Default: GUILDA.setting.
        opt.TimeLimit (1,1) double {mustBePositive}   % [s] Wall-clock limit of the whole run; Inf for none. Default: GUILDA.setting.
        opt.Progress {mustBeProgress}   % "dialog", "disp" or "none" (true: "dialog", false: "none"). Default: GUILDA.setting.
        opt.Verbose (1,1) logical   % Print the phases and the outcome. Default: GUILDA.setting.
        opt.PlotFcn {mustBePlotFcn}   % Live display during the run: "none". Default: GUILDA.setting.
        opt.Format (1,1) string {mustBeMember(opt.Format, ["GUILDAorigin","struct"])} = "GUILDAorigin"   % Form of the first output.
    end
    arguments (Output)
        result   % ResultODE (Format "GUILDAorigin") or a struct that mirrors the model hierarchy, with tables (Format "struct").
        flag     % 1 completed, 2 stopped by StopOnOutOfStep, 0 stopped by TimeLimit, -1 stopped by the solver.
        output   % Details: message, tEnd, phases, nPhases, nPhasesDone, isSparse, exception, outOfStep.
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
  for s_name = setdiff(string(fieldnames(opt)).', ["Time","Format"])
      sct_options.(s_name) = opt.(s_name);      % this call only
  end
  sct_options.Progress = progress_mode(sct_options.Progress);   % true/false -> "dialog"/"none"
  ```

  `TimeLimit` の設定値が正でないときは `Inf` にします(現行 `get_options.m:38-40` と同じ)。設定ファイルの値は `GUILDA.setting` の検査(type、options)に任せます。
- **`MaxStep`, `InitialStep` の優先順位:** 呼び出しの値 > `GUILDA.setting` の値 > ソルバーの既定(設定が NaN のとき)。
- **`Solver` と、`SolverOptions` も `Method` もないこと [決定 §0.4、説明]:**
  - `Solver` は積分のアルゴリズムを選びます(`"ode15s"` / `"ode23t"`)。潮流計算の再設計と同じく「`Solver` = アルゴリズム」の規則です。
  - `SolverOptions`(MATLAB の `matlab.ode.Options` オブジェクトを渡すオプション)は削除します。そのうち使われていた刻みの設定は `MaxStep` と `InitialStep` として、設定ファイルに保存でき、呼び出しで上書きできます。`MaxOrder`、`BDF` など、ほかのソルバー固有の設定は受けません(要望が出たら設定として加えます)。これで、同じ設定を 2 か所から与える重なりはなくなります。
  - `simulate` に別の `Method` オプションはありません。`Method` という名前は `initialize` の平衡点の求め方と、入力の時系列の補間(§2.10)に使います。
- **将来の固定刻みソルバー:** Y 法を手本にした自作ソルバーを加えるときは、`Solver` の選択肢を増やし、`SolverODE.solve` の中で `ode` オブジェクトの代わりにそのソルバーを使います。`sct_dae` などのデータの約束(§3)は MATLAB の `ode` に依存しないように作るので、モデル側の変更は要りません。そのソルバーの設定(刻み幅など)は、TimeSimulation の設定として加えます。
- **検証関数の置き場所 [提案]:** `mustBeScenarioOf`、`mustBePositiveOrNaN`、`mustBeProgress`、`mustBePlotFcn` は `@PowerNetwork/private/` に置きます。`mustBeSimulationTime` は今 `@Scenario/private/` にあり、`PowerNetwork` からは呼べないので、`_GUILDAsystem/_auxiliary/SystemTools/` 直下へ移して両方から使います。[事実] `mustBePlotFcn` は `calculate_powerflow.m:151` のローカル関数として統合済みです。`simulate` も使うので、S4 で `@PowerNetwork/private/mustBePlotFcn.m` に移して共有します。
- **`mustBeScenarioOf` のエラー [提案]:** `GUILDA:PowerNetwork:ScenarioNotFound`(既存のキー)。本文に系統のシナリオのタグを最大 10 個並べ、`net.add_scenario` を案内します。シナリオがない系統では「`net.add_scenario("name")` で作る(`Time` の既定は `[0, 10]`)」と案内します。
- **`output` の内容**は現行と同じです(`message`, `tEnd`, `phases`, `nPhases`, `nPhasesDone`, `isSparse`, `exception`)。`output.phases` の列名は外乱のタグです。
- **警告:** `flag` が 0 か -1 のとき `GUILDA:PowerNetwork:SimulationIncomplete` を出すのは現行と同じです。`flag = 2`(`StopOnOutOfStep` で止めた)は利用者が求めた停止なので警告しません(§2.12)。
- **`Export` オプションは削除 [決定 Q14]。** 書き出しは `result.export(...)` です(§5.4)。
- **停止条件と出力の時刻:** `StopOnOutOfStep`, `StopAngle` は §2.12、`SampleTime` は §2.13 です。

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
- `Judge` の引数はありません [決定 R3]。判定は結果に対して行います(§2.9)。

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
    % remove_disturbance: unchanged signatures; add_input, add_disturbance: InputValue is data (section 2.10)
    % judge, out_of_step: removed (section 2.9)
    % compile: new signature (section 3.4)
end
```

- **作り方は `add_scenario` だけ** [提案]。コンストラクタは `Access={?PowerNetwork}` です(#119 のモデルの物体と同じ)。`Scenario("x")` の直接の作成は `MATLAB:class:MethodRestricted` になります。
- **`Time` [決定 Q2]:** 既定は `[0, 10]` で、空は許しません。外乱の時間幅から決める規則(`compile.m:69-78`、`private/getTimeSpan.m` の時間が空の分岐)はなくします。時間の外にある外乱の警告 `GUILDA:Scenario:OutsideTimeSpan` は残します。
- **関数ハンドルを持たない [決定 R3]。** シナリオが持つのは、外乱の種類、時間、対象(タグと状態・入力の名前)、値(数値、時系列)と、`Time`, `Description` だけです。`struct(net, false)` と JSON にそのまま書けます。
- **削除:** `Judge`, `judge`, `out_of_step`(§2.9)、関数の `InputValue`(§2.10)、`Options`, `set.Options`, `l_compat`, `copy`, `string.m`(`LayerPackage.string` と同じ)、`import_csv`, `export_csv`(§2.8)、`validate(obj, net)` の `net` 引数。`validate` は `obj.a_PowerNetwork` に対して検査します。
- **改名:** `sc.s_tag = "new"` は `LayerPackage.set.s_tag` を通り、兄弟と重なれば番号を足します(他の層と同じ)。`log_edit` は何もしないので、`PowerNetwork.handle_edit` の `n_revOPF`(タグの編集で増える、`@PowerNetwork/handle_edit.m:66`)も増えません。
- **`LayerPackage.log_edit` の上書き [提案]:** `log_edit` は `LayerPackage` の protected メソッド(`@LayerPackage/LayerPackage.m:74`)なので、`Scenario` が同じ名前の protected メソッドを定義して上書きします。[未確認] `set.s_tag` からの呼び出しが `Scenario` 版になることは、実装時に確かめます。

### 2.5 `children` を使う箇所の扱い [提案]

`PowerNetwork.children` を `[a_Bus; a_Branch; a_GlobalController; a_Scenario; a_Parameter]` にします(`@PowerNetwork/PowerNetwork.m:213-215`)。

| 使う箇所 | 扱い |
|---|---|
| `LayerPackage.set.s_tag`(`LayerPackage.m:88-106`) | シナリオも兄弟になります。母線などのタグとシナリオのタグは同じ名前空間です [決定 3] |
| `LayerPackage.disp_tree`(`disp_tree.m:23`) | 既定の `sr_ignore = "Parameter"` のままでシナリオを表示します。行は `case1 @Scenario` |
| `LayerPackage.struct`(`struct.m`) | `a_Scenario` はこれまで `auxiliary` で `"out of target."` でした。`LayerPackage` になると再帰して `class`, `s_tag`, `a_PowerNetwork`(訪問済みのパス), `tab_disturbance`, `Time`, `Description`, `tab_parameter` を持ちます。関数ハンドルはありません [決定 R3]。`ResultPF` と `ResultODE` のスナップショット `struct(net, false)` にも入ります |
| `LayerPackage.table` | `tab_parameter`(空の表) |
| `LayerPackage.string` | `s_tag`。`Scenario/string.m` は削除 |
| `PowerSystemModel.gui`(`@PowerSystemModel/gui.m`) | `gui` を `LayerPackage` へ移し、`gui_content` の既定(空のページ)を `LayerPackage` に置きます [決定 Q12]。`f_model` が `Scenario` の protected の `parent`, `children`, `gui_content` を読めるようにするためと、カードの「Open in new window」(`build_navigation.m:32`、`UserData.gui()`)がシナリオでも動くようにするためです。`Parameter` も `gui` を持ちますが、カードに出ないので影響はありません |
| `DrawerModelGUI/render.m:76-85` | `build_parameter_tab` を `a_Parameter` を持つ物体だけで作ります(`isprop(a_target, "a_Parameter")`)。シナリオはパラメータのタブなしで、`gui_content` のページ(Disturbances: `tab_disturbance`、Settings: Time, Description)だけを表示します |
| `DrawerModelGUI/private/build_navigation.m:18` | `sv_kind` に `"Scenario"` を加え、`gui_palette.m` に色を加えます |
| `PowerNetwork.gui_content`(Summary の表) | `Item` に `"Scenario"` と個数を加えます |
| `PowerNetwork.export` / `import`(旧 `export_csv` / `import_csv`、§2.11) | `scenario/` サブフォルダを読み書きします(§2.8) |
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
    {"name":"Tolerance","kind":"namevalue","type":["double"]},
    {"name":"AbsoluteTolerance","kind":"namevalue","type":["double"]},
    {"name":"MaxStep","kind":"namevalue","type":["double"]},
    {"name":"InitialStep","kind":"namevalue","type":["double"]},
    {"name":"SeparateComplexParts","kind":"namevalue","type":["logical"]},
    {"name":"SampleTime","kind":"namevalue","type":["double"]},
    {"name":"StopOnOutOfStep","kind":"namevalue","type":["logical"]},
    {"name":"StopAngle","kind":"namevalue","type":["double"]},
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

### 2.7 設定(`DefaultTimeSimulation.json`)[決定 Q6, §0.4、提案]

| キー | 変更 | `Type` | `Value` | `Description` |
|---|---|---|---|---|
| `MaxStep` | 追加 | `double` | `NaN` | "[s] Largest step of the solver; NaN for the solver default" |
| `InitialStep` | 追加 | `double` | `NaN` | "[s] First step of each phase; NaN for the solver default" |
| `SampleTime` | 追加 | `double` | `NaN` | "[s] Interval of the recorded times on a uniform grid from the start time; the start and end of each phase are also recorded. NaN or 0 records the steps of the solver" |
| `StopOnOutOfStep` | 追加 | `logical` | `false` | "Stop the simulation when the rotor angle of a generator from the generator of the slack bus exceeds StopAngle (flag = 2)" |
| `StopAngle` | 追加 | `double` | `360` | "[deg] Threshold of StopOnOutOfStep: largest allowed absolute rotor angle from the reference" |
| その他(`Solver`, `Tolerance`, `AbsoluteTolerance`, `SeparateComplexParts`, `Progress`, `TimeLimit`, `Verbose`, `PlotFcn`) | 変更なし | | | |
| `version` | 1 → 2(利用者の設定ファイルは INFO とともに既定に戻ります) | | | |

- `makeODE` は `MaxStep` / `InitialStep` が NaN でなければ `o.SolverOptions` のそのフィールドに入れます。NaN のときは何も設定しないので、数値は現行と同じです。`SolverOptions` を受け取る分岐(`makeODE.m:23-25`)は削除します。
- `StopAngle` の既定 360 は、判定 `judge_out_of_step` の `Threshold` の既定と同じです。
- [未確認] JSON の `NaN` の読み書き(`TimeLimit` の `Infinity` と同じく `jsondecode` が受けるか)と、`GUILDA.setting` の画面での NaN の入力は、実装時に確かめます。

### 2.8 シナリオのファイル(`scenario/<タグ>.json`)[決定 Q13、提案]

`PowerNetwork.import_csv` / `export_csv` は `import` / `export` に改名します(§2.11)。この節は新しい名前で書きます。

**フォルダ:** `PowerNetwork.export(path)` が書くフォルダに `scenario/` を加えます。

```
<path>/network/parameter.csv
<path>/bus/parameter.csv
<path>/branch/parameter.csv
<path>/component/<key>/main.csv, dynamics.csv, opf.csv
<path>/scenario/<scenario tag>.json      ← 追加: シナリオ 1 つに 1 ファイル
```

- `export` は `net.a_Scenario` の各シナリオを `scenario/<s_tag>.json` に書きます。シナリオがなければ `scenario/` を作りません。`Overwrite=true` で消すサブフォルダに `scenario` を加えます(`export_csv.m:57`)。タグは `isvarname` なので、そのままファイル名に使えます。
- `import(path, ...)` は、母線・ブランチ・機器を作った後、`initialize` の前に、`scenario/*.json` を名前の順に読み、`net.add_scenario(<ファイル名>, Time=, Description=)` で作ってから外乱を足します。外乱の検査(タグがこの系統にあるか)は `add_disturbance` と同じです。JSON の構文と項目の検査は、ほかの表と同じく系統を変える前に行います。外乱のタグの検査は機器を作った後でないとできないので、そこで失敗すると系統は途中まで作られた状態で止まります(現行 `import_csv` の説明「A later failure ... can leave obj partly built」と同じ扱い)。
- **同梱の系統:** 同梱の系統クラスはコンストラクタで `import(..., Network=obj)`(現行 `import_csv`)を呼ぶので、そのフォルダに `scenario/` を置けば、系統を作るとシナリオも付きます。
- **順序:** シナリオの順(`a_Scenario`)はファイル名の順になり、追加した順は保存しません。
- **単独の読み込みはなくします。** `Scenario.import_csv` と `Scenario.export_csv` は削除し、読み書きは `@PowerNetwork/private/read_scenarios.m`・`write_scenarios.m`(`Scenario` の `to_json_struct` / `add_from_json_struct` を呼ぶ)にします。

**JSON の内容 [提案、R3 で関数ハンドルを除いた形]**

```json
{
  "Format": "GUILDAscenario",
  "version": 1,
  "Description": "fault B008, EL003 opened",
  "Time": [0, 20],
  "Disturbances": [
    {"Tag": "fault",  "TimeSpan": [0.10, 0.17], "FaultBus": ["B008"]},
    {"Tag": "open",   "TimeSpan": [0.17, 20],   "OpenBranch": ["EL003"]},
    {"Tag": "trip",   "TimeSpan": [1, 2],       "TripUnit": ["B002SG1"]},
    {"Tag": "offset", "TimeSpan": 0,            "OffsetUnit": "B001SG1", "OffsetState": ["delta"], "OffsetValue": [0.1]},
    {"Tag": "step",   "TimeSpan": [1, 1.5],     "InputUnit": "B002SG1", "InputName": ["Pmech", "Vfield"], "InputValue": [0.05, 0.01]},
    {"Tag": "ramp",   "TimeSpan": [2, 4],       "InputUnit": "B002SG1", "InputName": ["Pmech"],
     "InputValue": {"Time": [0, 1, 2], "Value": [[0], [0.05], [0.05]], "Method": "foh"}}
  ]
}
```

- タグはファイル名だけに持ち、JSON には書きません(2 か所で食い違わないため)。
- `Disturbances` の各要素は `add_disturbance` の Name-Value と同じ名前で、空の項目は書きません。読むときは要素ごとに `sc.add_disturbance(Tag, 項目...)` を呼びます。リストは 1 つでも配列で書き、読むときは `string(...)` で列にします(`jsonencode` の 1 要素の扱いに依らないため)。
- `InputValue` は、一定値なら数値の配列(入力名ごとに 1 つ)、時系列なら `Time`, `Value`, `Method`(補間、§2.10。省くと `"foh"`)を持つオブジェクトです。形で区別できるように、時系列を数値の 2 次元配列だけで書く形は使いません(`jsondecode` は 1 行の 2 次元配列とベクトルを区別しにくいため)。
- 関数ハンドルを書く場面はありません [決定 R3]。`Judge` の項目もありません。
- 未知の項目(古いファイルの `Judge` を含む)は警告(`GUILDA:import:UnknownScenarioField`)して無視します(CSV の未知の列と同じ)。`version` が読める値より大きければ止めます。

**`_GUILDAverification` への影響 [決定 R4]:** IEEJ の比較スクリプト 3 つは、1 つの CSV の多数のシナリオを `Scenario.import_csv` で読んでいます(§1.7)。単独の読み込みがなくなるので、(a) それぞれの CSV を同梱の系統のフォルダの `scenario/<tag>.json` に変換するか、(b) スクリプト内の小さな読み込み関数(`_GUILDAverification` のローカル関数で、GUILDA の API ではない)で CSV から `add_scenario` と `add_disturbance` を呼ぶか、のどちらかにします。(b) にします。検証の表は 1 つの CSV のほうが比べやすく、(a) では同梱の系統を作るたびに数十のシナリオが付くためです。

### 2.9 判定(安定・脱調)[決定 R3、提案]

`Scenario.Judge` と `sc.judge(result)` を削除し、判定は結果のメソッドにします。

```matlab
verdict = result.judge_out_of_step(Reference="slack", Threshold=360)
```

- 中身は現行の `Scenario.out_of_step(result, opt)`(`@Scenario/out_of_step.m`)そのもので、引数と出力の struct(`Verdict`, `Time`, `Units`, `MaxAngle`, `Reference`, `Threshold`)も同じです。基準のスラック母線と慣性 `M` は `sct_network` のスナップショットから読みます(§5.2)。
- **推奨は `ResultODE` のメソッド**です。理由: 判定が読むのは結果だけ(回転子角の軌道とスナップショット)で、シナリオのデータを読みません。シナリオから関数ハンドルをなくすと、判定をシナリオに置く理由もなくなります。`Scenario.out_of_step` のような静的メソッドで残すと、シナリオのクラスに結果を読む処理が残ります。
- 別の判定(IEEJ の比較の `judge_table4_5` など)は、利用者の関数 `v = my_judge(result)` を呼ぶだけです。GUILDA に登録の仕組みは設けません。
- メソッドの名前は §9.2 の R6 で確認します(`judge_out_of_step` を推奨。`api-design` の動詞_名詞の形)。

**`sc.Judge` / `sc.judge` を使う箇所 [事実]**

| 箇所 | 使い方 | 移行 |
|---|---|---|
| `@Scenario/judge.m`, `Scenario.m:89, 116, 146` | 定義 | 削除 |
| `@Scenario/out_of_step.m` | 既定の `Judge` | `@ResultODE/judge_out_of_step.m` へ移す |
| `@Scenario/copy.m:12` | 複製 | `copy` ごと削除 |
| `@Scenario/export_csv.m:49` | 既定以外の `Judge` を警告 | `export_csv` ごと削除 |
| `+DebugScript/test_F31_scenario.m:235, 242, 267, 270-271` | `sc.judge(r)`、利用者の `Judge` | `r.judge_out_of_step()` と利用者の関数の直接の呼び出しに |
| `_GUILDAverification/IEEJ_EAST10/compare_table4_3.m:73` | `sc.judge(result)` | `result.judge_out_of_step()` |
| `_GUILDAverification/IEEJ_EAST30/compare_table4_9.m:80, 83, 87` | `sc.Judge = @(r) Scenario.out_of_step(r, Reference=..., Threshold=360)` | `result.judge_out_of_step(Reference=s_ref, Threshold=360)` |
| `_GUILDAverification/IEEJ_WEST10/compare_table4_5.m:61, 70` | `sc.Judge = @judge_table4_5` | `v = judge_table4_5(result)`(関数の中の `Scenario.out_of_step` も `result.judge_out_of_step`) |
| `_GUILDAverification/IEEJ_WEST30/compare_table4_13.m:91` | `sc.judge(result)` | `result.judge_out_of_step()` |
| ヘルプの例(`Scenario.m`, `ResultODE.m`, `simulate.m`)、`feature-simulation.html`、`v4-migration.md` §1.18 | 説明 | 書き換え |

### 2.10 入力の時系列(`InputValue`)[決定 R3, R7、提案]

関数の `InputValue`(`@(t) ...`)をなくし、一定値か時系列のデータにします。

| 形 | `add_input(unit, name, value, [t1 t2])` の `value` | 意味 |
|---|---|---|
| 一定値 | 数値のベクトル(入力名ごとに 1 つ。1 つなら全部に共通、現行どおり) | `[t1, t2]` の間、入力に足す一定値(ステップ) |
| 時系列(行列) | `n × (1 + n_name)` の数値行列 `[t, v_1, ..., v_n]` | 1 列目は外乱の開始 `t1` からの時刻 [s](現行の関数の引数と同じ基準) |
| 時系列(table) | 変数 `Time` と入力名の変数を持つ table | 列は名前で対応させます(順は問わない) |

- **時刻の条件:** `t` は有限で狭義に増加し、`t(1) = 0` です。違えば `GUILDA:Scenario:InvalidInputSeries` で止まります。
- **補間の選択 [決定 R7]:** 時系列を加えるときに `Method` で選びます。

  ```matlab
  s_tag = sc.add_input(unit, name, value, time, Method="foh", Tag="")
  sc.add_disturbance(tag, InputUnit=..., InputName=..., InputValue=..., InputMethod="foh", TimeSpan=...)
  ```

  | `Method` | 点の間 | 連続性 |
  |---|---|---|
  | `"zoh"` | 0 次ホールド: 次の点まで前の点の値 | 各点で値が飛ぶ |
  | `"foh"`(既定) | 1 次: 線形補間 | 値は連続、傾きが各点で飛ぶ |
  | `"spline"` | 3 次スプライン(`griddedInterpolant` の `"spline"`) | 値と傾きが連続 |

  - 既定は `"foh"` です(値が連続で、元の関数を標本にしたときに最も素直な近似のため)。
  - どの方法も、最後の点より後は最後の値を保ち(`t2` まで)、時刻は外乱の開始からです。
  - 一定値(時系列でない `value`)には `Method` は効きません。`Method` を一定値に与えても無視せず、`GUILDA:Scenario:MethodWithoutSeries` で止めます(誤解を防ぐため)。
  - `"spline"` の点が 2 つのときは線形と同じです。
- **`tab_disturbance` の列:** `InputMethod`(string)を加え、列は 12 になります(`InputValue` の後)。一定値の行は `""` です。
- **`tab_disturbance` での持ち方:** `InputValue` の列のセルに、一定値は数値の列、時系列は `[t, v]` の行列で入れます(table で渡したものも行列にする)。関数ハンドルは入りません。
- **`zoh` の飛びと区間の境界 [提案]:** `"zoh"` の各点(最初の点を除く)では入力が飛ぶので、`compile` がその時刻を**区間の境界**にします。区間の中では入力が一定になり、可変刻みのソルバーが区間の中の飛びに出会いません。境界では、ほかの外乱の境界と同じく代数変数だけを解き直します(§4.2)。境界の時刻は `tab_phase` の行になり、外乱の列は変わりません(同じ外乱が続く)。点の多い `"zoh"` は区間が増えて遅くなるので、ヘルプにそう書きます。`"foh"` と `"spline"` は値が連続なので境界を加えません。
- **`compile` の出力との対応:** 現行は `event2fhandle`(`compile.m:245-259`)が値や関数を「区間の開始からの時刻の関数」にし、同じ入力の複数の外乱を関数の和にして `c_Uoffset{j}` に入れます(`compile.m:225-238`)。新しい `compile` は関数を作らず、`sct_event(k).c_input` に入力の行ごとのデータを入れます(§3.4)。
  - 一定値は 1 点の時系列 `t = 0`, `v` とします。
  - 区間の開始からの時刻に直すため、`t` から `ts = 区間の開始 - 外乱の開始` を引きます(現行の `exV(t+ts)` と同じずらし)。
  - 同じ入力の複数の外乱は、`c_input` の要素を外乱ごとに分けたまま渡し、`SolverODE` が評価した値を足します(補間の方法が外乱ごとに違ってもよいため)。
- **`SolverODE` での評価:** 区間の開始で `c_input` の要素ごとに補間のオブジェクトを 1 回作り、右辺で `e(iv_row) += F(t)` とします(現行 `getODEFunction.m:77-80` の関数の呼び出しの置き換え)。`"foh"` は `griddedInterpolant(t, v, "linear", "nearest")`、`"spline"` は `griddedInterpolant(t, v, "spline", "nearest")`(範囲外は端の値。`"nearest"` の外挿で最後の値を保つ)、`"zoh"` は区間の中で一定なので、区間の開始の値を定数として足します。右辺のヤコビアンには入りません(現行と同じ。入力は時刻だけの関数)。
- **JSON:** 一定値は数値の配列、時系列は `{"Time": [...], "Value": [[...], ...], "Method": "foh"}`(`Value` は時刻ごとの行。`Method` を省くと `"foh"`)です(§2.8)。
- **数値の違い:** 関数を時系列にした計算は、標本の取り方の分だけ現行と違います。線形の関数(例 `@(t) 0.01*t`)は `"foh"` の 2 点の時系列で表せますが、補間の丸めの分だけ一致しないことがあります(§8.3)。

### 2.11 `import_csv` / `export_csv` の改名 [決定、提案]

`PowerNetwork.import_csv(path, opt)`(Static)を `PowerNetwork.import(path, opt)` に、`net.export_csv(path, opt)` を `net.export(path, opt)` に改名します。データが CSV だけではなくなる(§2.8 の JSON)ためです。引数と動作は §2.8 の追加のほかは変えません。

**最初の確認(S6 の最初のコミットの前)[未確認]:** `import` は MATLAB の組み込み関数です(`which import` は `built-in (.../toolbox/matlab/general/import)`、`iskeyword('import')` は 0)。S6 は R2026a で次を確かめてから改名します。

1. `classdef` の `methods (Static)` に `net = import(path, opt)` を宣言でき、`@PowerNetwork/import.m` に定義できる。
2. コマンドウィンドウとスクリプトで `net = PowerNetwork.import(path)` が静的メソッドを呼ぶ。
3. ほかの GUILDA の関数の中(`import` 文を使う関数を含む)と、同梱の系統クラスのコンストラクタの中の `PowerNetwork.import(path, Network=obj)` が静的メソッドを呼び、パッケージの `import` 文と衝突しない。
4. `functionSignatures.json`、`doc`、ヘルプの生成が `PowerNetwork.import` を扱える。

どれかが成り立たないときの代わりの名前は **`import_network` / `export_network`** です [決定 R8](対で揃えるため、`export` だけ短くはしません)。`load_network` / `save_network` は MATLAB の `load` / `save`(MAT ファイル)と紛らわしいので勧めません。`export` は組み込み関数ではありませんが、`ResultODE.export` などの結果の `export`(Q14)とは別のクラスのメソッドなので衝突しません。

**改名で変える箇所 [事実: grep、`c3dc7b05`]**

| 種類 | 箇所 |
|---|---|
| 定義 | `@PowerNetwork/import_csv.m`, `export_csv.m`(ファイル名とヘルプ)、`PowerNetwork.m` の宣言、`import_matpower.m` のヘルプの参照 |
| メッセージのカタログ | `SystemTools/GUILDA/en/import_csv.xml`, `export_csv.xml`(ID `GUILDA:import_csv:*`, `GUILDA:export_csv:*` を `GUILDA:import:*`, `GUILDA:export:*` に。[未確認] `msg` がカタログのファイル名と呼び出し元の名前をどう対応させるかは実装時に確認) |
| 同梱の系統クラス(コンストラクタ) | `_GUILDAobject/+network/` の `IEEE9bus`, `IEEE14bus`, `IEEE14bus_NoTap`, `IEEE14bus_lossless`, `IEEE68bus`, `IEEJ_EAST10`, `IEEJ_EAST30`, `IEEJ_WEST10`, `IEEJ_WEST30`, `Ishizaki6Bus`, `TEST31bus`, `Txt3Bus` |
| 生成するクラスファイル | `export_csv.m` の `class_file`(書き出すクラスファイルの中の `PowerNetwork.import_csv(...)` の行) |
| 互換の包み | `_VersionSupport/@CsvNetHandler/import.m`, `export.m`, `CsvNetHandler.m`(呼び出しの名前だけを変える。決定 5 の「他の `_VersionSupport` は触らない」の例外で、呼び先の改名に合わせる最小の変更) |
| テスト | `test_F16_csv_io`, `test_F8_utilities`, `test_F30_governor`, `test_I91_slack_power_assignment`, `test_F31_scenario`, `test_levels.m`(節の名前) |
| 検証 | `_GUILDAverification/IEEJ_EAST10/compare_table4_3.m`, `IEEJ_EAST30/compare_table4_9.m`, `IEEJ_WEST10/compare_table4_5.m`, `IEEJ_WEST30/compare_table4_13.m` |
| 文書 | `_GUILDAdoc/developer/` の `api-design`, `feature-data-io`, `feature-initialize`, `feature-model-building`, `feature-simulation`, `folder-structure`、Update log、`notes/v4-migration.md`, `status.md`(過去の記録のノートは変えない) |
| 保留中 | `_GUILDAtutorial/*.mlx`(#113 の保留に含まれるので変えない) |

**利用者への影響:** 以前に `export_csv(..., ClassFile=true)` で書き出したクラスファイルは `PowerNetwork.import_csv` を呼ぶので動かなくなります(互換は設けない)。もう一度 `export` で書き出すか、その 1 行を書き換えます。

### 2.12 回転子角による停止(`StopOnOutOfStep`, `StopAngle`)[決定 §0.4、提案]

`StopOnOutOfStep=true` のとき、ある発電機の回転子角の基準からの差の絶対値が `StopAngle` を超えた時刻で実行を止めます。既定は `false`(止めない)と `360` です。

- **角の差の測り方:** 判定 `judge_out_of_step`(現行 `Scenario.out_of_step`)の既定と同じです。
  - 対象は状態 `delta` を持つ機器(`tab_variable` の Kind が `"x"`、Name が `"delta"`、所有者が機器の行)です。
  - 基準はスラック母線の発電機(スラック母線にある、`delta` を持つ最初の機器)です。差は `|δ_k - δ_ref|`(rad、折り返さない)です。
  - 解列中の機器は対象から外します。基準の発電機が解列中の区間では、停止の判定をしません。
  - 慣性中心(COI)や任意の機器を基準にする指定は、判定 `judge_out_of_step(Reference=)` にはありますが、停止条件には設けません(§9.2 の R10)。
  - 対象の機器や基準の発電機がない系統で `StopOnOutOfStep=true` なら、積分の前に `GUILDA:PowerNetwork:StopNoRotorAngle` で止めます。
- **`SolverODE` での実装:** `SolverODE` は発電機を知りません。`build_simulation_data` が `sct_dae.sct_stop` を作り、`SolverODE` は「ある変数の差の絶対値がしきい値を超えたら止める」とだけ扱います(§3.2)。
  - `ode` の `EventDefinition` の事象関数を、現行の進捗の事象(`solve.m:58`、`odeProg.Events()`)と停止の事象の 2 つの値を返す形にし、どちらも `Response="stop"` にします。停止の事象の値は `r_limit - max(abs(x(iv_angle(lv_on)) - x(i_ref)))` で、正から 0 を横切ると止まります。
  - 区間ごとに、解列中の機器の行を `lv_on` から外します(縮約した `x` での位置に直す)。
  - 止まった後、どちらの事象かを `ode` の解の事象の情報(`sol.EventIndex`)で見分けます。
- **`flag` と `output`:**
  - `flag = 2`: 停止条件で止まった。結果は止まった時刻(`output.tEnd`)までの軌道です。
  - `output.message`: `"The simulation stopped at t = 1.234 s by StopOnOutOfStep: the rotor angle of B003SG1 from B001SG1 reached 360 deg."`
  - `output.outOfStep`: `struct("Time", 1.234, "Unit", "B003SG1", "Reference", "B001SG1", "Angle", 360)`([deg])。`StopOnOutOfStep` が false か止まらなかったときは空の struct です。
  - `GUILDA:PowerNetwork:SimulationIncomplete` の警告は出しません。
  - 判定 `judge_out_of_step` は、`flag = 2` の結果を、角が `Threshold` を超えていれば `"out-of-step"`、超えていなければ `"incomplete"` とします(`StopAngle < Threshold` のとき)。
- **`flag` の値を新しく足す理由:** 0(TimeLimit)、-1(ソルバーの停止)と違い、利用者が求めた止まり方で、結果は正しいためです。1 にしないのは、終了時刻に届いていないことを `flag` だけで見分けられるようにするためです。

### 2.13 出力の時刻(`SampleTime`)[決定 §0.4、提案]

`SampleTime` が正のとき、結果を一定の時間間隔の時刻で記録します。NaN か 0 は、現行どおりソルバーの刻みで記録します(既定)。

- **時刻の格子:** 開始時刻 `t0` からの `t0 + k·SampleTime` です。区間ごとに、区間の中にある格子の時刻に、**区間の開始と終わりの時刻を加えます**(外乱の時刻を保つため。区間の境界の時刻は現行どおり 2 回現れます)。格子は区間ごとではなく実行全体で揃えるので、区間をまたいでも間隔は一定です(境界の前後を除く)。
- **作り方:** 積分の後の補間ではなく、`ode` の出力の時刻で求めます。区間ごとに `solve(o, tv)`(`tv` は区間の開始からの時刻のベクトル)を呼ぶと、ソルバーは自分の刻みで積分し、`tv` の時刻の値をソルバーの連続な近似で返します。積分の精度は `SampleTime` に依りません。[未確認] R2026a の `ode` オブジェクトで、質量行列のある DAE に時刻のベクトルを渡したときの動作と、`EventDefinition`(停止)で途中で止まったときに止まった時刻が解に入るかは、実装時に確かめます。止まった時刻が入らなければ、`sol` の事象の時刻と値を加えます。
- **`ResultODE`:** `rv_t` が格子の時刻(と区間の境界)になるだけで、プロパティの形は同じです。`rm_output`(§5.2)はその時刻で計算するので、記録が少ないほど速くなります。`get_point` は現行どおり記録した時刻の間を線形補間します。
- **`Format="struct"`:** `sol.t` が格子の時刻になり、すべての table の行がそれに揃います。繰り返しの実行で記録を減らすのに使えます。
- **`MaxStep` との関係:** `SampleTime` は記録だけで、刻みは変えません。`SampleTime` より速い変化を積分で捉えるには `MaxStep` を使います。

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
        flag    (1,1) double   % 1, 2 (StopOnOutOfStep), 0, -1.
        output  (1,1) struct   % Details (unchanged).
    end
```

`solve` は `PowerNetwork`、`Bus`、`Branch`、`Component`、制御器、`Scenario` の物体と、その `a_*` を一切読みません。読むのは引数と、ブロックのハンドルの呼び出しだけです。`ProgressODE` と MATLAB の `ode` は使います。`sct_options` の `Solver`, `MaxStep`, `InitialStep` から `ode` オブジェクトを作るのは `solve`(`makeODE`)で、`SampleTime` で出力の時刻を、`StopOnOutOfStep` で停止の事象を決めるのも `solve` です。将来の固定刻みソルバーもここで選びます(§2.1)。

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
| `sct_stop` | struct(空のことがある) | 停止条件(§2.12)。`iv_angle`(対象の `delta` の行)、`iv_angleComp`(その機器の `c_comp` の番号。解列の判定用)、`i_ref`(基準の `delta` の行)、`i_refComp`、`r_limit`([rad])。`StopOnOutOfStep` が false なら空 |
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

時間は必ず `[t0, tend]` で渡ります [決定 Q1, Q2]。`"zoh"` の入力の各点も区間の境界にします(§2.10)。外乱がないシナリオは `t0` に空の外乱 `NoAction` を置く現行の扱い(`compile.m:69-78`)のうち、時間が空の分岐を削ります。`private/getTimeSpan.m` の時間が空のときの規則(`[0, 30·ceil(tmax/10)]`)も削ります。

| フィールド | 型・大きさ | 内容 |
|---|---|---|
| `t1`, `t2` | double | 区間の開始と終了 [s] |
| `iv_tripComp` | double 列 | 解列中の機器(`c_comp` の番号) |
| `iv_tripGC` | double 列 | 解列中の GC(`c_gc` の番号) |
| `iv_faultBus` | double 列 | 地絡中の母線(位置) |
| `iv_openBranch` | double 列, 昇順 | 開放中のブランチ(位置) |
| `iv_offset`, `rv_offset` | double 列 ×2 | この区間の開始で状態に足す値。行は `tab_variable` の x の行。**第 1 区間は空**(初期値に含める、§3.5) |
| `c_input` | cell, k × 4 | `{iv_row, rv_t, rm_v, s_method}`: 入力の行(`tab_variable` の u の行)、区間の開始からの時刻(狭義に増加)、その時刻の値(`numel(rv_t) × numel(iv_row)`)、補間(`"zoh"`, `"foh"`, `"spline"`、一定値は `"zoh"` の 1 点)。外乱ごとに 1 要素で、`SolverODE` が足す。関数ハンドルはない(§2.10) |
| `sr_event` | string 列 | 有効な外乱のタグ(進捗の表示用) |

- タグから位置への変換に使うのは `sct_dae.sv_bus`, `sv_branch`, `sv_comp`, `sv_gc` です。状態と入力の名前は `tab_variable` の `Owner` と `Name` で行に変えます(現行 `compile.m:194-242` の `comp.sv_x`, `comp.sv_u` の照合と同じ結果)。
- LC の解列は現行どおり不可(`UnknownTripUnit`)です。

### 3.5 初期値 `rv_x0` [決定 6(e)、提案]

`build_simulation_data` が作ります。

```
rv_x0 = sct_dae.rv_equilibrium
rv_x0(x の行)  += 第 1 区間で有効なオフセット(開始時刻にかかわらず全部。現行 compile.m:185 の Iteration == 1)
rv_x0(u の行)  += 第 1 区間の入力の時系列の t = 0 の値(現行 initial_condition.m:36-39 の入力関数の値)
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
| 入力 `c_input` | — | `e(iv_row) += F(t)`。`F` は区間の開始で作る補間(`"foh"` 線形、`"spline"`、`"zoh"` は区間の中で一定。範囲外は端の値、§2.10。現行 `getODEFunction.m:77-80` の関数の呼び出しを置き換え) | — |

### 4.2 区間の初期化と整合する初期条件 [事実、変更なし]

区間の境界では微分状態をそのまま引き継ぎ、代数変数だけをその区間の網で解き直します(`CalculateInitialCondition`、解析的なヤコビアンのニュートン法)。解けなければ `InitialConditionFailed`、ソルバーが微分状態を動かしたら止めます(`solve.m:106-170`)。疎行列が拒まれたら密行列で解き直します(`use_dense`)。これらは位置だけで動くので、データの約束の変更で変わりません。

### 4.3 区間の結果 [提案]

`phase_result` は `iv_tripComp`, `iv_tripGC` のブロックの `iv_x` を NaN にし、`I = Y*V` を記録します。タグの照合(`phase_result.m:15-21`)は位置に変わります。記録する行は、現行の x, Vre, Vim, u(`iv_lin`)に**制御器の入力 uc を加えた全変数の行**にします(`Format="struct"` の制御器の表に要るため、§5.3)。`ResultODE` は従来どおり x, Vre, Vim, u の列だけを持ちます。

### 4.4 島の検査 [提案]

現行 `check_islands(net, ...)`(`private/check_islands.m`)は `build_simulation_data` 側(`@PowerNetwork/private/check_islands.m` に移す)で、`compile` の後、積分の前に全区間を検査します。メッセージはブランチと母線のタグを示すので、モデル側が適しています。エラー ID は `GUILDA:PowerNetwork:OpenBranchIsland` に改名します(§6.3)。

### 4.5 停止の事象と出力の時刻 [提案]

- 停止の事象(§2.12)は区間ごとに `lv_on` を作り直し、進捗の事象と一緒に `EventDefinition` に入れます。`flag = 2` で止まったら、残りの区間は解きません。
- 出力の時刻(§2.13)は区間ごとに `solve(o, tv)` で求めます。`SampleTime` が NaN か 0 のときは現行どおり `solve(o, 0, t2-t1)` です。

## 5. 出力の約束

### 5.1 `sct_sol`(`solve` の第 1 出力)[提案]

| フィールド | 型・大きさ | 内容 |
|---|---|---|
| `rv_t` | double, n_t × 1 | 時刻。ソルバーの刻み、または `SampleTime` の格子と区間の境界(§2.13)。区間の境界は 2 回(現行と同じ) |
| `rm_variable` | double, n_t × n_var | 変数 x, Vre, Vim, u, uc の値(`tab_variable` の変数の行の順)。解列中の状態は NaN |
| `rm_I` | double, n_t × 2 n_bus | 母線電流 Ire, Iim |
| `rv_phase` | double, n_t × 1 | 各時刻の区間の番号(`Format="struct"` で機器の電流 `f_I` と出力 `f_Y` を評価するとき、区間の開始からの時刻と、その区間の解列を知るため) |

`sct_sol` は内部のデータで、利用者には返しません。`Format="struct"` の第 1 出力は §5.3 の階層の struct で、`sct_sol` と `sct_dae`(ブロックのハンドル、タグ、表)から作ります。機器の電流と出力は `sct_sol` に記録しないので、そのときだけ評価します(積分の速さに影響しないため)。

`flag` と `output` は 2 番目、3 番目の出力です(どの `Format` でも同じ)。

### 5.2 `ResultODE` のコンストラクタ [決定 Q8、提案]

`ResultPF(tab_powerflow, cm_Y, sct_network, sct_solver)` に揃えます。

```matlab
function obj = ResultODE(sct_sol, sct_dae, sct_network, sct_solver)
    arguments (Input)
        sct_sol      struct = struct()   % Raw solver data (section 5.1).
        sct_dae      struct = struct()   % Data of the run (section 3.2): tab_variable and the blocks, to recompute the outputs y.
        sct_network  struct = struct()   % Snapshot of the network: struct(net, false).
        sct_solver   struct = struct()   % solver, options, flag, output, elapsed.
    end
```

- `ResultODE.tab_variable` と `rm_variable` は x, Vre, Vim, u の行・列だけにします(現行と同じ。`get_point` が uc を `UnknownVariable` にする説明もそのまま)。
- **出力 y [決定 R1]:** y は DAE の変数ではないので、コンストラクタがブロックの `f_Y` を各時刻で評価し直してプロパティに持ちます。ハンドルそのものは持ちません(結果はデータだけ)。

  | プロパティ | 型・大きさ | 内容 |
  |---|---|---|
  | `tab_output` | table, n_out × 7 | `get_variable_map` の Kind が `"y"`(機器の出力)と `"yc"`(制御器の出力)の行。列は `tab_variable` と同じ(Index, Kind, Role, Owner, Name, Label, Bus) |
  | `rm_output` | double, n_t × n_out | 出力の軌道。行 k は `rv_t(k)`、列 m は `tab_output(m,:)`。解列中の機器・GC の出力は NaN |

  - 評価は機器 `f_Y(t, x, V)`、LC `f_Y(t, x, V, u)`、GC `f_Y(t, x, V_all, u)` で、t は区間の開始からの時刻(ソルバーと同じ規約、`sct_sol.rv_phase` から作る)です。現行の右辺は接続が読む出力だけを計算します(`build_index.m:156-160` の `l_y`)が、ここではすべての出力を計算します。
  - 名前は `rv_t` / `tab_variable` / `rm_variable` に揃えます(`tab_output` と `rm_output`)。`get_variable_map` の Role は `"signal"` ですが、利用者向けには「出力」が分かりやすいので `output` にします。
  - `odeResults.Bus(i).Component(j)` に `Y`(列は `sv_y`)を加えます。制御器の出力は `rm_output` だけです(状態と同じ扱い)。
  - `export` の表は、変数の列の後に出力の列(`Label` の名前)を加えます。MAT ファイルには `rm_output`, `tab_output` を加えます。
  - `get_point` は変数だけを返します(出力は線形化の点ではないため。現行どおり)。
  - [決定 R9] コンストラクタでいつも計算します。[未確認] 費用は時刻 × ブロックの数だけの `f_Y` の評価で、S3 で IEEE68 の時間を計ります。遅ければ、`odeResults` と同じく初めて読んだときに計算する形(`rm_output` を Dependent にし、計算に要るデータを Hidden で持つ)に変えます。
- `tab_variable` は `sct_dae.tab_variable` の x, Vre, Vim, u の行から作ります。`sv_bus`, `c_component` は `sct_network`(`a_Bus{i}.s_tag`、`a_Bus{i}.a_Component{j}.s_tag`)から、`c_index` は `tab_variable` の `Kind`, `Owner`, `Bus` から作ります(`get_variable_map` の `c_idxBus` を使わない)。`simulator_columns.m` の検査 `GUILDA:ResultODE:VariableMap` は不要になります。
- `ResultBase` には `[]` を渡し、`s_network` は `ResultODE` が設定します(`ResultPF` と同じ)。`a_PowerNetwork` は空です。
- 新しいプロパティ: `sct_network`(SetAccess=private)。
- **系統の情報が要る理由:** 結果のメソッド(`Plot`, `get_point`, `export`, `odeResults`)は系統を読みません。読むのは判定 `judge_out_of_step`(§2.9)の基準(スラック母線、慣性 `M`)だけで、スナップショットから `l_isSlack` と `tab_parameter.dynamics.M` を読みます。[未確認] `struct(net, false)` の時間(IEEE68 など)は計っていません。S3 で計り、§8.2 のとおり記録します。

### 5.3 `Format="struct"` の形 [決定 Q9、2026-11-12 に形を確定]

`Format="struct"` の第 1 出力は、**モデルの階層をそのまま写した struct** です。各物体の応答は MATLAB の table で、列名は変数名です。`build_simulation_data` のデータと `sct_sol` から `simulate` が作ります(`@PowerNetwork/private/struct_result.m`)。

```matlab
sol = net.simulate("case1", Format="struct");
sol.t                                   % [s] n_t x 1, shared by every table
sol.s_tag                               % "case1" (tag of the scenario)
sol.phase                               % table: output.phases (t1, t2, one column per disturbance)
sol.tab_variable                        % table: variable rows of get_variable_map (x, Vre, Vim, u, uc)
sol.a_Bus{i}.s_tag                      % "B001"
sol.a_Bus{i}.V                          % table: Vre, Vim
sol.a_Bus{i}.I                          % table: Ire, Iim   (current injected into the network at the bus)
sol.a_Bus{i}.P,  sol.a_Bus{i}.Q         % table: P / Q      (one column each)
sol.a_Bus{i}.a_Component{j}.s_tag       % "B001SG1"
sol.a_Bus{i}.a_Component{j}.x           % table: delta, omega, ...
sol.a_Bus{i}.a_Component{j}.u           % table: the inputs of the component (sv_u)
sol.a_Bus{i}.a_Component{j}.I           % table: Ire, Iim   (current injected by this component)
sol.a_Bus{i}.a_Component{j}.a_LocalController{k}.s_tag, .x, .u
sol.a_Bus{i}.a_Component{j}.a_LocalController{k}.a_LocalController{m}.x, .u   % e.g. a PSS under an AVR
sol.a_GlobalController{k}.s_tag, .x, .u
```

| 部分 | 列 | 値の出どころ |
|---|---|---|
| `t` | (列ベクトル) | `sct_sol.rv_t`。区間の境界の時刻は 2 回現れます(`ResultODE.rv_t` と同じ) |
| `a_Bus{i}.V` | `Vre`, `Vim` | `rm_variable` のその母線の Vre・Vim の列 |
| `a_Bus{i}.I` | `Ire`, `Iim` | `rm_I`(母線から網へ注入する電流 `Y*V`。機器の電流の和) |
| `a_Bus{i}.P`, `.Q` | `P` / `Q` | `P + jQ = V · conj(I)`(母線の `V` と `I` から計算) |
| `a_Component{j}.x` | 状態の名前(`sv_x`) | `rm_variable`。解列中は NaN |
| `a_Component{j}.u` | 入力の名前(`sv_u`) | `rm_variable`。解列中は NaN |
| `a_Component{j}.I` | `Ire`, `Iim` | **その機器が注入する電流**(母線の合計ではない)。記録しないので、`f_I(t, x, V, u)` を各時刻で評価します(t は区間の開始からの時刻、ソルバーと同じ規約。`sct_sol.rv_phase` から作る)。解列中は 0(網へ電流を注入しないため) |
| `a_LocalController{k}.x`, `.u` | 状態の名前、入力(uc)の名前 | `rm_variable`(§4.3 で uc も記録する) |
| `a_GlobalController{k}.x` | 状態の名前 | `rm_variable`。解列中は NaN |
| `a_GlobalController{k}.u` | `<入力名>_<機器タグ>` | GC の uc は制御対象ごとにあるので、列名に制御対象のタグを付けます(`get_variable_map` の `Label` から GC のタグを除いた形)。解列中は NaN |

- **時間はトップの `sol.t` だけ [決定 R2]。** 各 table に `Time` の列は重ねません。どの table の行も `sol.t` の同じ行に対応します。理由: (1) 時刻を 1 か所だけに持つので、table ごとに時刻がずれる余地がありません。(2) `x` や `u` の列が変数だけになり、`sol.a_Bus{1}.a_Component{1}.x.omega` や `x{:,:}` で数値の行列としてそのまま使えます(`Time` の列があると、行列にするときに除く手間がかかります)。(3) 母線・機器・制御器の数だけ同じ列を複製しない分、大きな系統でメモリが少なくて済みます。描くときは `plot(sol.t, x.omega)` です。timetable にしない理由も同じで、区間の境界の重複した時刻を行の時刻として持つより、`sol.t` 1 つに揃えるほうが単純です。
- **入れ子のローカル制御器:** モデルと同じ入れ子です。AVR の下の PSS は `a_Component{j}.a_LocalController{k}.a_LocalController{m}` です。制御器のない層の `a_LocalController` は空のセル(0×1)です。機器のない母線の `a_Component` も空のセルです。
- **タグ:** 各要素に `s_tag` の項目(string)を持たせます(モデルの物体のプロパティと同じ名前)。セルの番号は `net.a_Bus`, `a_Component`, `a_LocalController`, `a_GlobalController` の順と同じなので、`net` の同じ位置の物体と対応します。タグで探す例: `i = find(cellfun(@(b) b.s_tag, sol.a_Bus) == "B001")`。
- **出力 y は含めません [決定 R1]。** `Format="struct"` は繰り返しの実行の負担を減らすためのものなので、出力の評価(`f_Y`)をしません。出力が要るときは `Format="GUILDAorigin"` の `result.rm_output` を使います。
- **列名の重なり:** 状態・入力・電流は別の table なので、名前が重なっても問題ありません。
- **計算量:** `Format="struct"` で追加に評価するのは機器の電流 `a_Component{j}.I`(`f_I`)だけです。

### 5.4 `export` への改名 [決定 Q14]

- `simulate` の `Export` オプションを削除し、利用者は `result.export(filename)` を呼びます。拡張子の検査(現行 `simulate.m:103-112` の `check_export`、`SimulateExport`)は `ResultODE.export` の先頭へ移します(積分の後ですが、結果は失われません)。
- `ResultODE.Export` → `export` の改名は、`ResultBase` と全結果クラスとともに潮流計算の作業が済ませました [事実、`514cde71`、§1.6]。この再設計では、`simulate` の `Export` オプションと `check_export` を削除し、拡張子の検査を `ResultODE.export` に置くことだけが残ります。
- `Format="struct"` の結果は `export` を持ちません。書き出すときは `Format="GUILDAorigin"` で実行します。

## 6. 削除・改名の一覧と移行

### 6.1 ファイル

| ファイル | 扱い |
|---|---|
| `_GUILDAsystem/_VersionSupport/v3_simulate_args.m` | 削除 |
| `_GUILDAsystem/_VersionSupport/ODEevent.m` | 削除 |
| `_GUILDAsystem/_auxiliary/@Scenario/copy.m` | 削除(`add_scenario(tag, From=sc)`) |
| `_GUILDAsystem/_auxiliary/@Scenario/string.m` | 削除(`LayerPackage.string`) |
| `_GUILDAsystem/_auxiliary/@Scenario/import_csv.m`, `export_csv.m` | 削除(`PowerNetwork.import` / `export` の `scenario/*.json`) |
| `_GUILDAsystem/_auxiliary/@Scenario/judge.m` | 削除(§2.9) |
| `_GUILDAsystem/_auxiliary/@Scenario/out_of_step.m` | `@ResultODE/judge_out_of_step.m` へ移す(§2.9) |
| `_GUILDAsystem/@PowerNetwork/import_csv.m`, `export_csv.m` | `import.m`, `export.m` に改名(§2.11。代わりの名前になる場合あり) |
| `SystemTools/GUILDA/en/import_csv.xml`, `export_csv.xml` | 改名に合わせる(§2.11) |
| `_GUILDAsystem/_auxiliary/@Scenario/private/getTimeSpan.m` | 時間が空のときの規則を削除(`phase_table` に吸収してもよい) |
| `_GUILDAsystem/_auxiliary/@Scenario/private/mustBeSimulationTime.m` | `SystemTools/` 直下へ移す(`PowerNetwork` からも使う)。`[]` を受けない形に |
| `_GUILDAsystem/_auxiliary/@SolverODE/get_options.m` | 削除(設定の合成は `simulate`) |
| `_GUILDAsystem/_auxiliary/@SolverODE/progress_mode.m` | `@PowerNetwork/private/progress_mode.m` へ移す |
| `_GUILDAsystem/_auxiliary/@SolverODE/private/validate_options.m` | 削除(`SolverOptions` がなくなり、検査は arguments ブロック) |
| `_GUILDAsystem/_auxiliary/@SolverODE/private/mustBeProgress.m` | `@PowerNetwork/private/` へ移す |
| `_GUILDAsystem/_auxiliary/@SolverODE/private/check_islands.m` | `@PowerNetwork/private/` へ移す |
| `_GUILDAsystem/_auxiliary/@SolverODE/private/checkSimulationTime.m` | 削除(未使用、simulate-improvements ST2) [事実: 呼び出しなし] |
| `_GUILDAsystem/_auxiliary/@ResultODE/private/simulator_columns.m` | `tab_variable` から作る形に書き換え |
| `_GUILDAsystem/_auxiliary/@ResultODE/Export.m`, `@ResultBase/Export.m` | [事実] `export.m` に改名済み(`514cde71`) |
| `_GUILDAsystem/_auxiliary/@PowerSystemModel/gui.m` | `@LayerPackage/gui.m` へ移す [決定 Q12] |
| `@PowerNetwork/build_simulation_data.m`, `@PowerNetwork/private/read_scenarios.m`, `write_scenarios.m`, `struct_result.m`, `check_simulation.m`, `simulation_blocks.m`, 検証関数 | 新規 |

### 6.2 メンバー

| メンバー | 扱い |
|---|---|
| `Scenario.Options`, `set.Options` | 削除 |
| `Scenario.l_compat` | 削除 |
| `Scenario.copy` | 削除 |
| `Scenario.import_csv`, `Scenario.export_csv`(Static) | 削除 |
| `Scenario.Judge`, `Scenario.judge`, `Scenario.out_of_step`(Static) | 削除。判定は `ResultODE.judge_out_of_step`(§2.9) |
| `Scenario.add_input`, `add_disturbance` の `InputValue` | 関数ハンドルを受けない。一定値か時系列(§2.10) |
| `PowerNetwork.import_csv`(Static), `export_csv` | `import`, `export`(§2.11) |
| `Scenario(tag, opt)`(公開コンストラクタ) | `Scenario(net, s_tag)`、`Access={?PowerNetwork}` |
| `Scenario.Time` | 既定 `[]` → `[0, 10]`、`(1,2)` に固定 |
| `Scenario.validate(obj, net)` | `validate(obj)` |
| `Scenario.compile(c_scenario, net, time)`(Static) | `compile(obj, sct_dae, time)`(§3.4) |
| `Scenario.to_json_struct`, `add_from_json_struct` | 追加(`Access={?PowerNetwork}`) |
| `Scenario.Ver` | 2.0 → 3.0、「1.x: ODEevent」の説明を削除 |
| `Scenario` の親クラス `auxiliary` | `LayerPackage` |
| `PowerNetwork.add_scenario(sc)` | `sc = add_scenario(s_tag, Time=, Description=, From=)` |
| `PowerNetwork.simulate(time, sc..., NV)` | `simulate(s_scenario, Time=, ..., Format=)` |
| `PowerNetwork.build_simulation_data` | 追加(Hidden)[決定 Q11] |
| `PowerNetwork.children` | `a_Scenario` を含める |
| `PowerNetwork.import` / `export` | `scenario/<tag>.json` を読み書き |
| `LayerPackage.gui`, `LayerPackage.gui_content`(既定) | 追加(`PowerSystemModel.gui` から移す) |
| `SolverODE.OptionMap`, `get_options`, `progress_mode` | 削除 |
| `SolverODE.solve(net, time, c_events, sct_options)` | `solve(sct_dae, sct_event, rv_x0, sct_options)` |
| `SolverODE.build_index(net)` | `build_index(sct_dae)` |
| `SolverODE.set_admittance(ctx, sv_open, l_force)` | `set_admittance(ctx, iv_open, l_force)` |
| `ctx.net`, `ctx.c_comp{j}.comp`, `ctx.c_lc{k}.con`, `ctx.c_gc{k}.gc`, `ctx.sv_owner` | 削除(位置と `f_reconnect`) |
| `ResultODE(net, solver, options, flag, output, elapsed, c_phase)` | `ResultODE(sct_sol, sct_dae, sct_network, sct_solver)` |
| `ResultODE.tab_output`, `rm_output`, `judge_out_of_step` | 追加(§5.2, §2.9) |
| `ResultODE` の `a_PowerNetwork` | 空。`sct_network` を追加 |
| `ResultBase.Export` と各結果クラスの `Export` | [事実] `export` に改名済み(`514cde71`) |
| simulate の `Export` オプション | 削除 [決定 Q14] |
| simulate の `SolverOptions` オプション、`makeODE` の `SolverOptions` の分岐 | 削除 [決定 §0.4] |
| simulate の `Time`, `MaxStep`, `InitialStep`, `SampleTime`, `StopOnOutOfStep`, `StopAngle`, `Format` オプション | 追加(`Time`, `Format` 以外は設定でもある) |
| `flag = 2`, `output.outOfStep` | 追加(§2.12) |
| `Scenario.add_input` の `Method`、`add_disturbance` の `InputMethod`、`tab_disturbance` の列 `InputMethod` | 追加(§2.10) |
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
| `GUILDA:import:ScenarioJson`, `GUILDA:import:UnknownScenarioField` | 追加(§2.8)。`ScenarioFunctionHandle`, `ScenarioJudgeNotSaved` は設けない [決定 R3] |
| `GUILDA:Scenario:InvalidNargin`, `InvalidInputType`(関数の `InputValue`) | 削除。`GUILDA:Scenario:InvalidInputSeries` を追加(§2.10) |
| `GUILDA:Scenario:NoRotorAngle`, `NoSlackGenerator`, `NoInertia`(判定) | `GUILDA:ResultODE:` に改名(§2.9) |
| `GUILDA:import_csv:*`, `GUILDA:export_csv:*` | `GUILDA:import:*`, `GUILDA:export:*`(§2.11) |
| `GUILDA:resolve_options:UnknownName`(simulate の経路) | MATLAB の arguments ブロックのエラーに変わる |
| `GUILDA:SolverODE:Stale`, `InputEdited`, `GconNoTarget`, `OpenBranchIsland` | `GUILDA:PowerNetwork:SimulateStale`, `SimulateInputEdited`, `GconNoTarget`, `OpenBranchIsland` に改名(モデル側の検査になるため。`msg` は呼び出し元のクラスの ID しか受け付けない、powerflow-structure と同じ理由) |
| 現行 `validate_options` の `SolverOptions` の不一致の ID | 削除(`SolverOptions` がなくなる) |
| `GUILDA:PowerNetwork:StopNoRotorAngle`, `GUILDA:Scenario:MethodWithoutSeries` | 追加(§2.12, §2.10) |
| `GUILDA:ResultODE:VariableMap` | 削除 |
| `GUILDA:ResultBase:Unsupported` | [事実] 本文は `export` に変更済み(`514cde71`) |
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
| `SolverOptions=matlab.ode.options.ODE15s(MaxStep=0.01)` | `MaxStep=0.01`(`SolverOptions` はなくなる。`MaxOrder` などは指定できない) |
| 脱調を見つけたら止めるスクリプト(`TimeLimit` や `OutputFcn` で代用していたもの) | `StopOnOutOfStep=true, StopAngle=...`(`flag = 2`) |
| 結果を一定間隔の時刻で取り出すための `interp1` | `SampleTime=0.01` |
| `net.simulate(..., Export="sim.csv")` | `res = net.simulate(...); res.export("sim.csv")` |
| `res.Export(...)`(全結果クラス) | `res.export(...)` |
| `other.add_scenario(sc.copy())` | `other.add_scenario("f", From=sc)` |
| `Scenario.import_csv(file, Network=net)` / `Scenario.export_csv(file, net.a_Scenario)` | `net.export(folder)` が `folder/scenario/<tag>.json` を書き、`PowerNetwork.import(folder)` が読む。単独の読み書きはない |
| `PowerNetwork.import_csv(path)` / `net.export_csv(path)` | `PowerNetwork.import(path)` / `net.export(path)`。古いクラスファイルの `import_csv` の行も書き換える |
| `sc.judge(result)` / `Scenario.out_of_step(result, ...)` | `result.judge_out_of_step(...)` |
| `sc.Judge = @my_judge; sc.judge(result)` | `my_judge(result)` |
| `sc.add_input(u, n, @(t) 0.01*t, [1 3])` | `sc.add_input(u, n, [0 0; 2 0.02], [1 3])`(`[t, 値]`、`Method="foh"` が既定) |
| `ODEevent(tag, net, ...)` | `net.add_scenario(tag).add_disturbance(tag, ...)` |
| `simulate(..., "Reporter", v)` / `"RelativeTolerance", v` | `Progress=v` / `Tolerance=v` |
| `res.a_PowerNetwork` | `res.sct_network`(スナップショット)。系統そのものは呼び出し側の変数 |
| `net.solver_ODE.solve(net, time, events, options)` | `[d, e, x0] = net.build_simulation_data(tag, time); net.solver_ODE.solve(d, e, x0, options)`(上級者向け) |

## 7. 実装の手順

各手順は 1 つのサブセッションの大きさです。各コミットで `DebugScript.run_all('Level','small','FailOnUnexpected',true)`、統合の前に medium を 1 回実行します。

| 手順 | 内容 | 主なファイル | テスト | 依存 |
|---|---|---|---|---|
| **S0** 基準の記録(**済**、`da12bc4e`) | 軌道の比較用の基準を保存する(§8.3)。コードは変えない | `+DebugScript/+helper/simulate_baseline.m`(新規)、基準の MAT は作業用フォルダ(コミットしない) | 基準の作成だけ | なし |
| **S1** v3 の削除(**済**、`938f3b81`) | `v3_simulate_args.m`, `ODEevent.m`, `Deprecated.xml` の 2 項目, `Scenario.l_compat`, `simulate.m:83`、v4-migration の表 | `_VersionSupport/` の 2 ファイル, `Deprecated.xml`, `Scenario.m`(l_compat の 2 行), `simulate.m`(1 行) | F6「Deprecated option names still work」、F31「Compatibility」の節と `test_levels` の該当行を削除 | S0 |
| **S2** `Scenario` を `LayerPackage` に | §2.2-2.5, §2.10 の前半: `add_scenario(tag)`(改名と INFO), `remove_scenario`(delete), `From`, `copy` の削除, `Judge`・`judge` の削除, `InputValue` の時系列(検査と `tab_disturbance` での持ち方。`compile` は暫定で時系列から補間の関数を作る), `Time` の既定 `[0, 10]` と時間の規則の削除, `children`, `log_edit` の上書き, `gui` の移動, GUI の描画, `disp_tree`, `sig_methods` の add/remove | `@Scenario/*`(`compile.m` の時間の分岐を含む。`out_of_step.m`, `import_csv.m`, `export_csv.m` を除く), `@Scenario/private/getTimeSpan.m`, `mustBeSimulationTime.m`(SystemTools へ), `@PowerNetwork/PowerNetwork.m`, `add_scenario.m`, `remove_scenario.m`, `gui_content.m`, `@LayerPackage/`, `@PowerSystemModel/gui.m`, `@DrawerModelGUI/`, `@GUILDA/update_keymap.m`, `functionSignatures.json`, `+DebugScript/+helper/scenario.m`, `noop_event.m` | F31 の書き換え(CSV と判定の節を除く。判定の節は削除し S3 の新しいテストへ)、関数の `InputValue` を使うテスト(F6, F31, I58 など)を時系列に、F32/F33(GUI のシナリオのカード)、F24(タグの名前空間)、F34、I53, I54(時間の規則)、新規は §8.2 | S1 |
| **S3** `ResultODE` をデータから、`export`、判定 | §2.9, §5.2, §5.4: 新しいコンストラクタ, `sct_network`, 出力 `tab_output`/`rm_output` の計算, `simulator_columns` の書き換え, `out_of_step` を `ResultODE.judge_out_of_step` へ移す(`flag = 2` の扱いを含む、§2.12)。`export` への改名は済んでいる(§1.6) | `@ResultODE/*`, `@Scenario/out_of_step.m`(削除), `@SolverODE/solve.m`(231 行の 1 か所だけ。暫定で `net` から入力と出力のハンドルを作る), `_GUILDAverification` の判定の行, 新規 `+DebugScript/test_F38_result_judge.m` | F6 の結果の節、I63(export)、新規 F38(判定。F31 の判定の節を移す)、新規: 系統を消した後(`delete(net)`)も `Plot`, `get_point`, `export`, 判定が動く、出力の値 | S1 |
| **S4** `simulate` の引数と設定 | §2.1, §2.7: タグの引数, `Time` の上書き, arguments ブロック, 設定の合成, `SolverOptions` の削除(`makeODE` の分岐を含む), `MaxStep`/`InitialStep`, `Format`(`"struct"` は S5 で完成。S4 では `"GUILDAorigin"` だけ受け付けてもよい), `Export` オプションの削除, `Scenario.Options` の削除, `get_options` 等の削除, `sig_methods` の simulate, 呼び出し元(`_GUILDAobject` のヘルプの例 20 ファイル、`_GUILDAverification` の 4 ファイルの simulate の行) | `simulate.m`, `@PowerNetwork/private/`(検証関数, `progress_mode`, `calculate_powerflow.m` から移す `mustBePlotFcn`), `calculate_powerflow.m`(ローカルの `mustBePlotFcn` を削除), `@SolverODE/SolverODE.m`, `get_options.m`, `progress_mode.m`, `private/makeODE.m`, `validate_options.m`, `mustBeProgress.m`, `@Scenario/Scenario.m`(Options), `DefaultTimeSimulation.json`, `update_keymap.m`, `functionSignatures.json`, `+DebugScript/*`(simulate の呼び出し約 230 か所) | 全 simulate テストの書き換え、I54(時間の検査)、I63(`Export` オプションの節を `export` に)、新規は §8.2 | S2(`Scenario.m`, `update_keymap.m`) |
| **S5** `SolverODE` のデータの約束、`Format="struct"` | §3, §4, §5.1, §5.3, §2.10 の後半(`compile` の時系列の出力、`"zoh"` の点の区間の境界、`SolverODE` の補間): `build_simulation_data`, `compile` の位置化, 初期値, `check_islands` の移動, `build_index` の分割, `set_phase`/`set_admittance`/`initial_condition`/`getNextPhase`/`phase_result` の位置化(uc も記録), `solve` のシグネチャ, `struct_result`, S3 の暫定の除去 | `simulate.m`, `@PowerNetwork/PowerNetwork.m`(Hidden の宣言), `@PowerNetwork/build_simulation_data.m`, `@PowerNetwork/private/`(収集, `struct_result`), `@Scenario/compile.m`, `@SolverODE/*` | F6, F29, F35(`PhaseProbe` で `solve` を直接呼ぶ箇所を `build_simulation_data` に)、I50-I64、§8.3 の軌道の一致、新規は §8.2 | S3, S4 |
| **S5b** 停止条件と出力の時刻 | §2.12, §2.13, §4.5: `StopOnOutOfStep`/`StopAngle`/`SampleTime` の arguments と設定、`sct_dae.sct_stop`、`EventDefinition` の 2 つの事象、`flag = 2` と `output.outOfStep`、`solve(o, tv)` による出力の時刻、`StopNoRotorAngle`、`sig_methods` の再生成 | `simulate.m`, `@PowerNetwork/build_simulation_data.m`, `@PowerNetwork/private/simulation_blocks.m`, `@SolverODE/solve.m`, `private/makeODE.m`(必要なら), `DefaultTimeSimulation.json`, `functionSignatures.json` | 新規は §8.2(停止、出力の時刻)。既定(停止なし、`SampleTime` NaN)は §8.3 の基準と `isequaln` | S5 |
| **S6** 系統のファイル: 改名とシナリオの JSON | §2.11 の確認(最初に R2026a で `PowerNetwork.import` を確かめ、結果をノートに記録)、`import_csv`/`export_csv` → `import`/`export`(または代わりの名前)と §2.11 の表の全箇所、§2.8: `scenario/`, `read_scenarios`/`write_scenarios`, `to_json_struct`/`add_from_json_struct`, `Scenario.import_csv`/`export_csv` の削除, `_GUILDAverification` の 3 スクリプトのシナリオの読み込み | `@PowerNetwork/import_csv.m`, `export_csv.m`(改名), `PowerNetwork.m`, `import_matpower.m`(ヘルプ), カタログの 2 ファイル, `_GUILDAobject/+network/` の 12 クラス, `_VersionSupport/@CsvNetHandler/`(呼び出しの名前), `@PowerNetwork/private/read_scenarios.m`, `write_scenarios.m`, `@Scenario/import_csv.m`, `export_csv.m`, `Scenario.m`(2 メソッドの宣言), `_GUILDAverification/IEEJ_*/compare_table*.m`, テスト(F8, F16, F30, F31, I91, `test_levels`) | F16(往復)にシナリオを追加、F31 の CSV の節を JSON に置き換え、新規は §8.2 | S3(検証スクリプトの判定の行), S4(`Scenario.m`、検証スクリプト), S5(`PowerNetwork.m`) |
| **S7** 文書 | `feature-simulation.html`(シーケンス図、SIM-xx の手順、オプション表)、`feature-data-io.html`(`scenario/` の JSON)、`api-design.html`, `class-design.html`, Update log, `v4-migration.md`, `status.md`、ヘルプの `<@Examples>` の残り | `_GUILDAdoc/`, `notes/` | 文書の検査スクリプト(あれば) | S5, S6(利用者向けの部分は S4 の後に並行可) |

**並行できる組 [提案]**

- S2 と S3 は並行できます(重なるファイルはありません。S3 は `@Scenario/out_of_step.m` だけ、S2 はそれ以外の `@Scenario/*` のうち CSV と `out_of_step` 以外)。ただし S3 は `ResultBase` の改名の統合を待ちます(下記)。
- S5b と S6 は並行できます(S5b は `simulate.m`, `build_simulation_data.m`, `@SolverODE/*`, 設定ファイル、S6 は `import`/`export`, `PowerNetwork.m`, `@Scenario/*` の CSV と JSON, 検証スクリプト)。`functionSignatures.json` は S5b だけが作り直します(S6 の `import`/`export` は `sig_methods` にない)。
- S5 と S6 は、`PowerNetwork.m` を両方が触る(S5 は `build_simulation_data` の宣言、S6 は `import`/`export` の宣言)ため、**S6 は S5 の統合の後**にします。S6 の最初の確認(§2.11 の 1-4、コードを変えない)だけは S5 と並行できます。
- S7 の利用者向け(Tutorial 以外のページ、v4-migration)は S4 の後、S5 と並行できます。`feature-simulation.html` は S5 の後、`feature-data-io.html` は S6 の後です。
- `_GUILDAtutorial/*.mlx` はチュートリアルの保留(#113)に含まれるため、この計画では変えません。

**注意(他の作業との重なり)**

- **`Export` → `export` の改名 [決定 R5、事実]:** 潮流計算の作業が `ResultBase` と全結果クラスの改名を済ませ、`514cde71` に統合されました(§1.6)。S3 と S4 は改名を前提にします。
- `mustBePlotFcn` は `calculate_powerflow.m` のローカル関数として統合済みです [事実]。S4 が `@PowerNetwork/private/` へ移して共有します(`calculate_powerflow.m` を触るので、そのとき潮流計算の作業が並行していないことを確かめる)。
- `update_keymap.m` と `functionSignatures.json` は S2 と S4 が触るので、S4 は S2 の統合後に始めます。
- `PowerNetwork.import_csv` / `export_csv`(改名後 `import` / `export`)は S6 だけが触ります。§9.3 の「接続を JSON、パラメータを CSV」の設計を行う場合は、S6 の後にします。

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
| `PowerNetwork.import_csv`, `export_csv` | F16, F8, F30, F31, I91, `test_levels.m` |
| `.judge(` / `.Judge` | F31 (235, 242, 267, 270-271 行) |
| 関数の `InputValue`(`@(t)`) | F6, F31 など(S2 で grep して時系列に) |
| `solver_ODE.solve(` | F29 (52, 192 行), F35 (300 行) |
| `SolverOptions=` | F6(削除。`MaxStep=` に置き換える) |
| `Export=`(simulate のオプション) | I63, F6, I62(S4 で `result.export` に。`.Export(` の改名は済んでいる [事実、`514cde71`]) |

**補助関数:** 多くのテストは `DebugScript.helper.noop_event(net, tspan)` と `DebugScript.helper.scenario(tag, net, ...)` でシナリオを作り、`net.simulate(tspan, ev)` で実行します。S2 で `helper.scenario` を `net.add_scenario` に、`noop_event` が `Time=tspan` を設定する形にし、S4 で `net.simulate(tspan, ev)` を `net.simulate(ev.s_tag)` に置き換えます。シナリオと違う時間で実行する箇所は `net.simulate(ev.s_tag, Time=tspan)` にします。

### 8.2 新しいテスト

- タブ補完: `functionSignatures.json` の `PowerNetwork.simulate` の `s_scenario` が `choices=cellstr(string(obj.a_Scenario))`(F34)。
- `simulate("nope")` が `ScenarioNotFound` で止まり、本文にタグの一覧がある。
- `Time`: `simulate("f", Time=[0 2])` が `[0, 2]` で計算し、`sc.Time` は変わらない。`Time` を与えなければ `sc.Time`。`add_scenario("f")` の `Time` は `[0, 10]`。外乱の時間幅は時間を変えない。
- 呼び出しの `Tolerance` が `result.options` に入り、`GUILDA.config("TimeSimulation","Tolerance")` は変わらない。与えない名前は設定の値。
- `MaxStep=1e-3` で出力の時間間隔が 1e-3 以下。設定の `MaxStep` も効く(`GUILDA.setting` を一時的に変え、`onCleanup` で戻す)。呼び出しの値が設定に勝つ。与えない実行は基準と `isequaln`。`SolverOptions=...` は MATLAB の未知の名前のエラー。
- 停止条件(S5b): IEEE9 などで脱調する地絡(長い故障時間)を `StopOnOutOfStep=true, StopAngle=180` で計算すると、`flag = 2`、`output.outOfStep.Unit` が脱調した発電機、`output.tEnd` の角の差が 180 deg(事象の許容誤差の範囲)、`SimulationIncomplete` の警告が出ない。同じ計算を停止なしで行い、`tEnd` までの軌道が一致する。基準の発電機の解列中は止まらない。`delta` のない系統で `StopNoRotorAngle`。`judge_out_of_step` が `flag = 2` を `"out-of-step"` / `"incomplete"` に正しく分ける。
- 出力の時刻(S5b): `SampleTime=0.01` で `rv_t` の区間の中の間隔が 0.01、区間の開始と終わり(外乱の時刻)が含まれ、境界が 2 回現れる。値がソルバーの刻みの計算(`SampleTime` なし)の補間と許容誤差の範囲で一致。`Format="struct"` の `sol.t` も同じ。`StopOnOutOfStep` で止まったとき最後の時刻が止まった時刻。NaN と 0 は基準と `isequaln`。
- 入力の補間: `Method="zoh"` で各点が `output.phases` の区間の境界になり、入力が区間の中で一定。`"spline"` の入力が `griddedInterpolant(..., "spline")` の値と一致。一定値に `Method` を与えると `MethodWithoutSeries`。JSON の往復で `Method` が残り、省いた JSON は `"foh"`。
- `Format="struct"`: `sol.a_Bus{i}.V.Vre` が `ResultODE` の同じ列と `isequaln`。どの table も `height` が `numel(sol.t)`。各要素の `s_tag` が `net` の同じ位置の物体のタグ。AVR+PSS の系統で PSS が `a_LocalController{1}.a_LocalController{1}` にある。機器の `I` の和が母線の `I` と一致(数値の誤差の範囲)。`P + jQ = V·conj(I)`。GC の `u` の列名が `<名前>_<機器タグ>`。解列中の機器の `x` が NaN、`I` が 0。機器のない母線の `a_Component` が空。`.y` を加える場合は、その列が `f_Y` の値と一致。
- `simulate(..., Export=...)` が MATLAB の未知の名前のエラーになる。`result.export("x.foo")` が `ExportExtension` で止まる。
- `Scenario` の改名・外乱の追加が `net.sct_stale` と `n_revOPF` を変えない。
- `disp_tree` の出力にシナリオの行がある。GUI のシナリオのカードとページ(F32/F33 の形で、表示を開いて閉じる)。
- `add_scenario` のタグが母線のタグと重なると番号を足した `sc.s_tag` になり、INFO が出る(`evalc` で確かめる)。
- `remove_scenario` の後、その変数の `isvalid` が false。`From` で別の系統へ複製すると元は残る。
- JSON: `export` → `import` の往復で、各シナリオの `Time`, `Description`, `tab_disturbance`(一定値と時系列の `InputValue` を含む)が一致。`scenario/` のないフォルダは従来どおり読める。壊れた JSON は系統を変える前に止まる。古いファイルの `Judge` の項目は `UnknownScenarioField` の警告で無視される。
- 改名: `PowerNetwork.import(path)` がスクリプト、関数の中、同梱の系統のコンストラクタから動く(§2.11 の確認)。`export(..., ClassFile=true)` が書くクラスファイルが `PowerNetwork.import` を呼ぶ。
- シナリオが関数ハンドルを持たない: `struct(sc)` と `tab_disturbance` に `function_handle` がない。`add_input` に関数を渡すと止まる。
- 入力の時系列: `[0 0; 2 0.02]` の入力(既定の `"foh"`)で、入力の軌道(`result.rm_variable` の u の列)が線形補間の値と一致し、`t1 + 2` 以後は 0.02 を保つ。table で渡しても同じ。`t` が増加しない、`t(1) ≠ 0` は `InvalidInputSeries`。同じ入力の 2 つの外乱の和。一定値の入力は基準と `isequaln`。
- 判定: `result.judge_out_of_step()` が現行の `Scenario.out_of_step(result)` と同じ struct を返す(F31 の判定の節を F38 へ移す)。
- 出力: `result.rm_output` の機器の出力が、同じ時刻の `f_Y` の値と一致。解列中は NaN。`odeResults` の `Y`。`export` の表に出力の列がある。`Format="struct"` に `.y` がない。
- `solve` が系統を読まない: `build_simulation_data` の後で系統を `delete` し、`solve` が同じ結果を返す(S5)。
- `ResultODE` が系統を読まない: 系統を `delete` した後で `Plot`, `get_point`, `odeResults`, `export`, `result.judge_out_of_step()`(`Reference="slack"`, `"COI"`)、`rm_output` が動く(S3)。`struct(net, false)` の時間を IEEE68 で記録する。

### 8.3 軌道が変わらないことの確認 [提案]

S0 で、基準コミットのコードで次の実行の `rv_t`, `rm_variable`, `rm_I`, `output.phases`, `flag` を MAT ファイルに保存します(作業用フォルダ、コミットしない)。すべて時間を明示します(Q2 で時間の自動の規則がなくなるため)。

| 例 | 外乱 |
|---|---|
| IEEE68bus(既定) | B008 などの地絡 `[1, 1.07]`、`[0, 10]` |
| IEEE68bus(`LocalController=false`) | 外乱なし `[0, 5]`(t = 0 の停止の回帰) |
| IEEE14bus(AVR+PSS) | SG1B003 の解列 `[1, 1.2]`(再接続)、`[0, 5]` |
| IEEE14bus | EL003 の開放 `[1, 3]`、`[0, 5]` |
| IEEE9bus | オフセット(`delta` +0.1)と一定値の入力(`Pmech` 0.05)、`[0, 5]`。関数の入力は時系列に置き換わるので基準から外し、線形の関数とその 2 点の時系列の差を `Tolerance` 以内として別に確かめる |
| AGC 付きの系統(F18 の構成) | GC の解列、GC が観測する機器の解列、`[0, 5]` |

各手順の後に同じ実行をして比べます。

- **S1-S4, S6:** 数値の経路を変えないので `isequaln` で一致することを求めます。
- **S5:** 評価の順序と初期値(`rv_Iequilibrium` を含む)を保つので、`isequaln` を目標にします。一致しない場合は差の最大値を記録し、`Tolerance` 以内で、原因(例: 行列の組み立ての順)を特定してから統合します。
- 比較は `DebugScript.helper.simulate_baseline(Mode="compare")` のように 1 つの関数で行い、F6 に常設はしません(基準の MAT をリポジトリに入れないため)。常設するなら、短い区間の小さな例で、基準値を数値でテストに書きます。

## 9. 問いと回答

### 9.1 回答済み(2026-11-12)

§0.2-§0.5 の表のとおりです。§0.4 で Q6 の回答(`SolverOptions` を残す)は取り消され、`SolverOptions` は削除になりました。回答の前の推奨と違う決定は Q1(時間の上書きを許す)、Q2(既定 `[0, 10]`)、Q3(改名と INFO)、Q6(`SolverOptions` を残す)、Q9(モデルの階層を写した struct と table)、Q13(系統のフォルダの JSON)、Q14(`Export` オプションの削除と `export` への改名)です。

### 9.2 確認の状況(すべて決定済み)

| # | 事項 | 推奨 |
|---|---|---|
| R1 | ~~`Format="struct"` に出力 `.y` を加えるか~~ | **決定(§0.3):** `ResultODE` が計算して `rm_output` に持つ。`Format="struct"` は持たない |
| R2 | ~~`Format="struct"` の table に `Time` の列を重ねるか~~ | **決定(§0.3):** 重ねない。`sol.t` だけ |
| R3 | ~~シナリオの JSON と関数ハンドル~~ | **決定(§0.3):** シナリオは関数ハンドルを持たない。JSON は単純なデータだけ |
| R4 | ~~`_GUILDAverification` の IEEJ のシナリオ~~ | **決定(§0.4):** 推奨どおり、検証スクリプトのローカル関数 |
| R5 | ~~`Export` → `export` の改名をだれが行うか~~ | **決定(§0.4)、済み:** 潮流計算の作業が全結果クラスを改名(`514cde71`) |
| R6 | ~~判定のメソッドの名前と置き場所~~ | **決定(§0.4):** `ResultODE.judge_out_of_step(Reference=, Threshold=)` |
| R7 | ~~入力の時系列の補間と時刻の基準~~ | **決定(§0.4):** `Method` で `"zoh"` / `"foh"`(既定) / `"spline"`、最後の点の後は値を保つ、時刻は外乱の開始から |
| R8 | ~~`import` を使えないときの代わりの名前~~ | **決定(§0.4):** `import_network` / `export_network` |
| R9 | ~~`ResultODE` が出力をいつも計算すること~~ | **決定(§0.4):** いつも計算する。IEEE68 で遅ければ、初めて読んだときに計算する形(`odeResults` と同じ遅延)に変える |
| R10 | ~~停止条件の基準~~ | **決定(§0.5):** スラック母線の発電機だけ |
| R11 | ~~`StopOnOutOfStep` で止めたときの `flag`~~ | **決定(§0.5):** `flag = 2`、`SimulationIncomplete` の警告は出さない |
| R12 | ~~`"zoh"` の各点を区間の境界にすること~~ | **決定(§0.5):** 境界にする。点の多い `"zoh"` が遅くなることをヘルプに書く |

### 9.3 別の設計課題: 系統の接続を JSON、パラメータを CSV に

利用者は、系統の接続の構造を JSON に、パラメータを CSV に分けて保存することを検討しています。**S0-S7 とは別の設計課題**として扱い、この再設計では `PowerNetwork.import_csv` / `export_csv` の既存の配置に `scenario/` を足すだけにします。

現状は、すべてが CSV で、表どうしを ID の列で結んでいます [事実]。母線は `bus/parameter.csv` の行番号で番号付けされ、ブランチの `From`・`To` と機器の `Bus` がその番号を指します。機器は `component/<key>/main.csv` の `ParameterID`・`OpfID` で `dynamics.csv`・`opf.csv` の行を指します。タグは `FullTag` 列で保存します。制御器は保存しません(`ControllersNotSaved`)。

- **JSON にする利点:** 階層(母線 → 機器 → ローカル制御器、GC と制御対象)をそのまま書けるので、いまは保存できない制御器を自然に保存できます。番号や ID の列による間接の参照がタグによる参照になり、行の並べ替えや追加で参照が壊れません。シナリオ(§2.8)と同じ形式になり、`Format` と `version` の項目で版を管理できます。
- **JSON にする欠点:** 表計算ソフトで多数の母線や機器を一覧して編集する使い方(いまの CSV の主な利点)が、接続の部分では失われます。接続とパラメータが 2 種類のファイルに分かれるので、両者の対応(タグ)の検査が新たに要ります。既存の CSV フォルダ(同梱の系統、利用者のフォルダ)の移行と、旧形式の読み込みを当面残すかの判断が要ります。
- **中間の案:** 接続(母線の並び、ブランチの両端、機器の母線と key、制御器の階層)を 1 つの JSON に、パラメータを key ごとの CSV(いまの `dynamics.csv` など、`FullTag` で結ぶ)に残すと、制御器の保存と表計算での編集を両立できます。
