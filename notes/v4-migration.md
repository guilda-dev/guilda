# Migrating to GUILDA v4

状態: `refactor/design-alignment`(分岐元 `version4.0`)で作業中です。v4 では互換性を壊す変更を認めています。

基準コミットは `fe9aa3a`(2026-11-02)です。`b69e54b` 以降のコミットを確認し、スクリプトやモデルの作者が対応を要する変更を追記しました。追記した項目は実装とテストで確認しています。それ以前からある記述をすべて再検証したわけではありません。

第 1 章はスクリプト作者向けの変更(1.7–1.15 と 1.17 は v4 の解析 API)、第 2 章はモデル作者向けの変更、第 3 章は計画中の変更、第 4 章は互換性の方針、第 5 章は解析クラスとモデルを書く人への注意です。

設計の参照先は、同じブランチの `_GUILDAdoc/developer/class-design.html` と `api-design.html` です。

> **Silent breaking changes.** These run without an error or a warning but
> give a different meaning or different numbers. Check every script that
> uses them.
>
> - **`simulate`'s second output is inverted.** v3: `true` when the run
>   stopped early. v4: `flag = 1` completed, `0` stopped by `TimeLimit`,
>   `-1` stopped by the solver. `if flag` is now true for a completed run
>   **and** for a solver stop; test `flag < 1` for "stopped early" (1.11).
> - **`initialize`'s outputs are reordered.** v3: `[flag, tab, output]`.
>   v4: `[result, flag, output]` with `result.tab_bus` the old `tab`.
>   `[flag, tab] = net.initialize()` gives no error: `flag` is then a
>   `ResultPF` and `tab` the exit flag. `if flag` on the result
>   object fails or means something else; test `result.l_success` (1.17).
> - **The slack power goes to the first component with `Q = NaN`.** v3 gave it to
>   the first component of the slack bus, so a load added before a generator
>   generated power. Those networks now split the power differently (1.8).
> - **Layout of `comp.get_sys` / `bus.get_sys`.** Inputs, states and
>   outputs now have the same shape on every layer: inputs `[port; u of the
>   component; u of its controllers]`, outputs `[port; y of the component;
>   y of its controllers]`; states are never outputs. The option `full`
>   (states as outputs) is accepted and **ignored**, so code that took the
>   states from the outputs of a `full=true` model reads other rows. An
>   output named like a state is labelled `Y_<name>`. `net.get_sys` and
>   `net.linearize` are unchanged (1.12).
> - **`get_sys`'s second output is no longer `lin`.** `[sys, flag, output]`:
>   `flag` is a logical (all Jacobian entries finite and `Avv` invertible) and
>   `output.result` is the `ResultLIN`. `[sys, lin] = net.get_sys()`
>   gives no error; using `lin` as an `odeLinearizer` fails later (1.12).
> - **`get_sys` は既定で `ss` ではなく `ResultLIN` を返します。** すべての層の `get_sys` の既定は `Format="GUILDAorigin"`(`ResultLIN` を返却)です。`eig(sys)`、`pole`、`step`、`sys(出力名, 入力名)` など `ss` の関数を使うスクリプトは `Format="ss"` を渡す(Control System Toolbox が必要)か、`res.A`、`res.E` と名前のプロパティを読むように直してください(1.12)。
> - **`optimize_powerflow` with 1–3 outputs has the v4 meaning.**
>   `[bus, cub, flag] = net.optimize_powerflow()` now gives
>   `bus = ResultOPF`, `cub = flag`, `flag = output`. Only the 6-output form
>   returns the old tuple (with a warning) (1.9).
> - **DAE `B` sign.** `get_sys(Method="DAE")` / `get_ss("DAE")` returns
>   `B` with the opposite sign on the algebraic rows (the bus current
>   balance). v3 had the wrong sign there, so its DAE model did not match
>   Kron (1.12).
> - **IEEE14bus numbers.** `network.IEEE14bus` now has the MATPOWER case14
>   data, `IEEE14bus_lossless` is that data with R = 0, and CSV import reads
>   transformer taps, so power flow, OPF, simulation and linearization
>   results of both networks differ from v3 (1.15).
> - **A tripped global controller gives no output.** A trip event that
>   names a global controller now also sets its output to zero (before: only
>   its states were frozen, and a direct feed-through part kept acting)
>   (1.6).
> - **An input under a local controller now acts.** An input event or a
>   global controller on an input that a local controller drives adds to the
>   controller's output in `simulate` (before: it was overwritten, so it had
>   no effect) (1.6).
> - **A global controller reads outputs and can drive local controllers.**
>   It reads an output of its unit before a state of the same name (the AGC
>   reads the output `omega`, equal to the state), and an output whose name is
>   an input of a local controller of the unit goes to that controller instead
>   of the component (1.6). The bundled models give the same numbers: no
>   bundled local controller has an input named like an AGC output.
> - **`TimeLimit` no longer stops a run by default.** The default is `Inf`
>   (before: 10 s of each phase), so a run that used to stop early with
>   `flag = 0` now continues to the end time (1.11).
> - **`initialize(Method="OPF")` and `Method="equilibrium"` numbers.** The
>   components now take the powers of the OPF solution or the ones they hold,
>   not `tab_parameter.powerflow`, so the stored equilibrium and later simulations
>   differ where the old point violated Y*V = I (1.17).
> - **Automatic tag numbers.** After a removal, `add_bus`, `add_branch` and
>   `add_component` number the new object after the largest number in use,
>   not `numel + 1`; scripts that build tags by counting may name another
>   object (1.4).
> - **潮流計算の解の数値。** `Tolerance` の既定は全手法で最大 P/Q 不平衡 1e-8 [pu] です(以前は手法ごとに意味と既定値が異なり、`"dynamic"` は 1e-5、`"fsolve"` は fsolve の既定)。また既定の `WarmStart=true` では、2 回目以降の計算は同じ系統の前回の収束解から始まります。解は `Tolerance` の範囲で変わり、`"dynamic"` では以前より代数解に近くなります。初期値を固定したい計算は `WarmStart=false`(フラットスタート)を渡してください(1.8)。
> - **`@GUILDA/user/` の改名した設定キーは無視されます。** OptimalPowerFlow の `OptimalityTolerance`、ContinuationPowerFlow の `MaxIterations`、TimeSimulation の `RelativeTolerance` は読まれず(表示だけで警告なし)、新しいキー `Tolerance` / `MaxIteration` の既定値で計算します。新しいキー名で書き直してください(「解析の設定は GUILDA.setting」の節)。
> - **`local_LQR` のゲインは系統の Hz の編集に追従します。** Hz の編集後の `get_sys` や `simulate` で、保持している平衡点から `K` を設計し直します。以前は古い Hz の `K` のままだったので、Hz を編集するスクリプトでは数値が変わります(1.6)。
> - **Automatic tags read parent first, and variable labels are
>   `<name>_<s_tag>`.** A component on bus `B001` is `B001SG1` (was
>   `SG1B001`), its AVR `B001SG1CA1` (was `CA1SG1B001`), a global controller
>   `PowerNetworkAGC1` (was `AGC1PowerNetwork`). Every label (`StateName`,
>   `InputName`, `OutputName`, the `Label` column of `get_variable_map`, the
>   controller columns of `Export`) ends with the tag of its owner only:
>   `delta_SG1B001_B001_IEEE9bus` is now `delta_B001SG1`. A script that
>   looks a tag or a label up by a hard-coded string finds nothing; `ismember`
>   and `==` return false without an error. The messages in `sct_stale` name
>   the edited layer only, and `LayerPackage.get_tag` is removed (1.23).

---

## 解析クラスの名前の変更

`_GUILDAsystem/_auxiliary` のソルバー、結果、イベントのクラス名を統一しました。別名は残していないので、旧名を呼ぶと未定義エラーになります。メッセージ ID も `GUILDA:<旧名>:*` から `GUILDA:<新名>:*` に、カタログも `SystemTools/GUILDA/en/<新名>.xml` に変わりました。

| 旧名 | 新名 |
|---|---|
| `PowerFlowCalculation` | `SolverPF` |
| `PowerFlowResult` | `ResultPF` |
| `OptimalPowerFlow` | `SolverOPF` |
| `OPFResult` | `ResultOPF` |
| `ContinuationPowerFlow` | `SolverCPF` |
| `CPFResult` | `ResultCPF` |
| `odeSimulator` | `SolverODE` |
| `odeSimulationResult` | `ResultODE` |
| `odeEventSet` | `Scenario`(1.18) |
| `odeProgress` | `ProgressODE` |
| `odeLinearizer` | `SolverLIN` |
| `LinearizationResult` | `ResultLIN` |

イベントのクラスは、v3 の `odeEventSet` も v4 の開発途中の名前 `ODEevent` も `Scenario` に対応します。`ODEevent(tag, net, ...)` は互換の関数として残しています(1.18)。`EventODE` という名前は公開されておらず、別名もありません。

次の名前は変わりません。

- 結果の `s_solver` の値は新しいクラス名になりますが、`net.solver_PF`、`net.solver_OPF`、`net.solver_CPF`、`net.solver_ODE`、`net.solver_LIN` のプロパティ名はそのままです。
- 設定のセクション名とファイル名(`GUILDA.config("PowerFlowCalculation")`、`"OptimalPowerFlow"`、`"ContinuationPowerFlow"`、`Default<セクション名>.json`)はそのままなので、`@GUILDA/user` に保存した設定は引き続き読み込まれます。ただし改名したキーは変換しません(次の節)。
- `GUILDA:Deprecated:*` と `GUILDA:v3_*` の ID(`ContinuationPowerFlowConstructor`、`OdeLinearizerConstructor` など)と `ContinuationPowerFlowV3`、`Continuation_Power_Flow` もそのままです。

この文書の v3 の書き方を示す箇所では、旧クラス名を残しています。

---

## 解析の設定は GUILDA.setting、`net.solver_*` は条件だけ

潮流計算(1.8)と同じく、最適潮流計算、連続潮流計算、時間応答シミュレーション、近似線形化の設定も `GUILDA.setting` に置きました。各ソルバーの `get_options` が実行のたびに解析ごとのセクション(`GUILDA.config("<セクション>")`。既定値は `@GUILDA/config/Default<セクション>.json`、`@GUILDA/user/` の同名ファイルで上書き)を読み、呼び出しの Name-Value をその呼び出しだけに適用します(設定ファイルは変わりません)。

| 解析 | セクション | `net.solver_*` に残るもの |
|---|---|---|
| 潮流計算 | PowerFlowCalculation | `solver_PF`: ウォームスタートの解とキャッシュ(設定なし) |
| 最適潮流計算 | OptimalPowerFlow | `solver_OPF`: 条件 `Cost`、`Constraint`、`DefaultCost`、`ReferenceBus`(public。実行をまたいで保持し、Name-Value で上書き可)、AC OPF のウォームスタートの解、問題のキャッシュ |
| 連続潮流計算 | ContinuationPowerFlow | `solver_CPF`: 条件 `LoadBus` |
| 時間応答シミュレーション | TimeSimulation | `solver_ODE`: なし |
| 近似線形化 | Linearization(新設) | `solver_LIN`: なし(v3 互換の Hidden `NonUnit` だけ) |

- **削除したプロパティへの代入はエラーです(互換なし)。** 例: `net.solver_ODE.RelativeTolerance = 1e-6`、`net.solver_ODE.Progress = "none"`、`net.solver_ODE.TimeLimit = 60`、`net.solver_OPF.Method = "ELD"`、`net.solver_CPF.MaxIterations = 100`、`net.solver_LIN.Method`、`.Point`、`.Coordinate`。いずれも存在しないプロパティへの代入として止まります。既定を変えるときは `GUILDA.setting` で該当するセクションを編集し、1 回だけ変えるときは Name-Value を渡してください(例 `net.simulate(t, sc, Tolerance=1e-6, Progress="none")`)。
- **v3 互換の `net.solver_ODE.Reporter` も削除しました。** `v3_ode_reporter.m` と警告 `GUILDA:Deprecated:SimulatorReporter` はなくなり、代入はエラーです。Name-Value の `simulate(..., Reporter=..., RelativeTolerance=...)`(`GUILDA:Deprecated:SimulateOptionName`)はこれまでどおり動きます。
- **JSON のキーを Name-Value の名前にそろえました。** `@GUILDA/user/` の旧キーは変換しません。読み込み時に未知のキーとして捨てられ(`Remove unknown environment field '<キー>'.` を表示、警告なし)、新しいキーは既定値になります。

  | セクション | 旧キー | 新キー |
  |---|---|---|
  | OptimalPowerFlow | `OptimalityTolerance` | `Tolerance` |
  | OptimalPowerFlow | `Display`(select、既定 `"default"` = ソルバーの既定) | `Verbose`(logical、既定 false。ソルバーの `Display` は true で `"iter"`、false で `"none"`) |
  | ContinuationPowerFlow | `MaxIterations` | `MaxIteration` |
  | ContinuationPowerFlow | `LoadBus` | なし(`net.solver_CPF.LoadBus` の条件か Name-Value `LoadBus`) |
  | TimeSimulation | `RelativeTolerance` | `Tolerance` |
  | TimeSimulation | なし | `Solver`(既定 `"ode15s"`。`"ode15s"` / `"ode23t"`)、`Verbose`(既定 false) |
  | Linearization(新設) | なし | `Method`(既定 `"Feedback"`。`"Kron"` / `"Feedback"` / `"DAE"`)、`Coordinate`(既定 `"theta&rho"`) |
  | 各解析のセクション | なし | `PlotFcn`(既定 `"none"`) |
  | PowerFlowCalculation | なし | `Verbose`(logical、既定 false) |
  | PowerFlowCalculation | `MaxIteration`・`GradientStepSize` の 0 = 自動 | NaN = 自動(0 は 0 回・刻み幅 0。保存した 0 は直してください) |
  | PowerFlowCalculation | `FsolveMaxFunEvals`(0 = 既定) | `FsolveMaxFunctionEvaluations`(NaN = 既定) |
  | OptimalPowerFlow | `Algorithm_linprog`、`Algorithm_quadprog`、`Algorithm_fmincon` | `LinprogAlgorithm`、`QuadprogAlgorithm`、`FminconAlgorithm` |
  | OptimalPowerFlow | `StepTolerance` | `QuadprogStepTolerance`、`FminconStepTolerance` |
  | OptimalPowerFlow | `MaxFunctionEvaluations`、`UseParallel` | `FminconMaxFunctionEvaluations`、`FminconUseParallel` |
  | TimeSimulation | `SeparateComplexParts`(`"on"` / `"off"`) | `SeparateComplexParts`(logical、既定 false) |

  キーの規則: Name-Value と同じ名前・型、1 つのソルバーだけの設定は `<Solver 名><MATLAB のオプション名>`、自動・ソルバーの既定は NaN、オン・オフは logical。

  結果の `res.options` のフィールドも新しい名前です(`res.options.Tolerance`、`res.options.MaxIteration` など)。
- **`SolverOptions` と `Point` は呼び出しだけ。** 時間応答シミュレーションの `SolverOptions`(`matlab.ode.Options`)は呼び出しかシナリオの `Options` でだけ与えます。与えなければ `ode` オブジェクトは `Solver` のオプションを使います。優先順位は `GUILDA.setting` < `sc.Options` < 呼び出しの Name-Value です。線形化の `Point` も呼び出しだけで(既定 `[]` = 平衡点)、保存しません。
- **`Plot` オプションを `PlotFcn` に置き換えました。** `calculate_powerflow`、`optimize_powerflow`、`calculate_continuation_powerflow`、`simulate`、`linearize`、`get_sys` の `Plot`(解析後に `result.Plot()` を呼ぶ)は廃止し、渡すと `GUILDA:resolve_options:UnknownName` で止まります。解析後の図は `result.Plot()` で描いてください。`PlotFcn`(MATLAB の `optimoptions` / `odeset` と同じ名前)は解析中のライブ表示で、値は `"none"`、表示キーの string 配列、または関数ハンドルです。既定は各セクションのキー `PlotFcn`(select、選択肢は `"none"` と各解析のキー)です。
  - 潮流計算 `"residual"`(方程式ごとの残差の棒グラフ。全 Solver)、OPF は fmincon のプロット関数(`"fval"` → `optimplotfval` など。linprog・quadprog では `GUILDA:SolverOPF:PlotFcnUnsupported`)、連続潮流計算 `"pvcurve"`(全母線の PV 曲線を伸ばす)。
  - 関数ハンドルは `stop = f(x, optimValues, state)`(optimoptions と同じ形。OPF は fmincon にそのまま渡す)。
  - 時間応答シミュレーションと線形化は `"none"` のみ(ほかの値は `GUILDA:check_plotfcn:InDevelopment`)。未知のキーは `GUILDA:check_plotfcn:UnknownKey`、別の型の値は `GUILDA:check_plotfcn:InvalidValue` で止まります(`tools.check_plotfcn`)。
  - OPF の既定の表示: 既定(`Verbose` false)ではソルバーは何も表示しません(以前の `Display` `"default"` はソルバーの終了メッセージを表示)。`Export` は変わりません。

---

## 1. Changes so far — script authors

### 1.1 Nominal frequency and system base belong to the network

The network holds `Hz` and `baseMVA` in `net.tab_parameter.base`.
Components no longer have their own `Hz` (`comp.tab_parameter.base` and
`comp.para_base` are removed), and buses no longer have an operation `baseMVA`.

```matlab
% old
comp.tab_parameter.base.Hz          % or comp.para_base.Hz
comp.para_base.Hz = 50;
net.add_bus("baseMVA", 100, ...)

% new
net.tab_parameter.base.Hz           % read / write: whole network
net.tab_parameter.base.Hz = 50;
net.tab_parameter.base.baseMVA = 100;
comp.get_Hz()                       % read-only: frequency of the network the object belongs to
net.add_bus(...)                    % no baseMVA option
```

- `get_Hz()` falls back to `GUILDA.config("Model","Hz")` for an object that is
  not attached to a network.
- CSV import accepts and ignores a `baseMVA` column; CSV export no longer
  writes it.
- Removed without replacement: `rv_odeInit` (PowerNetwork, Bus) and
  `Bus.rv_odeX0`.

### 1.2 Equilibrium V is owned by the bus, I by the components

- `Bus.c_Iequilibrium` is now Dependent: the sum of its components'
  currents.
- `Component.c_Vequilibrium` reads its bus; `LocalController.c_Vequilibrium`
  / `c_Iequilibrium` read the parent.
- Do not write copies of the voltage into a component or controller.

### 1.3 編集の追跡と「古い」状態のエラー

v3 の編集ログ(`tab_editLog`)はありません。各層は、古くなっている部分ごとに理由のメッセージを `sct_stale`(Hidden、読み取り可)に持ちます。空の列は最新の意味です。

| 層 | 古くなるタグ(`sct_stale` のフィールド) |
|---|---|
| `PowerNetwork` | `powerflow`、`odefcn`(系統の Hz) |
| `Component`、`LocalController`、`GlobalController` | `equilibrium`、`odefcn` |
| `Bus`、`Branch` | なし |

- **初期値。** 各タグは作成時に `"initialize has not been run"` を持ちます。各クラスは自分のフィールドにだけ追加し、自分のコードで空にします。
- **メッセージ。** 「編集した層のタグ」+ `": "` + 編集内容(値を含む)。パラメータの編集は「パラメータの区分 `/` 所有者のタグ」、それ以外は編集した層のタグです(1.23)。例: `"dynamics/B001SG1: edit D: 2 -> 2.1"`。重複は解析のエラー表示で除きます。
- **編集の種類(タグ)。** パラメータのグループ名(`dynamics`、`powerflow`、`base`、`operation`、`OPF`、`graph`)、`Topology`、`Slack`、`Tag`。

| 編集 | 古くなるもの |
|---|---|
| 系統の `baseMVA`、母線・ブランチの追加 / 削除 / 置換 | 系統の `powerflow` |
| 母線の `powerflow`・`dynamics`(シャント)、スラック母線の変更、機器の接続 / 置換 / 削除 | 系統の `powerflow` |
| ブランチの `dynamics` | 系統の `powerflow` |
| 機器の `powerflow`(P、Q) | 系統の `powerflow` |
| 機器・制御器の `dynamics`(`local_LQR` の `Q`、`R`、`V0` を含む) | その層の `equilibrium`、`odefcn` |
| ローカル制御器の追加 / 置換 / 削除 | 機器の `equilibrium` |
| 機器・制御器を付ける(`set_bus`、`set_parent`) | 付けた層の `equilibrium`、`odefcn` |
| グローバル制御器の追加 | その制御器の `equilibrium`(系統の `powerflow` は古くならない) |
| グローバル制御器の削除 | なし |
| 系統の `Hz` | 系統の `odefcn`(子へは届かない。各モデルは `initialize` で、ハンドルを作った周波数 `r_odefcnHz` と比べて作り直す) |
| `operation`、`OPF`、`graph`、`Tag`(改名) | なし |

- **最新にするのは `net.initialize()` だけです。** `powerflow` が古いか `Method` を明示したときだけ潮流計算を解き、`Bus.set_equilibrium` で書き込みます。その後、母線 → 機器 → ローカル制御器、ブランチ、グローバル制御器(最後)の順に、各層が自分のタグから判断して、古いハンドルを作り直し、まだ古い平衡点を保持している V と I から計算し直します。最後に系統の `powerflow` と `odefcn` を空にします。何も古くなければ、グローバル制御器の平衡点の再計算(常に行う)のほかは何も変わりません。
  - 動特性だけの編集: 潮流計算を解かず、編集したモデルだけを計算し直します。
  - Hz だけの編集: ハンドルを作り直すだけです(`local_LQR` は保持している平衡点で `K` を設計し直します)。
  - `Method="equilibrium"`: 潮流計算を解きません。`powerflow` が古いときは `GUILDA:PowerNetwork:InitializeEquilibriumEdited` で止まります。
- **解析は検査だけです。** 各解析は自分が使うタグだけを読み、空でないタグがあればメッセージを最大 3 件挙げて、解析ごとのエラーで止まります。何も作り直しません。

  | 解析 | 読むタグ | エラー |
  |---|---|---|
  | `simulate`(`solver_ODE.solve`、`initialize_index` のループ内) | 系統の `powerflow`・`odefcn`、機器・ローカル制御器・グローバル制御器の `equilibrium`・`odefcn` | `GUILDA:SolverODE:Stale` |
  | `linearize`、`net.get_sys`(`solver_LIN.solve`) | 同上 | `GUILDA:SolverLIN:Stale` |
  | `calculate_continuation_powerflow`(`solver_CPF.solve`) | 系統の `powerflow`・`odefcn`、機器の `equilibrium`・`odefcn`(制御器は読まない) | `GUILDA:SolverCPF:Stale` |
  | `comp.get_sys`(`Point` なし) | 系統、機器とその制御器 | `GUILDA:Component:Stale` |
  | `bus.get_sys`(`Point` なし) | 系統、母線の機器(制御器は `comp.get_sys` が読む) | `GUILDA:Bus:Stale` |
  | `con.get_sys`、`con.validate` | 系統、その制御器 | `GUILDA:LocalController:Stale` |
  | `gc.get_sys` | 系統、そのグローバル制御器 | `GUILDA:GlobalController:Stale` |

  検査はソルバーの中にあるので、ソルバーを直接呼んでも検査されます。
- **改名は何も古くしません。** 母線を改名しても、その機器のタグは変わりません(タグは永続的な ID として扱います)。
- **パラメータの型の誤りはエラーです。** 宣言と違うクラスの値を代入すると `GUILDA:Parameter:ClassNameMismatch` で止まり、値も編集履歴も変わりません。以前は MATLAB がリスナー内のエラーを警告に変えていたので、スクリプトは止まりませんでした。`try` / `catch` なしで型の違う値を代入しているスクリプトは、正しいクラスの値に直してください。

```matlab
net.a_Bus{2}.tab_parameter.powerflow.V = 1.02;
net.sct_stale.powerflow      % "powerflow/B002: edit V: 1.025 -> 1.02"
net.simulate([0 10]);        % error GUILDA:SolverODE:Stale
net.initialize();
net.simulate([0 10]);        % OK
```

パラメータを編集して古い(変わらない)平衡点のまま解析していたスクリプトは、編集の後に `net.initialize()` を呼ぶ必要があります。

### 1.4 Topology methods

```matlab
net.remove_bus("B003")                           % error if branches are connected
net.remove_bus("B003", "RemoveBranches", true)   % also removes those branches
net.remove_global_controller("agc")
bus = net.add_bus(...)                           % tag number: largest in use + 1
new = bus.replace_component(...)                 % now returns the new component
net.add_branch(Type, ["B001","B002"], ...)       % buses may be given by tag
```

- **Automatic tags** of buses (`B###`), branches (`###`) and components
  (`<n><bus tag>`, per bus) take the largest number in use + 1, so a new tag
  never equals an existing one. A removed number is not reused while a
  larger one remains (before: `numel + 1`, which could repeat a tag after
  `remove_branch` / `remove_component`).
- `add_global_controller` with a tag already in use is an error
  (`GUILDA:PowerNetwork:GconTagInUse`); the tag is the user's choice.
- `remove_bus` refuses a bus whose components a global controller controls.
- `remove_component`, `replace_component`, `remove_branch`, `remove_bus`,
  `remove_global_controller`, `remove_local_controller` and a controller replaced by
  `add_local_controller` delete the removed object (`delete`; a bus with its
  components, a component with its local controllers). A variable that still holds it
  is an invalid handle (`isvalid` is false) (1.24).
- Buses are created with their network: `Bus(net, tag, opt)`. The separate
  `set_network` step after construction and `reset_odeset` (Bus, Branch,
  PowerNetwork) are gone.
- **存在しないタグの削除はエラーです。** `net.remove_branch` は `GUILDA:PowerNetwork:BranchNotFound` で止まります。複数のタグの一部だけが不明な場合も何も削除しません。以前は不明なタグを無視していました。`bus.remove_component` と `bus.replace_component` は `GUILDA:Bus:ComponentNotFound` で止まります。存在しないタグを渡して無視させていたスクリプトは、`string(net.a_Branch)` や `string(bus.a_Component)` で確かめてから呼んでください。
- **グローバル制御器が制御する機器は削除も置換もできません。** `remove_component` と `replace_component` は `GUILDA:Bus:ComponentControlled` で止まり、何も変えません。先に `net.remove_global_controller(tag)` を呼び、機器を編集してから制御器を作り直してください。
- **`add_branch` の検査。** 次の場合はエラーで止まり、系統は変わりません。

  | ID | 条件 | 対応 |
  |----|------|------|
  | `GUILDA:PowerNetwork:BranchBusIndex` | 母線番号が範囲外 | 先に `add_bus` する。番号は `a_Bus` の添字 |
  | `GUILDA:PowerNetwork:BusNotFound` | 母線タグが不明 | `string(net.a_Bus)` のタグを渡す |
  | `GUILDA:PowerNetwork:BranchSelfLoop` | 両端が同じ母線 | 母線のシャントは `net.add_bus(Gshunt=G, Bshunt=B)` で与える |
  | `GUILDA:PowerNetwork:BranchZeroImpedance` | `R = X = 0`(アドミタンスが無限大) | `R` か `X` を 0 以外にするか、2 つの母線を 1 つにまとめる |

  同梱の系統はすべて通ります。
- **`add_bus` の `FullTag`。** `net.add_bus(FullTag="Sub7")` は自動の番号を付けずにそのタグを使います。使用中のタグなら番号を付けて改名します。
- **タグは MATLAB の変数名として有効な文字列です。** ネットワーク・母線・ブランチ・機器・制御器の `s_tag`(作成時の `PowerNetwork(tag)`、`add_bus` の `Tag` / `FullTag`、CSV の `FullTag` 列、改名)は `isvarname` を満たす必要があり(英字で始まり、英字・数字・`_` のみ、`namelengthmax` 文字以内、予約語でない)、それ以外は `GUILDA:LayerPackage:InvalidTag` で止まります。タグは OPF の変数・制約の名前や struct のフィールド名に使うためです。重複による番号の付与(`<tag>002` など)の後も同じ検査をします。`-` や空白を含むタグは `_` に置き換えてください。同梱の IEEJ_WEST10 のブランチは `LINE20-1` → `LINE20_1`、`G1-TR` → `G1_TR` に変わりました(`Scenario.add_open_branch` などで参照するタグも同様)。
- `_GUILDAsystem/@PowerNetwork/add_branch.m` は通常の追跡対象のファイルです(1.22)。

### 1.5 Single slack bus

The network keeps exactly one slack bus. Setting `bus.l_isSlack = true`
releases the other slack buses (also before the first `initialize`).
Setting it to `false` now releases the bus instead of being ignored.

```matlab
net.a_Bus{3}.l_isSlack = true;   % bus 1 is no longer slack
```

### 1.6 Global and local controllers

Any number of global controllers is supported: `initialize`, `simulate` and
all `get_sys` algorithms (Kron, DAE, Feedback) handle every controller.
Outputs of several controllers on the same input add up. Scalar `alpha` /
`beta` of the AGC are expanded to every controlled unit.

| v3 | v4 |
|----|----|
| `gc.PowerNetwork{1}` (a cell) | `gc.a_PowerNetwork` (the network, or `[]` when detached) |

- `gc.PowerNetwork` is removed without a compat form (reading it is an
  error).
- **Trip of a global controller** (a `Scenario` trip naming the
  controller): its output is zero during the event (silent change, see the box
  at the top), and after the event it restarts from its equilibrium, like
  a tripped generator.
- **Trip of a generator with a local controller** no longer fails with
  `MATLAB:TooManyOutputs`. After the event, the states of its local
  controller and of the controller nested in it restart from their
  `rv_Xequilibrium`; the stored equilibrium does not change. Whether this
  transient after reconnection is physically valid has not been evaluated.
- **Global controllers observe outputs and all bus voltages** (see
  `notes/controller-signal-routing.md`). The inputs `sv_u` of a global
  controller are read on each controlled unit by name, as for a local
  controller: an output in `sv_y` of the unit, otherwise a state in `sv_x`
  (`gc.iv_obsY` / `gc.iv_obsX`). Its port `V` is the voltage of all buses
  `[Vre1; Vim1; Vre2; ...]` in the order of `net.a_Bus` (before: `[]`); a
  branch flow is computed from `V` and the branch data. `add_global_controller`
  accepts a unit that has each name of `sv_u` as an output or a state.
- **Global controller outputs are routed by name**, per controlled unit:
  - to every local controller of the unit (nested ones included) that has an
    input of that name, and then not to the component. The controller input
    receives the sum of what it reads without the global controller (an
    output or state of the component, the output of a nested controller, or
    its equilibrium) and the global controller output;
  - otherwise to the component input of that name, as before. An input driven
    by both a local and a global controller receives the sum.
  - The routing is decided in one place, the connection map
    `[~, ~, ~, tab_connection] = net.get_variable_map()` (rows of `Kind`
    `"global"`, see 1.12). `add_global_controller` prints these connections
    as an INFO line (`Source -> Target` by Label, e.g.
    `Pmech_B001SG1_IEEE9busAGC1 -> Pmech_B001SG1`). Nothing is
    stored on the controller (`gc.sv_route` is removed). When
    `comp.add_local_controller` or `comp.remove_local_controller` changes
    where an output of a global controller of that component goes, the edit
    prints the outputs that go elsewhere now (`GUILDA:Component:GconRouteChanged`;
    `-> (no input)` for an output left without an input); `simulate` prints
    nothing. An output that has no input left stops `simulate` with
    `GUILDA:SolverODE:GconNoTarget`. `Message.ShowInfo` hides the INFO lines.
  - `gc.get_sys` has the bus voltages and the observed signals as inputs, and
    one output row for each input an output drives (labelled as that input),
    both read from the connection map. A controller not added to a network has
    no connections: its inputs and outputs are labelled with its own rows of
    the map (`gc.attach_tag(name + "_" + unit tag)`).
- **Controller inputs are wired by name.** A local controller reads the
  component it is attached to (directly, or through the controller above
  it) by the names of its inputs `sv_u`: a name in the component's `sv_y`
  reads that output, otherwise a name in `sv_x` reads that state (the
  output wins when both exist). The reserved inputs `"Xall"` / `"Yall"`
  read all states / all outputs; the old names `"X"` / `"Y"` stop with
  `GUILDA:LocalController:ReservedInputNames`. An input named like an output of
  a nested controller (e.g. `Vpss`) reads that output. AVR and PSS responses
  are unchanged.
- **Inputs driven by a local controller** (silent change, see the box at the
  top). The controller's outputs drive the component inputs of the same name.
  In `simulate`, an input event or a global controller on such an input adds
  to the output (`u = y + u - rv_Uequilibrium`), as `get_sys` already
  assumed. Before, the output overwrote them, without a warning. Runs with
  such inputs give other numbers.
- **`controller.local_LQR` works again** (v4 contract):
  `comp.add_local_controller(controller.local_LQR(tag, Q=, R=, Input=,
  V0=))`. It reads `"Xall"` and outputs `u = u* - K (x - x*)`;
  `net.initialize` computes `K = lqr(A, B, Q, R)` from `comp.get_sys`
  (without controllers) connected to an infinite bus of voltage `V0`.
  `Q` / `R` default to identity; editing them makes the equilibrium stale.
  Its key `"local"` takes the place of an AVR (the PSS of a replaced AVR is
  detached). A global controller on a driven input adds to its output, and
  the design of `K` does not take it into account (use `Input="Vfield"` with
  an AGC on `Pmech` to keep them apart).
- **Replacing an AVR keeps its PSS.** `gen.add_local_controller(new_avr)`
  moves the PSS of the old AVR to the new one; `add_local_controller(avr,
  pss)` replaces both. A replacement warns
  `GUILDA:Component:ReplaceController` and detaches the replaced
  controller. Before, the PSS was dropped. Adding or replacing is logged (1.3).
- **`local_LQR` と Hz の編集。** 系統の Hz を編集しても平衡点は古くならないので、`K` は編集の時点では変わらず、次の `net.initialize()` がハンドルを作り直すときに、保持している平衡点から設計し直します(潮流計算は解きません)。それまでの解析は止まります(例: `GUILDA:SolverODE:Stale`)。同じ Hz に戻したときは設計し直しません。設計し直しに失敗したときは警告を出し、その制御器の `equilibrium` を古い扱いにします(次の `initialize` が平衡点から設計し直し、失敗すればエラー)。
- **ローカル制御器の削除。** `comp.remove_local_controller(tag)` を追加しました。タグは `s_tag` で指定します。

  ```matlab
  gen.remove_local_controller("CP1");                     % PSS だけ
  gen.remove_local_controller("CA1", RemoveNested=true);  % AVR とその PSS
  ```

  PSS が残っている AVR は `RemoveNested=true` がないと `GUILDA:Component:ControllerHasNested` で止まり、不明なタグは `GUILDA:Component:ControllerNotFound` で止まります。どちらも何も変えません。削除は `Topology` の編集として記録されるので、`net.initialize()` が必要です。削除した制御器は親への参照を持ちません。
- **制御器の接続の検査。** `add_local_controller` は、何かを変える前に次を検査します。

  | ID | 条件 | 対応 |
  |----|------|------|
  | `GUILDA:Component:InvalidControllerKey` | 役割 `s_role`(1.21)が `"avr"`, `"pss"`, `"local"`, `"governor"` のいずれでもない(以前は何も付かなかった) | `s_role` を直す |
  | `GUILDA:Component:ControllerOutput` | 出力が機器や AVR のどの入力にも一致しない。負荷に AVR を付けた場合を含む。`GUILDA:local_LQR:UnknownInput` はこの ID に置き換わった | `sv_y` か `Input=` を直す。ID で捕まえていたコードも直す |
  | `GUILDA:Component:PssParentKey` | `s_role` が `"avr"` でない制御器の下に PSS を付けた | 先に AVR を付ける |
  | `GUILDA:Component:NotExtAvr` | AVR がないのに PSS を付けた | 先に AVR を付ける |

  入力名の綴りの誤りはエラーになりません(平衡点の値を読みます)。`con.validate` の `flag.inputs` に `equilibrium (not connected)` と出るので確認できます(第 2 章)。
- **グローバル制御器の検査。** `GlobalController` の作成時に、不明なタグや機器でない値、別の系統の機器は `GUILDA:GlobalController:InvalidComponent` で止まります。`net.add_global_controller` は、対象の機器がこの系統にないと `GUILDA:PowerNetwork:GconOtherNetwork` で、機器に制御器の `sv_u` の状態や `sv_y` の入力がないと `GUILDA:PowerNetwork:GconPorts` で止まります。後者は以前は `simulate` で初めて失敗していました。機器を削除や置換した後は、制御器を現在の機器で作り直してください。
- **制御器の `tab_parameter` に代入できます。** 機器や送電線と同じ書き方で、編集が記録されます。

  ```matlab
  avr.tab_parameter.dynamics.kap = 200;
  agc.tab_parameter.dynamics.kP  = [200; 300];   % グローバル制御器は対象の機器ごとに 1 行
  agc.tab_parameter.dynamics.kP(2) = 300;
  ```

  動特性の編集として `f_*` と平衡点が古くなるので、`net.initialize()` が必要です。同じ値の代入は編集に数えません。型が違う値は `GUILDA:Parameter:ClassNameMismatch` で止まります。
- **`replace_component` and local controllers.** The new option
  `Controllers` is `"drop"` (default) or `"keep"`:
  `bus.replace_component(tag, Type, Controllers="keep")`.
  - `"drop"`: the new component has no local controllers, as before, but now
    the warning `GUILDA:Bus:ControllersDropped` names them. They stay on the
    replaced component.
  - `"keep"`: they move to the new component with the controllers nested in
    them (a handle to one of them then refers to the new component), and
    `net.initialize()` designs them again. If the new component lacks an
    input they drive or a signal they observe, the error
    `GUILDA:Bus:ControllersNotKept` stops the call and nothing changes. The
    weights of `controller.local_LQR` are kept as given, so a `Q` of another
    size stops `net.initialize()`.

### 1.7 The v4 analysis API (common to 1.8–1.12)

Every analysis is a method `net.verb_noun(Name, Value)` that returns
`[result, flag, output]`:

- `result` is a result object (subclass of `ResultBase`):
  `ResultPF`, `ResultOPF`, `ResultCPF`, `ResultODE`,
  `ResultLIN`. It holds the computed values, `flag`, `output`,
  `options` (the effective settings), `s_solver`, `r_elapsed`,
  `s_network`, `a_PowerNetwork` and `l_success`. Model data stay with the
  network.
- `flag` keeps the solver's exit flag where there is one; `output.message`
  describes the outcome.
- Name-Value options (UpperCamelCase) override the defaults **for this
  call only**: the settings in the analysis section of `GUILDA.setting` and
  the conditions kept in `net.solver_OPF` / `net.solver_CPF`. Neither the
  settings file nor the solver is changed. Edit `GUILDA.setting` (or the
  conditions) to change the defaults for later calls. An unknown name
  stops with `GUILDA:resolve_options:UnknownName`, which lists the accepted
  names.
- Plotting and writing files are methods of the result: `result.Plot()`,
  `result.Export(filename)`, or the option `Export=true|filename` of the
  analysis call. The option `Plot` is removed; `PlotFcn` is the live display
  during the analysis (keys `"residual"` for the power flow, the fmincon plot
  functions such as `"fval"` for the OPF, `"pvcurve"` for the continuation power
  flow, or a function handle; see "解析の設定は GUILDA.setting"). A relative file name is
  relative to the **current folder** (v3 wrote to `GUILDA.pwd`).
- The solvers hold no settings: they keep at most the conditions of their
  network (`solver_OPF`, `solver_CPF`), warm start solutions and caches, and no
  longer keep the network, the last result or intermediate data (see each
  section for removed properties).
- `net.solver_LIN` (`SolverLIN`) is new; `reset_solver` creates all
  five solvers.

### 1.8 Power flow

| v3 | v4 |
|----|----|
| `tab = net.calculate_powerflow()` | `res = net.calculate_powerflow(); tab = res.tab_bus` |
| `[tab, flag, output] = net.calculate_powerflow("dynamic")` | `[res, flag, output] = net.calculate_powerflow(Solver="dynamic")` |
| `net.calculate_powerflow("dynamic", "export", true, "filename", f)` | `net.calculate_powerflow(Solver="dynamic", Export=f)` or `res.Export(f)` (`.json`) |
| `net.solver_PF.rm_response`, `rr_step`, `i_iteration` | `res.cm_Vhistory`, `res.rv_step` |

- オプション: `Solver`(`"newton"` | `"gradient"` | `"levenberg-marquardt"` | `"fsolve"` | `"dynamic"`。開発版の `Method` から改名)、`Tolerance`、`MaxIteration`、`Verbose`、`WarmStart`、`PlotFcn`、`Export`。v3 の潮流計算(fsolve)は `Solver="fsolve"` で、Optimization Toolbox が必要です。
- **設定は GUILDA.setting に置きます。** 既定値は PowerFlowCalculation セクション(`@GUILDA/config/DefaultPowerFlowCalculation.json`)にあり、Name-Value はその呼び出しだけを上書きします(JSON には書きません)。`net.solver_PF` は数値の設定を持ちません。`net.solver_PF.Method = ...`、`.Tolerance`、`.MaxIterations`、`.Display`、`.WhenFailed`、`.gradient`、`.dynamic` などは存在しないプロパティへの代入としてエラーになります。

  | 旧(`net.solver_PF` / JSON キー) | 新(PowerFlowCalculation のキー / Name-Value) |
  |----|----|
  | `Method` | `Solver` |
  | `Tolerance`(0 = 手法の既定) | `Tolerance`(全手法で最大 P/Q 不平衡 [pu]、既定 1e-8) |
  | `MaxIterations` | `MaxIteration`(NaN = 自動: newton 50、gradient 1e6、levenberg-marquardt 100、fsolve 400) |
  | `Display` | `Verbose`(logical、既定 false) |
  | `MaxFunEvals`、`UseParallel` | `FsolveMaxFunctionEvaluations`(NaN = fsolve の既定)、`FsolveUseParallel` |
  | `PlotFcn` | `PlotFcn`(解析中のライブ表示。`"none"` か `"residual"`) |
  | `gradient.StepSize` | `GradientStepSize`(NaN = 自動) |
  | JSON MethodNewtonRaphson `StepSize` | `NewtonStepSize` |
  | `dynamic.Mass`、`Damper`、`foh_PQ`、`t_span` | なし(`MethodDynamic` が自動で決める) |
  | `WhenFailed` | `WhenFailed` |
  | なし | `WarmStart`(既定 true) |

  `@GUILDA/user/DefaultPowerFlowCalculation.json` の v3 の旧キーは読み込み時に変換します(`MaxIterations`、`MaxFunEvals`、`UseParallel` は改名、`Display`、`PlotFcn` は削除、`Tolerance` 0 は削除して既定値。`MaxFunEvals` の変換先は旧名 `FsolveMaxFunEvals` のままで、今は未知のキーとして捨てられます)。MethodNewtonRaphson セクションは廃止しました。連続潮流計算の修正子の設定は ContinuationPowerFlow セクションの `CorrectorMaxIteration`、`CorrectorStepSize`、`Increment` です(値は旧セクションと同じ 1000、1、1e-4)。`@GUILDA/user/DefaultMethodNewtonRaphson.json` は読みません。
- **ウォームスタート。** `WarmStart=true`(既定)は同じ系統の前回の収束解から、`false` はフラットスタート(位相 0、大きさ 1。PV・スラック母線の大きさは設定値 `V`、スラックの位相は設定値 `Varg`)から解きます。解は `net.solver_PF` が保持し、母線・ブランチの追加、削除、置換のときだけ捨てます(パラメータの掃引では保持)。`net.reset_solver()` でも捨てます。`optimize_powerflow` と `initialize` も `WarmStart` を受け付けます(OPF は OptimalPowerFlow セクションの既定 false。連続潮流計算は対象外)。
- **`"dynamic"`。** 仮想ダイナミクスの `Damper` は 1、`Mass` 0、`foh_PQ` 0 で固定し、`t_span` はありません。収束で止まり、内部の安全上限は仮想時間 1e4 です。flag は他の手法と同じ 1/0/-2(0 は仮想時間の上限)で、以前の logical ではありません。`res.rv_step` は ODE のステップの仮想時刻です。
- **初期値 `V0`、`Varg0` の廃止。** 母線の `tab_parameter.powerflow` は `V`、`Varg` だけです。`add_bus(V0=..., Varg0=...)` はエラーになります。初期値は潮流計算・OPF のソルバーが決めます(上のウォームスタート)。
- **`ResultPF.tab_violation`。** 潮流計算は `operation` の制約を課しません。解が違反する制約(母線の `Vmin`/`Vmax`、機器の `Pmin`/`Pmax`/`Qmin`/`Qmax`、ブランチの `Pmax`/`Qmax`/`Smax`/`Imax`/`Vargmax`)を `tab_violation`(列 `Class`、`Object`、`Limit`、`Value`、`Bound`、`Excess`)に記録するだけで、警告もエラーも出しません。
- `ResultPF`: `tab_bus` (Varg, V, P, Q, Vphasor, Iphasor per bus;
  the old output table), `tab_branch` (branch flows), `cm_Vhistory`,
  `rv_step`; `Plot` draws the voltage profile, `Export` writes the bus or
  branch table (`.csv`, Excel) or the history (`.json`, GridSpring viewer).
- Behavior: `Solver="dynamic"` no longer writes the JSON history by default
  (v3 did). The network is not changed, except that a slack bus is selected
  when none is set.
- **Silent change: the automatic slack bus.** v3 always took the first bus. Now
  it takes the first bus with a component with `Q = NaN`, otherwise the first
  bus with a component (then `GUILDA:Bus:SlackWithoutQnan` warns). A network
  whose first bus has such a component is unchanged. Any other network gets
  another slack bus, so its results change; only the INFO message shows it. To
  keep the old choice, set `net.a_Bus{1}.l_isSlack = true`.
  `net.optimize_powerflow` and `tools.network_to_mpc` use the same bus as their
  reference when none is set, but do not set `l_isSlack`. They keep the first bus
  when no bus has a component. The angles of their results are then relative to
  the new reference bus. `tools.slack_bus_index(net)` returns this bus.
- **Silent change: the component that takes the slack power.** v3 gave the
  remaining active power of the slack bus to its first component. Now it goes to
  the first component with `Q = NaN`, so a load added before a generator no longer
  generates power and a CSV round trip keeps the operating point. A slack bus whose
  first component has `Q = NaN` is unchanged, and so is one without such a component
  (the first component still takes the remaining P and Q). Any other network changes
  the power of the components of the slack bus; the bus power and voltages stay. To
  keep the old split, add the components so that the one with `Q = NaN` comes first.
- **Errors instead of the fixed `BUS001` message.** A network without buses stops
  with `GUILDA:PowerNetwork:NoBus`, and a network whose buses have no components
  with `GUILDA:PowerNetwork:NoSlackCandidate`.
- Deprecated, still working:

  | Old form | Warning ID |
  |----------|------------|
  | positional mode `calculate_powerflow("dynamic", ...)` | `GUILDA:Deprecated:CalculatePowerflowMode` |
  | options `"export"` / `"filename"` (with the positional mode or `"filename"`) | `GUILDA:Deprecated:CalculatePowerflowExport` |

  The old export keeps the v3 default file name
  `<yyMMdd_HHmmss>_PFcalculation.json`, now in `GUILDA.pwd` explicitly.
  `"export"` alone is read as the v4 option `Export`.
- Fixed earlier (stage 1): initializing from the stored equilibria works
  (now `net.initialize(Method="equilibrium")`, 1.17), and the dynamic power
  flow holds PV bus voltages at their set values.

### 1.9 Optimal power flow

| v3 | v4 |
|----|----|
| `[bus, cub, flag, output, lambda, prob] = net.optimize_powerflow("methods", "DC OPF")` | `[res, flag, output] = net.optimize_powerflow(Method="DC OPF")` |
| `bus`, `cub`, `lambda`, `prob` | `res.tab_bus`, `res.tab_cub`, `res.lambda`, `res.OPFprob` |
| (cost computed by hand) | `res.r_cost`; branch flows `res.tab_branch` |

- Options: `Method` (`"ELD"` | `"DC OPF"` | `"AC OPF"`, default
  `"AC OPF"`), `Solver` (`"auto"` | `"linprog"` | `"quadprog"` |
  `"fmincon"`), `Tolerance` (`OptimalityTolerance`), `MaxIteration`,
  `Verbose` (the `Display` of the solver: `"iter"` or `"none"`), `PlotFcn`
  (fmincon only), `Export`. Settings in the OptimalPowerFlow section of
  `GUILDA.setting` (keys `Tolerance`, was `OptimalityTolerance`; `Verbose`,
  was `Display`); the conditions `Cost`, `Constraint`, `DefaultCost`,
  `ReferenceBus` in `net.solver_OPF` (`SolverOPF`, new; it was empty in v3).
- `ResultOPF`: `Plot` draws the component outputs and, for DC/AC OPF, the
  bus voltages; `Export` writes the bus, connection or branch table.
  `l_success` is true for a positive exit flag. The nodal price of a bus is
  `-res.lambda.Constraints.balancedP_<bus>`.
- **Output count decides the form** (silent change): only 6 outputs return
  the v3 tuple; 1–3 outputs get the v4 meaning; 4 or 5 outputs are an error
  (too many outputs).
- Deprecated, still working:

  | Old form | Warning ID |
  |----------|------------|
  | 6 outputs `[bus, cub, flag, output, lambda, prob] = ...` | `GUILDA:Deprecated:OptimizePowerflowTuple` |
  | option `"methods"` | `GUILDA:Deprecated:OptimizePowerflowMethods` |
  | `net.build_opf_problem("methods", m)` | `GUILDA:Deprecated:BuildOpfProblemMethods` |

- `net.build_opf_problem` takes the same option name as
  `optimize_powerflow`: `[prob, x0] = net.build_opf_problem(Method="DC OPF",
  validate=false)`.
- Fixes (stage 1 and OPF step 1, see [status.md](status.md#opf)): ELD, DC
  and AC OPF run again; loads keep their power-flow P and Q (not
  dispatched); branch-end variables are `"<branch>_<bus>"`; branch limits
  `Smax`, `Imax`, `Pmax`, `Qmax`, `Vargmax`, with `Imax`/`Smax` applied
  squared; zero cost terms are left out of the objective; branch-end
  variables start at the initial bus voltages. Shipped CSVs whose
  `Pmin`/`Qmin` were `#NAME?` (Excel's `-Inf`) are fixed; check your own.
- New `tools.network_to_mpc(net)` converts a network into a MATPOWER case.
- **Customizing the problem (options).** `SolverOPF` builds the problem from
  `tab_parameter` of the buses, components and branches; user terms are
  Name-Value options of `optimize_powerflow` and `build_opf_problem`
  (conditions kept between runs in `net.solver_OPF`), applied to the whole network:
  - `Cost=@(v, p) <scalar>` is added to the objective; `Constraint=@(v, p)
    struct(name, constraint, ...)` is added, each field becoming
    `prob.Constraints.<name>`, also the label of its dual in
    `res.lambda.Constraints`.
  - `v.Component.(tag).P/.Q`, `v.Bus.(tag).Varg/.V`,
    `v.Branch.(tag).Pfrom/...` address every variable; `p` holds `p.Method`
    and `p.base`.
  - `DefaultCost=false` leaves out the `tab_parameter.OPF` costs;
    `ReferenceBus="auto"|<tag>|"none"` picks the bus with a fixed angle.
  - A default limit of one object is removed by setting it to ±Inf in its
    `tab_parameter.operation` (branch limits: NaN also means none).
  - `optimize_powerflow(Problem=prob, InitialPoint=x0)` solves a problem from
    `build_opf_problem` modified by the user.
  - Bad handles stop with `GUILDA:SolverOPF:InvalidCost`,
    `InvalidConstraint`, `InvalidConstraintField` or `DuplicateName`, or
    with `GUILDA:SolverOPF:HandleError`.
  - OPF settings do not make the equilibrium stale.
- **Default load cost is 0** (silent change in `r_cost`). `add_component`
  gives loads `HP = fP = 0` and other components `HP = fP = 1` (before: 1
  for every component, so a fixed load added a constant to `r_cost`). The
  bundled `IEEE9bus`, `IEEE68bus`, `Ishizaki6Bus`, `TEST31bus` and
  `Txt3Bus` now store 0 for their loads (`IEEE14bus*` already did). A load
  whose Pmin/Pmax (Qmin/Qmax) are finite is dispatched within them
  (price-responsive load, with a cost set explicitly); with infinite bounds
  it keeps its power-flow P (Q) as before.
- **DC OPF susceptance is MATPOWER's** `b = 1/(X·tap)`, with the phase
  shift at the from end (`a_Bus{1}`): the flow from i to j is
  `b·(θi − θj − phase)`. Before, `b = Im(Y_ij)` (`= X/(R²+X²)`), so DC OPF
  results change for branches with `R ≠ 0`, taps or phase shifters.
- **`Solver` must fit the problem.** A `Solver` that cannot express the
  problem (e.g. `"linprog"` with a quadratic cost) stops with
  `GUILDA:SolverOPF:UnsupportedSolver`, which lists the usable
  names; there is no silent fallback.

### 1.10 Continuation power flow

| v3 | v4 |
|----|----|
| `cpf = Continuation_Power_Flow(net, struct("CPFBus", b)); [sol, pred] = cpf.solve;` | `[res, flag, output] = net.calculate_continuation_powerflow(LoadBus=b)` |
| `cpf = ContinuationPowerFlow(net, "CPFBus", b)` | error; use the line above |
| `cpf.CPF_Result.x_sol` / `x_prd` | `res.rm_x` / `res.rm_xPredicted` (full variable layout, lambda in the last row) |
| (read from `x_sol`) | `res.rv_lambda`, `res.cm_Vbus`, `res.sv_bus`, `res.r_lambdaMax`, `res.r_noseStep`, `res.tab_nose`, `res.tab_path` |

Option names:

| v3 (`CPF*` property) | v4 option | ContinuationPowerFlow key (`LoadBus`: `net.solver_CPF` property) |
|----------------------|-----------|---------------------------|
| `CPFBus` | `LoadBus` | `LoadBus` (property) |
| `CPFInitLam` | `InitialLambda` | `InitialLambda` |
| `CPFMaxIter` | `MaxIteration` | `MaxIteration` |
| `CPFStepSize` | `StepSize` | `StepSize` |
| `CPFArcL` | `ArcLength` | `ArcLength` |
| `CPFUseInternal` | `UseInternalState` | `UseInternalState` |
| – | `Tolerance` (default 1e-5), `Verbose`, `Limits`, `PlotFcn`, `Export` | `Tolerance`, `Verbose`, `Limits`, `PlotFcn` (`Export`: call only) |
| `CPFFcn`, `CPFJac`, `CPFInitVal` | not supported | – |

- `flag` is a logical: true when the path passed the nose. `output` has
  `message`, `iterations`, `correctorIterations`.
- `ResultCPF.Plot` draws the PV curves of the load buses; `Export` writes
  the path table.
- Behavior: the network must be initialized (an error names the remedy);
  an empty or unknown `LoadBus` is an error (v3 warned for an empty bus
  list). `SolverCPF()` takes no arguments and holds only the
  condition `LoadBus`.
- Deprecated:

  | Old form | ID | Behavior |
  |----------|----|----------|
  | `Continuation_Power_Flow(net, opt)` | `GUILDA:Deprecated:ContinuationPowerFlowFunction` | warning; returns a `ContinuationPowerFlowV3` with the v3 properties, `solve` and `CPF_Result` (`.x_sol`, `.x_prd`, `.result` = the `ResultCPF`); `net.solver_CPF` is not changed |
  | `SolverCPF(net, Name, Value)` | `GUILDA:v3_cpf_constructor:ContinuationPowerFlowConstructor` | **error** |

  `sol` / `sol_pred` of the wrapper are in the full variable layout (as
  `CPF_Result.x_sol`).

### 1.11 Time simulation

| v3 | v4 |
|----|----|
| `[out, l_stop] = net.simulate(t, ev1, ev2)` | `[res, flag, output] = net.simulate(t, ev1, ev2)` |
| `if l_stop` (stopped early) | `if flag < 1` (`0` TimeLimit, `-1` solver stop) |
| `net.solver_ODE.Reporter = "none"; net.simulate(t, ev)` | `net.simulate(t, ev, Progress="none")` (one call) or the key `Progress` of the TimeSimulation section; assigning `net.solver_ODE.Reporter` is an error |
| `net.solver_ODE.RelativeTolerance = 1e-6; ...` | `net.simulate(t, ev, Tolerance=1e-6)` (one call) or the key `Tolerance` of the TimeSimulation section; assigning the property is an error |
| `out.odeNetwork` | `res.a_PowerNetwork` |

- Options after the events: `Solver` (MATLAB `ode` solver, default
  `"ode15s"`), `SolverOptions`, `Tolerance` (`RelativeTolerance`),
  `AbsoluteTolerance`, `SeparateComplexParts` (logical), `TimeLimit`, `Progress`
  (`"dialog"` | `"disp"` | `"none"`, or true/false), `Verbose`, `PlotFcn`,
  `Export`. Defaults: the TimeSimulation section of `GUILDA.setting`
  (`SolverOptions`: call or `sc.Options` only); `net.solver_ODE` holds no
  settings.
- `ResultODE` stores the trajectory once, in the order of
  `net.get_variable_map()`: `res.rv_t` (times), `res.tab_variable` (the
  rows `x`, `Vre`, `Vim`, `u` of the map at the time of the run, which are its
  leading rows) and `res.rm_variable` (row k at `rv_t(k)`,
  one column per row of `tab_variable`, **including the states of local and
  global controllers**; states of a tripped unit are NaN), plus `res.rm_I`
  (bus currents). `res.get_point(t, tab_map, Side=)` gives the values at a time
  (linear interpolation; `tab_map` is a part of `tab_variable`, e.g. the rows
  `x`, `Vre`, `Vim`, `u` of a bus or component map; a row that is not in the
  result, such as a controller input `uc`, stops with
  `GUILDA:ResultODE:UnknownVariable`).
- `simulate` writes nothing to the models. The DAE vector follows the
  variable map: `z = [x; V; I; u; uc]` (states, bus voltages, then the bus
  currents `I`, which are not in the map, then the component inputs and the
  controller inputs). The positions, the trips, faults and input events of
  each phase are in the run context of `SolverODE` only. At a
  phase boundary the time appears twice; `Side="after"` (default) takes the
  start of the later phase (after the event), `"before"` the end of the
  earlier one.
- `odeResults` is a view with the old layout
  (`res.odeResults.Bus(i).Component(j).X.omega`, `.t`); controller states
  are only in `rm_variable`. New `sv_bus`,
  `c_component`, `Plot(Quantity=...)`, `Export` (`.csv`, `.txt`, `.xlsx`,
  `.xls` table, or `.mat` with `odeResults`, `rm_variable`, `tab_variable`,
  `options`, `flag`, `output`); `odeNetwork` is removed. The table also has
  one column per state of a local or global controller, named by `Label` of
  `tab_variable`, after the bus and component columns. `output` has
  `message`, `tEnd`, `phases`, `nPhases`, `nPhasesDone`, `isSparse`,
  `exception`.
- Behavior:
  - **flag** (silent change, see the box at the top).
  - **A run that does not reach the end time warns.** `net.simulate` always
    warns `GUILDA:PowerNetwork:SimulationIncomplete` when `flag` is not 1,
    also when `flag` is requested; check `flag` and silence this ID if you
    handle the stop yourself. Calling `solver_ODE.solve` directly does not
    warn.
  - On a stop the result holds the trajectories up to `output.tEnd`.
    `output.message` names the phase, its interval and the solver's
    warning text.
  - **A numerical failure keeps the completed phases.** When the solver gives
    up on a phase, `simulate` no longer throws: it returns `flag = -1`, the
    completed phases in the result, and in `output.exception` the
    `MException` (`GUILDA:SolverODE:PhaseFailed`, `InitialConditionFailed`
    or `UnfeasibleDAE`, with the original as its cause); `output.exception`
    is empty otherwise. When the first phase fails, the result has no time
    points and `output.tEnd` is the start time, so check `flag` before reading
    the trajectories. Scripts that caught these errors must test `flag`
    instead.
  - **Other errors during a phase still stop.** An error of an input function
    or a model stops with `GUILDA:SolverODE:PhaseFailed`, or with
    `InitialConditionFailed` / `UnfeasibleDAE` during the retry from a
    recomputed initial condition (phase and interval in the message, the
    original error as its cause). Only the
    solver's identifiers `MATLAB:daeic12:NeedBetterY0`,
    `MATLAB:daeic12:IndexGTOne`, `MATLAB:decic:IndexGTOne`,
    `MATLAB:decic:ConvergenceFail` and the all-zero mass matrix errors of
    the phase count as numerical failures.
  - **Working data is restored.** After every run, also after an error,
    faults, connections and offsets are back at their initial values.
  - Phases that start at rest no longer stop at t = 0 in large networks
    (e.g. `IEEE68bus(LocalController=false)`): bus current residuals below
    the round-off level of their terms are set to zero in the ODE function,
    so ode15s does not read round-off noise as divergence.
  - `TimeLimit` is the wall-clock limit **of the whole run**, checked at each
    solver step, and its default is `Inf` (before: 10 s of each phase; silent
    change, see the box at the top). The default is the key `TimeLimit` of the
    TimeSimulation section (`DefaultTimeSimulation.json`), so a user
    settings file that sets this key keeps its value. Set `TimeLimit=...` if
    a script relied on the old stop.
  - **Sparse matrices.** `simulate` solves with sparse admittance, Jacobian
    and mass matrices. When the solver's index check rejects them
    (`IndexGTOne`), the phase is solved again and the later phases use dense
    matrices; `output.isSparse` is then false. Step counts and values differ
    from earlier versions within the tolerance, so compare results within it,
    not exactly.
  - **`Export` is checked before the run.** A file name whose extension is
    not `.csv`, `.txt`, `.xlsx`, `.xls` or `.mat` stops at once with
    `GUILDA:PowerNetwork:SimulateExport` (before: after the integration, and
    the result was lost).
  - `SolverODE` no longer holds `odeNetwork`, `odeTimeTable`, `odeYmat`,
    `odeResult`, `rv_odeV`; `solver_ODE.simulate(net, ...)` is replaced by
    the internal `solve(net, time, events, options)`.
  - **Event checks.** Before the integration, an event's `InputUnit` must
    be a component of the network (`GUILDA:Scenario:UnknownInputUnit`),
    each `InputName` an input of it (`GUILDA:Scenario:UnknownInputName`,
    the message lists the inputs), and a function `InputValue` must take
    one argument, the time since the event start
    (`GUILDA:Scenario:InvalidNargin`). Errors that used to fail inside
    the integration now stop at once.
  - **イベントの検査の追加。** 次も積分の前に止まります。

    | ID | 条件 |
    |----|------|
    | `GUILDA:Scenario:UnknownFaultBus` | `FaultBus` が系統の母線でない |
    | `GUILDA:Scenario:UnknownTripUnit` | `TripUnit` が機器でもグローバル制御器でもない(ローカル制御器は解列できない) |
    | `GUILDA:Scenario:UnknownOffsetUnit`, `UnknownOffsetState` | `OffsetUnit` が機器でない、`OffsetState` がその状態でない |
    | `GUILDA:Scenario:InvalidTimeSpan` | `TimeSpan` に NaN がある、または順序が逆 |
    | `GUILDA:Scenario:ValueCountMismatch` | 値の数が `OffsetState` や `InputName` の数と合わない(1 つの値は全部に共通) |
    | `GUILDA:Scenario:OtherNetwork` | 別の系統で作ったイベント(構成が同じでも)。実行する系統で作り直す |
    | `GUILDA:Scenario:DuplicateTag`, `ReservedTag` | タグの重複、または `t1`, `t2`, `Properties`, `Row`, `Variables`, 空, `NoAction<数字>` |
    | `GUILDA:Scenario:ScenarioArray` | シナリオを配列で渡した。`net.simulate(time, sc1, sc2)` のように別の引数で渡す |

    イベントは系統のタグや状態数の写しを持たなくなったので、作成後にグローバル制御器を足すなど構成を変えても、そのイベントは使えます。
  - **`simulate` の時間の検査。** `time` は有限で `t0 < tend` の `[t0, tend]`、またはイベントの時間幅を使う `[]` だけです。他の値は `GUILDA:PowerNetwork:SimulateTime` で止まり、理由を示します。以前は 3 点以上の時間を渡すと無言で短い区間だけを計算することがありました。時刻の列が欲しいスクリプトは `res.get_point` で読み出してください。引数の順序(時間、イベント、Name-Value)の誤りは `GUILDA:PowerNetwork:SimulateArguments` で止まります。
  - **初期条件の失敗の説明。** 区間の開始の初期条件が解けない場合は、これまでどおり `flag = -1` で `output.exception` が `GUILDA:SolverODE:InitialConditionFailed` です。`output.message` が理由と対処を示すようになりました。よくある原因は、故障で供給できなくなる定電力負荷(`"load-power"`)です。その負荷を `"load-impedance"` にするか、別の母線を故障させてください。同じ故障が定インピーダンス負荷なら完走することをテストで確認しています。
  - **区間の開始では微分状態を動かしません。** 区間の境界で微分状態はそのまま引き継ぎ、代数変数だけを新しい区間の網で解き直します(解析的なヤコビアンによるニュートン法。`decic` とソルバ自身の初期条件の計算は使いません)。解けなければ `InitialConditionFailed` で止まり、ソルバが微分状態を動かした場合も止まります。以前は、解けないと微分状態も動かして続け、`GUILDA:SolverODE:InitialConditionRelaxed` を警告するだけでした(IEEJ WEST10 の B003 の地絡で回転子角が最大 2.16 rad 跳んでいました)。この警告と緩めた再計算は `8bd906c`(`fix/ode-initial-condition-jump`、統合は `bf7512b`)で削除しました。
  - An event whose `TimeSpan` lies entirely outside the simulation time
    has no effect and warns `GUILDA:Scenario:OutsideTimeSpan` (before:
    ignored silently).
  - **A fault, trip or input needs a duration.** A scalar `TimeSpan` or
    `[t, t]` stops with `GUILDA:Scenario:ZeroLengthTimeSpan` before the
    integration (before: the event lasted until the next phase boundary, so
    it depended on unrelated events). Give `[t_start, t_end]`. An offset alone
    may still use one time.
  - Trip of a global controller or of a generator with a local controller,
    and inputs driven by a local controller: see 1.6.
- **Settings key.** The default progress display is the key `Progress` of
  `@GUILDA/config/DefaultTimeSimulation.json` (was `Reporter`, same values
  `"none"` | `"disp"` | `"dialog"`). User settings files are not converted:
  a user file whose `version` differs from that of its default file (or has
  none) is reset to the defaults with an INFO (`GUILDA:GUILDA:ConfigReset`).
- Deprecated, still working:

  | Old form | Warning ID |
  |----------|------------|
  | `simulate(..., "Reporter", v)` / `"RelativeTolerance", v` | `GUILDA:Deprecated:SimulateOptionName` |

- Fixed earlier (stage 1): `simulate` works without events, clears previous
  phase results, keeps phases inside the requested time range, applies
  offset state events that start after t = 0, and matches event offsets /
  inputs by name (summed per unit). Input functions receive the time since
  the event start.

### 1.12 Linearization

| v3 | v4 |
|----|----|
| `[sys, lin] = net.get_sys(NonUnit=n, Algorithm=a)` | `sys = net.get_sys(Method=a)` (`Algorithm=a` still works with `GUILDA:Deprecated:LinearizeAlgorithm`); `[sys, flag, output] = ...`, `output.result` is the `ResultLIN` |
| `lin = odeLinearizer(net, n, Algorithm=a); sys = lin.get_sys` | `res = net.linearize(); sys = res.get_ss(a)` |
| `lin.Kxx`, `lin.Kxv`, `lin.Kvx`, `lin.Kvv`, `lin.get_DAE` | `res.rm_Axx`, `rm_Axv`, `rm_Bx`, `rm_Avx`, `rm_Avv`, `rm_Bv`, `rm_E` (unreduced DAE in the order of `res.tab_variable`) |
| – | `net.linearize(Point=x)` or `Point={sim, t}`: linearize away from the equilibrium |
| – | `net.get_variable_map()`, `bus.get_variable_map()`, `comp.get_variable_map()` (also the signals and the connection map, see below) |

- Options: `Method` (`"Kron"` | `"Feedback"` | `"DAE"`, default
  `"Feedback"` as in v3), `Point` (call only), `Coordinate`, `PlotFcn`; the
  eigenvalue map is `res.Plot()`. Defaults in the Linearization section of
  `GUILDA.setting`; `net.solver_LIN` holds no settings.
- `res.get_ss(Method)` gives the same A, E, C, D and names as v3
  `get_sys` for every algorithm (checked against a copy of the v3 code in
  F7); `get_ss("DAE", Coordinate=...)` chooses `"theta&rho"` (default),
  `"theta&V"` or `"Vre&Vim"` for the bus variables.
- **DAE `B` sign** (silent change): the rows of the algebraic equations
  have the opposite sign; the input-to-state transfer function of the DAE
  model now equals that of Kron.
- `flag` is true when all Jacobian entries are finite and `Avv` is
  invertible; `output` has `message`, `s_issue`, `l_equilibrium`, `n_x`,
  `n_v`, `n_u`, `rcond_Avv`, `sv_faultBus`. A `Point` or a model
  that is not finite stops with `GUILDA:SolverLIN:PointNotFinite` or
  `JacobianNotFinite`.
- Default outputs of `get_ss` (as v3): `"Kron"` the states, without output
  names; `"DAE"` the dynamic states; `"Feedback"` the states without those of
  the global controllers, with rows for states its connection removes (IEEE68:
  128 states and 144 outputs, 144 states in `"Kron"`). `Input` and `Output`
  select other channels.
- State order of `get_ss` (as v3): `"Kron"` and `"DAE"` put the global
  controllers' states first, then the components; `"Feedback"` puts the
  components first, then the global controllers in the order they were
  added. Find a state by `StateName`, not by position.
- A bus without components (e.g. a pure junction bus) can be linearized: it
  has no states and takes no current.
- **チャネル名で添字できます。** `sys(出力名, 入力名)` は `sys(行, 列)` と同じ結果です。`comp.get_sys`、`bus.get_sys`、制御器の `get_sys` が返すモデルで使えることをテストで確認しています。以前はチャネルと同じ名前のグループが曖昧さのエラーを起こしていました。そのため、`comp.get_sys` と `con.get_sys` が返すモデルの `InputGroup` と `OutputGroup` は空になりました(`con.get_sys` は `tag=false` のときだけ持ちます)。`sys.InputGroup.<名前>` を読むスクリプトは `sys(:, "<名前>")` に直してください。
- **各層の `get_sys` も検査します。** `comp.get_sys`、`bus.get_sys`、`con.get_sys`、`gc.get_sys` は、平衡点を使うとき系統と自分(と使う下の層)のタグを読み、古ければ層ごとのエラー(`GUILDA:Component:Stale` など、1.3 の表)で止まります。`comp` と `bus` で `Point` を渡したときは検査しません(`initialize` までは以前のハンドルのまま)。系統に属さない機器・制御器は、古いハンドルをその場で作ります。
- **`net.rv_Xequilibrium`** は `get_variable_map` の状態の行の順で値を返します(以前は読むと常に失敗しました)。`comp.rv_Xequilibrium_all` は AVR の下の PSS も含みます。
- **解けないモデルのエラー。**

  | ID | 条件 | 対応 |
  |----|------|------|
  | `GUILDA:Bus:NoI2V`, `GUILDA:Component:NoI2V` | `port="I2V"` で `D` が正則でない(機器のない母線、`P = Q = 0` の負荷など。以前は NaN を返した) | `port="V2I"` を使う |
  | `GUILDA:ResultLIN:SingularAvv` | Kron / Feedback で `Avv` が正則でない(`rcond < 1e-14`)。`net.linearize` は止まらず `flag = false`、`output.s_issue = "SingularAvv"` | `output.message` が示す母線電圧を確認する。`DAE` は計算できる |
  | `GUILDA:ResultLIN:NoUnitBus` | Feedback で状態を持つ機器がない | Kron か DAE を使う |
  | `GUILDA:GlobalController:GlobalControllerPort` | `gc.get_sys` で機器に制御器の入出力がない | 対象の機器を直す |
- `NonUnit` は廃止しました (Issue #118)。機器のない母線と、状態がなく I2V 形式を
  持たない母線は自動で判定します。`Bus.l_isNonUnit` も削除しています。互換の扱いは
  4 章の表のとおりです。`Point={sim, t}` reads
  `sim.get_point(t)` and works with local and global controllers;
  `Point={sim, t, "before"}` takes the value before the event at a phase
  boundary (the default is after).
- **`comp.get_sys` / `bus.get_sys` layout** (silent change, see the box at
  the top), the same on each layer:

  | Layer | Inputs | States | Outputs |
  |-------|--------|--------|---------|
  | controller (`con.get_sys`, now public) | `[V; u_con]` | `x_con` | `y_con` |
  | component | `[port; u_mac; u_con]` | `[x_mac; x_con]` | `[port; y_mac; y_con]` |
  | bus | `[port; u_mac, u_con of each component]` | `[x_mac; x_con]` | `[port; y_mac, y_con of each component]` |

  `port` is `[Vre; Vim]` in and `[Ire; Iim]` out for `port="V2I"`, the
  inverse for `"I2V"`. Controllers are listed depth first. States are
  never outputs and every name is unique; an output named like a state of
  its owner is `Y_<name>` (e.g. `Y_omega_B001SG1`). A controller input
  adds to the internal signal it drives (as `u_mac` does). `full` is
  ignored. The `I2V` outputs `y` now account for V being an output, and
  the outputs of a component with controllers keep their tags.
- Removed: `SolverLIN(net, NonUnit, Name, Value)` stops with
  `GUILDA:v3_linearizer_constructor:OdeLinearizerConstructor` (error); `SolverLIN()`
  takes no arguments.

- **行列で線形化し、`Format` で形を選びます。** `net.get_sys`、`bus.get_sys`、`comp.get_sys`、`con.get_sys`、`gc.get_sys` は Control System Toolbox なしで線形化し、`Format` で返す形を選びます。

  | `Format` | `sys` | Toolbox |
  |----------|-------|---------|
  | `"GUILDAorigin"`(既定) | `ResultLIN`。`A`、`B`、`C`、`D`、`E`(`E dx/dt = A x + B u`、`y = C x + D u`)、`StateName`、`InputName`、`OutputName` にモデル | 不要 |
  | `"struct"` | 同じ 8 フィールドの構造体(名前は string の列) | 不要 |
  | `"ss"` | 記述子形式の状態空間モデル(`dss`、v3 と同じ) | Control System Toolbox |

  - `net.get_sys` の `ResultLIN` は `net.linearize` の結果で、`A` … `OutputName` は `Method` と `Input`/`Output` で選んだモデル(`result.options` に保持)。`[sys, flag, output]` の `flag`、`output` は以前と同じ。
  - `res.get_ss(Method, Format=...)` は既定 `"ss"`、`"struct"` なら Toolbox 不要。`net.linearize` の結果の `A` … `OutputName` は `get_ss(options.Method)`(全入力、既定の出力)。
  - 行列は以前の実装と一致(1030 モデル、最大相対誤差 2e-14)。
  - 書き換え例: `sys = net.get_sys(); eig(sys)` → `res = net.get_sys(); eig(res.A, res.E)`、または `sys = net.get_sys(Format="ss")`。
  - LQR 制御器(`controller.local_LQR`、`local_LQR_retrofit`、`+controller/+modeling/get_environment`)は引き続き Control System Toolbox が必要(1.14)。

### 1.13 Network files (CSV, MATPOWER)

| v3 | v4 |
|----|----|
| `net = CsvNetHandler.import(path)` | `net = PowerNetwork.import_csv(path)` |
| `CsvNetHandler.import(path, obj)` (network class constructor) | `PowerNetwork.import_csv(path, Network=obj)` |
| `CsvNetHandler.export(net, "MyNet", savepath=d)` | `net.export_csv(fullfile(d, "@MyNet"))` |
| – | `net = PowerNetwork.import_matpower(mpc)` (`"case14"`, a struct, a file or a function handle) |

- `import_csv` options: `Initialize` (default true), `Network`.
  `export_csv` options: `Overwrite` (an existing folder is otherwise an
  error, `GUILDA:export_csv:FolderExists`), `ClassFile` (default: when the
  folder name starts with `@`).
- Folder format: `network/parameter.csv` holds `Hz` and `baseMVA`; the bus
  column `Slack` marks the slack bus. Folders written before v4 (no
  `network/parameter.csv`) import with the defaults
  (`GUILDA.config("Model","Hz")`, 100 MVA); a bus column `baseMVA` is
  ignored. Equilibria and controllers are not saved.
- **母線の列 `V0`、`Varg0` は読みません。** 古いフォルダの `bus/parameter.csv` にあれば、INFO `GUILDA:import_csv:RemovedColumn` を表示して無視します。`import_matpower` は VM を初期値として使いません(発電機のない母線の `V` には使います)。`tools.network_to_mpc` の VM/VA は母線の平衡点の電圧(`initialize` の前は 1、0)です。
- **保存しない制御器を警告します。** `export_csv` は書き出しを終えた後、制御器が残っていると `GUILDA:PowerNetwork:ControllersNotSaved` で警告し、ローカル制御器(`<機器>/<AVR>/<PSS>`)とグローバル制御器を列挙します。読み込んだ系統には戻らないので、`import_csv` の後に付け直してください。
- **往復でタグを保持します。** 母線、ブランチ、機器の表に `FullTag` 列を追加しました。欠番や改名を含めて保存時のタグが戻ります。`FullTag` のないフォルダや空の値は、これまでどおり自動のタグになります。母線の `Tag` 列は接頭辞(タグの末尾の数字を除いた部分)です。`FullTag` の重複は番号を付けて改名します。
- **`import_csv` は系統を変える前に表を検査します。** 間違ったファイル、列、行番号では `Network=` の系統は変わりません(モデルのキーが不明な場合や潮流の失敗など、検査の後の失敗では途中まで作られることがあるので、作り直してください)。

  | ID | 種類 | 条件 |
  |----|------|------|
  | `GUILDA:import_csv:UnknownColumn` | 警告 | 未知の列。列は無視する(メモの列で止めないため)。綴りの誤りはこの警告で分かる。`dynamics.csv` の列は機器のクラスによるので検査しない |
  | `GUILDA:import_csv:UnknownID` | エラー | `ParameterID` や `OpfID` が参照先にない、または空 |
  | `GUILDA:import_csv:BusRow` | エラー | `From`, `To`, `Bus` が 1 から行数までの整数でない |
  | `GUILDA:import_csv:MissingFile` | エラー | 必要な表がない |
  | `GUILDA:import_csv:NoComponentFolder` | 警告 | `component/` がない |

  メッセージはファイル、行、列を示します。
- CSV import reads the branch columns `tap`/`phase` (as export writes
  them) and `Tap`/`Phase`; both in one file is an error. v3 read only
  `Tap`/`Phase`, so every imported transformer tap was 1.
- CSV import errors have the IDs `GUILDA:import_csv:*` (e.g.
  `DuplicateColumns`, `MissingColumns`); catch them by these IDs.
- `import_matpower` is the inverse of `tools.network_to_mpc`; MATPOWER is
  not needed. Options `GeneratorModel`, `GeneratorParameter`, `LoadModel`,
  `Hz`, `Tag`, `Initialize`. Isolated buses, piecewise-linear and
  higher-degree costs are not supported.
- Deprecated, still working:

  | Old form | Warning ID |
  |----------|------------|
  | `CsvNetHandler.import(path, net, Initialize=tf)` | `GUILDA:Deprecated:CsvNetHandlerImport` |
  | `CsvNetHandler.export(net, ModelName, savepath=d, Overwrite=tf, version=v)` | `GUILDA:Deprecated:CsvNetHandlerExport` |

  `CsvNetHandler` now lives in `_VersionSupport/`. The bundled network
  classes call `PowerNetwork.import_csv(..., Network=obj)`; your own
  network classes that call `CsvNetHandler.import` warn once.

### 1.14 Toolbox はすべて任意

- 必須は MATLAB のみ。潮流計算の既定 `Solver="newton"` は Toolbox なしで動きます。
- 起動時の確認(`check_requirement`)は `@GUILDA/config/ListToolbox.json` の
  Toolbox ごとに「ok」か、無いときに使えない機能(`Warning`)を 1 行ずつ表示します。
  `ListToolbox.txt` は廃止し、「Required Toolbox components ... missing」の文も出しません。
  キーは `tools.require_toolbox` の短縮名(`optim`/`control`/`symbolic`)で、
  `tools.require_toolbox` も Toolbox 名とライセンス名をこのファイルから読みます。
- Optimization Toolbox: 潮流計算の `Solver="fsolve"` と OPF(`optimize_powerflow`、
  `initialize(Method="OPF")`)。無いと `tools.require_toolbox` が
  `GUILDA:require_toolbox:Unavailable` で止めます。
- Control System Toolbox: 線形化の `ss` 出力(`Format="ss"`)と LQR 制御器
  (`controller.local_LQR`、`local_LQR_retrofit`、`+controller/+modeling/get_environment`)。
- Symbolic Math Toolbox: 実行時のコードは使いません(テストで確認)。
  `MethodNewtonRaphson`(`NewtonRaphsonMethod` から改名、別名なし)は Toolbox があれば
  シンボリックの `Fcn`(v3 の `NRMFcn`)も受け付け、無ければ
  `GUILDA:MethodNewtonRaphson:SymbolicUnavailable` で止まります(関数ハンドルを渡し、
  必要なら `Jac`(v3 の `NRMJac`)も渡す)。手書きヤコビアンを確かめる開発用スクリプト(負荷・制御器の
  `validate.m`、未公開の `vsm1axis`)は引き続き必要です。

### 1.15 Bundled networks

- **`network.IEEE14bus` matches MATPOWER `case14`** (100 MVA): line
  charging, load reactive power sign, bus voltage limits 0.94–1.06,
  generator limits and costs; loads have no OPF cost. Its transformer taps
  are read (1.13). All IEEE14bus results change (power flow, OPF,
  simulation, eigenvalues); the measured differences are in
  [status.md](status.md#ieee14のデータとcsvのタップ).
- **New `network.IEEE14bus_NoTap`**: `IEEE14bus` with the transformers
  4-7, 4-9 and 5-6 at tap 1, phase 0.
- **`network.IEEE14bus_lossless` is `IEEE14bus` with R = 0** on every
  branch. Line charging, the bus 9 shunt and the transformer taps stay
  (they take no real power); bus, load and generator data, limits and costs
  are those of `IEEE14bus`. All its results change; against the previous
  `IEEE14bus_lossless` (old data, taps read): bus voltages up to 0.054 pu
  (bus 14), angles 0.33°, slack P unchanged (219.0 MW, no loss), slowest
  mode −0.385 → −0.595, smallest damping ratio 0.037 → 0.035, OPF cost
  2.66 → 7642.59 $/hr (ELD, DC and AC OPF give the same cost).
- **New `network.IEEE9bus`** (WSCC 3-machine) and **`network.IEEE68bus`**
  (NETS-NYPS 16-machine), ported from the GUILDA v2 CSV data:
  `gen-1axis` generators, `load-impedance` loads, and per generator an
  `AVR_ST1` (v2 sadamoto2019: `kap = Ka`, `tap = Te`) and a `PSS1` with
  `kpss = Kpss/Tpss` (the v2 PSS gain includes `1/Tpss`).
  `network.IEEE9bus(LocalController=false)` /
  `network.IEEE68bus(LocalController=false)` build them without AVRs and
  PSSs. The v2 folders are kept for reference in `+network/archive/`
  (the old 68-bus wrapper is `IEEE68bus_v2`). Known issues: see
  [status.md](status.md#同梱ネットワーク).
- There is no network with the v3 IEEE14 data; keep a copy of a v3 export
  to reproduce old results.

### 1.16 Startup and utilities

`GUILDA` starts in `matlab -batch` (no desktop); the tutorial is not opened
there.

- `GUILDA.dictionary` searches the GUILDA folder (`GUILDA.pwd`), not the
  current folder, so it works from any folder; the old load classes in
  `+component/+load/history` and the folders named `archive` (e.g. the v2
  networks in `+network/archive/`) are not listed.
- Removed: the unimplemented `GUILDA.import_MATPOWER` (use
  `PowerNetwork.import_matpower`).
- The startup no longer rewrites the generated signature files when their
  content is unchanged (no spurious file changes in a git checkout).
- **読み込めないクラスの報告。** `GUILDA.dictionary` は読み込めないクラスを `GUILDA:dictionary:ClassNotLoaded` で警告し、元の理由を示します。そのクラスはキーの一覧に載りません。作ったクラスが `add_component` のキーに出ないときは、この警告を確認してください。`+DebugScript` のテスト用クラスは一覧に載らなくなりました。
- **MAT ファイルから読み込んだ系統。** `save(f, "net")` と `load(f)` で、構成、親への参照、`f_*` が読み込んだ系統を指す状態で戻ります。読み込み後も編集の記録、古い平衡点の検出、パラメータの型の検査が働きます。以前は `load` が内部のエラーを無視して空の系統を返し、警告もありませんでした。
  - 機器など下の層の変数だけを保存しても、構成は戻り、読み込んだ層の編集は記録され、型も検査されます(パラメータは表として保存されるため。1.20)。
  - `net.a_Bus`、`net.a_Branch`、`net.a_GlobalController` に直接は代入できません(`MATLAB:class:SetProhibited`)。`add_*` と `remove_*` を使います。
- 開発者向けに `GUILDA.publish_doc` を追加しました。ドキュメントを `gh-pages` ブランチへ公開します。実行したときだけ公開サイトが変わります。

### 1.17 Initialize

| v3 | v4 |
|----|----|
| `[flag, tab, output] = net.initialize()` | `[result, flag, output] = net.initialize()`; `tab = result.tab_bus` |
| `net.initialize("methods", "powerflow calculation")` | `net.initialize(Method="powerflow")` (default) |
| `net.initialize("methods", "optimal powerflow")` | `net.initialize(Method="OPF")` |
| `net.initialize("methods", "calculate from Xequilibrium")` | `net.initialize(Method="equilibrium")` |
| – | `comp.set_input(u)`, then `net.initialize(Method="FixedInput")` (the equilibrium with the inputs held) |

- `result` is a `ResultPF` (`"powerflow"`, and `"equilibrium"` with
  `s_solver = "equilibrium"` and no branch flows) or a `ResultOPF`
  (`"OPF"`, which runs AC OPF).
- Other Name-Value options go unchanged to `calculate_powerflow` or
  `optimize_powerflow` (e.g. `net.initialize(Method="OPF",
  Solver="fmincon")`, `net.initialize(MaxIteration=50)`); unknown names stop
  with `GUILDA:resolve_options:UnknownName`. `"equilibrium"` takes no other
  option. `Solver` chooses the algorithm of that analysis (for the power flow,
  default: the `Solver` of the PowerFlowCalculation section of GUILDA.setting). `WarmStart` is passed on like the other options.
- **`Method="FixedInput"`** (new): the inputs of the components
  (`rv_Uequilibrium`) are held; the states, bus voltages, currents and the
  `Pmech` of the first generator of the slack bus are solved, with the slack
  bus angle 0. Controllers are not in the equations: they take their
  equilibria afterwards (an AVR or governor shifts its reference). Options:
  `Solver` (`"newton"` (default), `"levenberg-marquardt"`, `"fsolve"`),
  `Tolerance`, `MaxIteration` (default: PowerFlowCalculation), `Verbose`,
  `WarmStart`. Inputs are edited with `comp.set_input(u)`: the edit is stale
  (`net.sct_stale.input`), so the analyses and `net.initialize()` stop with
  `InputEdited` until `Method="FixedInput"`; `Method="powerflow"` or `"OPF"`
  replaces the edited inputs (INFO `GUILDA:PowerNetwork:InputOverwritten`).
- **Load properties removed:** `component.load.impedance.Z` and
  `component.load.power.PQ_st` (the same values are `rv_Uequilibrium`).
- **Output order** (silent change, see the box at the top).
- **Failure is an error.** A power flow that does not converge, an
  infeasible OPF, or stored equilibria that do not satisfy the network
  equations stop with `GUILDA:PowerNetwork:InitializePowerflowFailed`,
  `InitializeOPFFailed`, `InitializeEquilibriumFailed` (or
  `InitializeNoEquilibrium`); the network keeps its previous equilibrium
  and stale state (`sct_stale`), and a slack bus that the power flow set is
  released again.
  Before, a failed analysis was written into the network.
- **`"OPF"` and `"equilibrium"` set a real operating point** (silent change,
  see the box at the top). With `"OPF"` the components take P and Q of the
  solution (`result.tab_cub`); with `"equilibrium"` they keep the V and I they
  hold, and their states and inputs are recomputed, so this follows edits of
  dynamics parameters. Before, both used `tab_parameter.powerflow`, and `simulate` then
  returned `flag = 1` while the states drifted.
- **`"equilibrium"` with a stale power flow is an error.** An edit that makes
  the power flow stale (`net.sct_stale.powerflow`: e.g. P of a component, the
  network `baseMVA`, topology, slack bus) stops with
  `GUILDA:PowerNetwork:InitializeEquilibriumEdited`, and the network is not
  changed. Run `net.initialize()` instead. Dynamics edits are recomputed from
  the held V and I, as with the default method.
- **The point that was set is checked.** With every `Method`, `max|Y*V-I|`
  must be below 1e-6, otherwise `initialize` stops with
  `GUILDA:PowerNetwork:InitializeNotEquilibrium`. Here, and when writing the
  point fails, the network does not keep its previous equilibrium: its power
  flow is marked stale, and analyses stop (e.g. `GUILDA:SolverODE:Stale`)
  until `initialize` succeeds.
- **A split network is reported.** When branches do not connect all buses, a
  successful `net.initialize` warns with `GUILDA:PowerNetwork:NetworkIsland` and
  lists the islands: the point is valid when the power of each island balances, so
  the analysis is not stopped. Turn it off with
  `warning("off", "GUILDA:PowerNetwork:NetworkIsland")` if this is intended. A failed
  power flow or OPF on such a network keeps `InitializePowerflowFailed` or
  `InitializeOPFFailed`, and its message lists the islands instead of solver settings.
  `net.calculate_powerflow` called alone does not check this: it warns about nothing,
  and a failure only shows as `result.l_success = false`.
- **The models are evaluated at the point that was set**, with every `Method`, for
  components, local controllers and global controllers. Before, `initialize` passed
  and the error appeared later in `simulate`.
  - A state or input of the wrong size stops with
    `GUILDA:PowerNetwork:InitializeEquilibriumSize`, a model function that returns the
    wrong size (`fcn_I` must be one complex value, not `[re; im]`) with
    `GUILDA:PowerNetwork:InitializeModelSize`, and a model function that stops with
    `GUILDA:PowerNetwork:InitializeModelFailed`. Each names the tag, and the equilibrium
    is left out of date.
  - A residual of 1e-6 or more warns with `GUILDA:PowerNetwork:EquilibriumResidual`, and
    the network stays usable: its states move without a disturbance. The warning lists
    the tags with `|dx|`, `|I - Iequilibrium|` and `|u - source|` (the input against the
    output or state that drives it; for a global controller, its output, which adds to
    the inputs of its units). It can become an error once external models are checked.
    The bundled networks stay below 2e-13.
- **A slack bus should be able to take the remaining power.** Setting
  `bus.l_isSlack = true` warns with `GUILDA:Bus:SlackWithoutQnan` when the bus has
  components and none has `Q = NaN`. `net.initialize` still runs: the first
  component of the bus takes the remaining power, so a load can generate power.
  If a custom component should balance the network, set `Q = nan` on it.
- Deprecated, still working:

  | Old form | Warning ID |
  |----------|------------|
  | option `"methods"` | `GUILDA:Deprecated:InitializeMethods` |
  | old values `"powerflow calculation"`, `"optimal powerflow"`, `"calculate from Xequilibrium"` (with `methods` or `Method`) | `GUILDA:Deprecated:InitializeMethodValue` |

  The old output order cannot be detected and is not converted.

### 1.18 シナリオ(`ODEevent` → `Scenario`)

外乱のイベント `ODEevent` は `Scenario` に置き換わりました。1 つのシナリオが 1 回のシミュレーションの外乱の一覧(外乱ごとに時間区間)を持ち、シミュレーション時間 `Time`、`simulate` のオプション `Options`、説明 `Description`、判定関数 `Judge` も保存できます。シナリオは系統が所有します(`net.a_Scenario`、親の参照 `sc.a_PowerNetwork`)。

| v3 / 旧 v4 | v4 |
|----|----|
| `ev = ODEevent("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008")` | `sc = Scenario("fault"); sc.add_fault("B008", [1,1.05]); net.add_scenario(sc)` |
| `ODEevent(..., "TripUnit", u)` / `"OpenBranch", b` | `sc.add_trip(u, [t1,t2])` / `sc.add_open_branch(b, [t1,t2])` |
| `ODEevent(..., "OffsetUnit", c, "OffsetState", x, "OffsetValue", v)` | `sc.add_offset(c, x, v, t)` |
| `ODEevent(..., "InputUnit", c, "InputName", n, "InputValue", v)` | `sc.add_input(c, n, v, [t1,t2])` |
| 複数の種類を 1 つのイベントに | `sc.add_disturbance(tag, TimeSpan=..., FaultBus=..., OpenBranch=..., ...)`(旧 `ODEevent` と同じ Name-Value) |
| `net.simulate([0,20], ev_fault, ev_open)` | 1 つのシナリオに 2 つの外乱を入れて `net.simulate(sc)`(`sc.Time` を使う)。`net.simulate(time, sc1, sc2, ...)` も使えます |
| 安定判別のスクリプト | `verdict = sc.judge(result)`(既定は `Scenario.out_of_step`) |

- **所有。** `net.add_scenario(sc)` で追加、`net.remove_scenario(tag)` で外します(親の参照も消えます)。タグは系統の中で一意です。他の系統のシナリオを追加すると移動します(親は 1 つ)。別の系統でも使うときは `sc.copy()`(親のない複製)を追加します。シナリオの追加や編集は平衡点を古くしません(編集履歴にも記録しません)。
- **タグの検査。** 外乱は母線、ブランチ、機器を(番号ではなく)タグで指します。系統に属するシナリオへ外乱を足すとき、シナリオを系統へ追加するとき、シミュレーションの開始時(そのときの系統で)に検査します。検査に失敗すると何も追加しません。属していないシナリオの `simulate` は `GUILDA:Scenario:OtherNetwork` で止まります。
- **時間と設定。** `net.simulate(sc)` または `time = []` は `sc.Time`、なければ外乱の時間幅を使います。オプションの優先順位は `GUILDA.setting` の TimeSimulation セクション < `sc.Options` < 呼び出しの Name-Value です。一緒に実行するシナリオの `Time` や `Options` が食い違うときは、呼び出しで与えないと `GUILDA:PowerNetwork:ScenarioTimeConflict` / `ScenarioOptionConflict` で止まります。
- **判定。** `sc.judge(result)` は `sc.Judge(result)` を返します。既定の `Scenario.out_of_step` は、状態 `delta` を持つ機器(同期発電機)の回転子角の基準からの差の絶対値が `Threshold`(既定 360 度)を超えたら `"out-of-step"`、超えずに `flag ~= 1` なら `"incomplete"`、それ以外は `"stable"` を返します。基準 `Reference` は既定がスラック母線の発電機で、`"COI"`(慣性 `M` の重み付き重心)や機器のタグも指定できます。結果は構造体(`Verdict`, `Time`, `Units`, `MaxAngle`, `Reference`, `Threshold`)です。`net.simulate` の `output` には判定を入れません(複数のシナリオを一緒に実行できるため)。文献との比較や一致数の集計は GUILDA には入れず、検証用スクリプトで行います。
- **CSV。** `Scenario.import_csv(path, Network=net)` が 1 つのファイルの複数のシナリオを読み(`Scenario` 列が同じ行が 1 つのシナリオ、1 行が 1 つの外乱)、`Scenario.export_csv(path, net.a_Scenario)` が同じ形式で書きます。列は `Scenario`, `Description`, `ScenarioTimeStart`, `ScenarioTimeEnd`, `Tag`, `TimeStart`, `TimeEnd`, `FaultBus`, `TripUnit`, `OpenBranch`, `OffsetUnit`, `OffsetState`, `OffsetValue`, `InputUnit`, `InputName`, `InputValue` で、リストは `;` 区切りです。`InputValue` の関数ハンドルは CSV に書けず `GUILDA:Scenario:CsvFunctionHandle` で止まります(MAT ファイルに保存してください)。`Options` と既定以外の `Judge` は保存せず、`GUILDA:Scenario:CsvNotSaved` で警告します。
- **メッセージ ID。** `GUILDA:ODEevent:*` は `GUILDA:Scenario:*` になりました(キーは同じ)。`EventArray` は `ScenarioArray` に、一緒に実行するシナリオ間のタグの重複は `DuplicateRunTag` に、シナリオ内のタグの重複は追加の時点の `DuplicateTag` になりました。`add_scenario` / `remove_scenario` の誤りは `GUILDA:PowerNetwork:ScenarioTagInUse`, `ScenarioNotFound`, `NotScenario` です。
- **互換。** `ODEevent(tag, net, Name=Value)` は `_VersionSupport/ODEevent.m` で動き続けます(1 セッションに 1 回 `GUILDA:Deprecated:ODEevent` を警告)。タグ `tag` のシナリオに同じタグの外乱を 1 つ入れて `net` に追加し、それを返します。旧版との違い:
  - 返り値は `Scenario` です。`ev.TimeSpan` などの旧プロパティはなく、`ev.tab_disturbance` の列として読めます(変更はできません)。
  - タグ、状態、入力の検査は作成の時点で行います(以前は `simulate` の時点)。
  - 同じ系統で同じタグの `ODEevent` を作り直すと、前のもの(`ODEevent` で作ったもの)は系統から外れ、その系統で実行できなくなります(ループでシナリオが溜まらないため)。`add_scenario` で追加した同じタグのシナリオがあるときは `GUILDA:PowerNetwork:ScenarioTagInUse` で止まります。
- **内部。** 区間ごとのデータ(有効な外乱、地絡、解列、開放ブランチ、オフセット、入力関数)は `solve` の冒頭で `Scenario.compile` が 1 回だけ作ります(EV5)。モデルの作業データを書くのは `SolverODE` だけです。結果は以前の `ODEevent` と同じ(`rv_t`, `rm_variable`, `rm_I`, `output.phases` が代表的な地絡、解列、オフセット、入力、開放の例でビット単位で一致)です。

### 1.19 文字列と構造体の名前(`str_` → `s_`、`s_` → `sct_`)

型の文字 `s` は文字列だけを表し、構造体は `sct_` になりました(2026-11-05)。互換の別名はありません。

| v3 / 旧 v4 | v4 |
|----|----|
| `obj.str_tag`(すべての層、`Parameter`、`Scenario`) | `obj.s_tag` |
| `bus.str_bustype` | `bus.s_bustype` |
| `res.str_solver`、`res.str_network` | `res.s_solver`、`res.s_network` |
| `linearize`/`get_sys` の `output.str_issue` | `output.s_issue` |
| `comp.sct_edit.str_odefcn`(モデル作者向け) | `comp.sct_stale.odefcn`(古い理由のメッセージ。空なら最新。1.3 と 2.「`set_odefcn` は廃止」を参照) |

- `net.info` と `struct(obj)` の表や構造体の列名、フィールド名も `s_tag`、`s_bustype` になります。
- 名前の対応表は [naming-struct-string.md](naming-struct-string.md) にあります。

### 1.20 パラメータは `tab_parameter` で読み書き(`para_*` の廃止)

各層のパラメータのコンテナは `a_Parameter`(`Parameter` の cell、区分ごとに 1 つ)にまとまり、`para_*` プロパティはなくなりました(2026-11-06)。パラメータは `tab_parameter` で読み書きします。列は区分のタグ(`dynamics`, `powerflow`, `operation`, `OPF`, `graph`, 系統は `base`)です。互換の別名はありません。

| 旧 | 新 |
|----|----|
| `obj.para_X.Y` | `obj.tab_parameter.X.Y`(例: `bus.tab_parameter.powerflow.V`) |
| `obj.para_X.Y = v` | `obj.tab_parameter.X.Y = v` |
| `obj.para_X.tab_parameter` | `obj.tab_parameter.X` |
| `net.para_base.Hz` | `net.tab_parameter.base.Hz`(読むだけなら `obj.get_Hz()`) |
| `comp.tab_parameter.base`、`comp.para_base` | なし(機器は Hz を持ちません。`net.tab_parameter.base.Hz` と `comp.get_Hz()`) |

- `tab_parameter` への書き込みは、変わった値だけを書き込みます。変わらない値は編集として記録されません。値が等しくてもクラスが違うと書き込まれ、`GUILDA:Parameter:ClassNameMismatch` になります。
- 知らない列(例: 機器の `base`)を書くと `GUILDA:PowerSystemModel:UnknownParameterGroup` で止まり、何も書き込みません。
- 複数の値を変えるときは、表を 1 回読んで変えてから 1 回で書き戻すと速くなります(`tp = obj.tab_parameter; tp.dynamics.D = 2; tp.dynamics.M = 10; obj.tab_parameter = tp;`)。
- `GlobalController` の `tab_parameter.dynamics` の行名は `controlledUnits` のタグです。
- `struct(obj)` の結果に `para_*` のフィールドはありません。パラメータは `tab_parameter` のフィールドにあります。
- 各 `Parameter` はパラメータを 1 つの表(`tab_parameter`)として保持します。動的プロパティ(`para.V` のような読み書き)、`add_entry`、`CallbackChanged` はありません。表への書き込みで、パラメータ名(順序は不問)、行数、行名が変わると `GUILDA:Parameter:TableMismatch`、クラスが変わると `GUILDA:Parameter:ClassNameMismatch` で止まり、どちらも何も保存しません。
- MAT ファイルからの読み込みに復元の処理は不要になり、`PowerNetwork.loadobj` と警告 `GUILDA:PowerNetwork:IncompleteLoad` はなくなりました。

### 1.21 制御器はキーで作る(`add_local_controller` / `add_global_controller`)

制御器は `add_component` と同じく、モデルのキーを渡して追加メソッドの中で作ります(2026-11-07)。制御器のオブジェクトを渡す形はなくなりました。互換の形はありません。

| 旧 | 新 |
|----|----|
| `gen.add_local_controller(controller.avr.AVR_ST1("avr1", kap=30))` | `avr = gen.add_local_controller("avr-ST1", parameter=struct(kap=30))` |
| `gen.add_local_controller(avr, pss)` | `gen.add_local_controller("avr-ST1"); gen.add_local_controller("pss-PSS1")`(1 回に 1 つ。PSS は今の AVR の下) |
| `net.add_global_controller(controller.agc.broadcast_PI_AGC(net, "agc", g1, g2, kP=100))` | `agc = net.add_global_controller("agc-PI", {g1, g2}, parameter=struct(kP=100))`(機器はタグの配列でも可) |
| `con.key == "avr"`(役割) | `con.s_role == "avr"` |
| `remove_local_controller("CAavr1")` | `remove_local_controller(avr.s_tag)` |

- キー: `avr-ST1`, `avr-DC1`, `pss-PSS1`, `gov-LPT1`, `gov-LPT3`, `gov-LPT4`, `local-LQR`(ローカル制御器)、`agc-PI`(グローバル制御器)。一覧は起動時に `GUILDA.dictionary` から作ります(`add_component` と同じ)。`controller.local_LQR_retrofit` は抽象クラスのままでキーはありません。
- `parameter` はコンストラクタの Name=Value の struct か 1 行の table です。省いたものはクラスの既定値になります。
- 両メソッドは作った制御器を返します。タグは自動で付きます。ローカル制御器: 機器のタグ・種類の頭文字・番号(例: `B001SG1CA1`、`B001SG1CP2`)。グローバル制御器: 系統のタグ・`AGC`・番号(例: `PowerNetworkAGC1`)(1.23)。番号は使用中の最大 + 1 です。同梱の系統(`network.IEEE9bus` など)の制御器のタグも変わりました。
- 制御器クラスの `key` はモデルのキー(機器の `"gen-park"` と同じ)になり、付ける場所を表していた役割(`"avr"`, `"pss"`, `"local"`, `"governor"`, `"agc"`)は定数プロパティ `s_role` に移りました。新しい制御器クラスは具象クラスに `key`、自身か基底クラスに `s_role` を定義し、コンストラクタを `(tag, Name=Value)`(グローバル制御器は `(net, tag, 機器..., Name=Value)`)にします。追加後に `GUILDA` を実行するとキーの一覧に載ります。
- `GUILDA:Component:SharedController` はなくなりました。呼び出しのたびに新しい制御器を作るので、別の機器に付いた制御器を付け直すことは起きません。外した制御器を付け直すこともできません(同じキーでもう一度追加します)。`InvalidControllerKey` と `PssParentKey` は `s_role` を調べます。
- `add_local_controller.m` と `add_global_controller.m` は、ほかのキーで作るメソッドと同じく通常の追跡対象のファイルです(1.22)。

### 1.22 キーの一覧は生成しない(`GUILDA.keymap`、テンプレートの廃止)

キーで作るメソッド(`Bus.add_component`、`Bus.replace_component`、`PowerNetwork.add_branch`、`Component.add_local_controller`、`PowerNetwork.add_global_controller`)は、テンプレートから生成するファイルではなく、通常の追跡対象の `.m` ファイルになりました(2026-11-08)。`template/` フォルダと `.gitignore` の 5 行はなくなりました。

- **キーの出所は各クラスの定数 `key` だけ。** 静的メソッド `GUILDA.keymap(category)`(`"Component"`、`"Branch"`、`"LocalController"`、`"GlobalController"`)が、キー(string)からクラス名(string)への `dictionary` を返します。初回の呼び出しで `GUILDA.dictionary` から作り、persistent 変数に保持します。
- **検証。** `Key` は検証関数 `tools.mustBeKeyOf(Key, category)` で確かめます。未知のキーのエラーは `GUILDA:mustBeKeyOf:UnknownKey` で、使えるキーの一覧を示します(以前は MATLAB の `mustBeMember` のエラー)。
- **振り分け。** `switch` の代わりに、`GUILDA.keymap(category)` で引いたクラス名を `str2func` でハンドルにしてコンストラクタを呼びます。関数ハンドルではなくクラス名を保持するのは、モデルのコンストラクタが `Access={?Bus}` などで、呼び出すクラスの中でハンドルを作る必要があるためです。
- **`GUILDA.update_keymap`** はファイルを書かず、`GUILDA.keymap` のキャッシュを作り直してキーの一覧を表示します。起動時(設定 UpdateKeyMap)に呼ばれるほか、モデルクラスを追加・削除した後に再起動せずに呼べます。
- **コード補完。** `_GUILDAsystem/resources/functionSignatures.json`(追跡対象)が、キーで作るメソッドと `remove_component`・`remove_branch`・`remove_bus`・`remove_global_controller`・`remove_local_controller` の補完候補を与えます。`Key` にはそのカテゴリのキー、タグの引数にはそのオブジェクトの今のタグ(例: `bus.replace_component(` で、その母線の機器のタグ)が出ます。JSON の項目は `arguments` ブロックの候補を置き換えるため、全引数を含みます。
- **開発者向け。** これらのメソッドの `arguments` ブロックを変えたら `GUILDA.update_keymap(Signature=true)` で JSON を作り直します(内容が変わったときだけ書きます)。名前・種類・クラス・既定値は `?Class` のメタデータから、説明は各引数の行末のコメントから取ります。テスト `test_F34_signatures` が JSON と `arguments` ブロックの一致を確かめます。
- タグの候補は、変数がワークスペースにあるときだけ出ます(エディターでコードを実行する前は出ません)。キーの候補は常に出ます。

### 1.23 Parent-first automatic tags; variable labels are `<name>_<s_tag>` (`get_tag` removed)

**Automatic tags read parent first** (2026-11-12): the tag of the parent,
then the class header, then the number. Buses (`B001`) and branches
(`EL004`) have no parent part and do not change.

| Object | before | now |
| --- | --- | --- |
| component | `SG1B001`, `LPQ1B008` | `B001SG1`, `B008LPQ1` |
| local controller | `CA1SG1B001` | `B001SG1CA1` |
| local controller under the AVR (PSS) | `CP2SG1B001` | `B001SG1CP2` |
| global controller | `AGC1PowerNetwork` | `PowerNetworkAGC1` |

- The numbering is the same: per bus for components; across all the local
  controllers of a component, nested ones included; per network for global
  controllers. The number suffix `%.3d` that `set.s_tag` adds to a tag in
  use stays at the end.
- `Bus.replace_component` keeps the number of the replaced component
  (`B001SG2` replaced by a load is `B001LPQ2`). A component added to a renamed bus takes the new
  bus tag first (`BXSG1`); the tags of existing children do not follow.
- `tools.next_tag_number(sv_tags, s_prefix)` counts the tags that start
  with the parent tag (it took a suffix before).
- The model constructors still pass the header and the number (`"SG" +
  index`, `"CA" + tag`, `"AGC" + tag`). The base classes put the parent tag
  in front: `Component` takes the bus tag from the field `BusTag` of its
  options (set by `add_component` and `replace_component`), and
  `GlobalController` takes the tag of its network, so the messages of the
  constructors already name the full tag. `add_local_controller` puts the
  component tag in front after the constructor.

**Labels** made by `attach_tag` (the names of states, inputs and outputs in
`get_sys`, `linearize` and `ResultLIN`, the `Label` column and the
`Source` / `Target` columns of `get_variable_map`, the INFO line of
`add_global_controller`, the controller columns of `ResultODE.Export`) are
the name, `"_"` and the tag of the owner layer. Before, the tags of all the
parents up to the network were appended. A generated tag starts with the tag
of its parent, so the labels stay unique within a network.

| | v4 before | now |
| --- | --- | --- |
| component state | `delta_SG1B001_B001_PowerNetwork` | `delta_B001SG1` |
| local controller state | `omega_CP2SG1B001_CA1SG1B001_SG1B001_B001_PowerNetwork` | `omega_B001SG1CP2` |
| bus voltage | `Vre_B001_PowerNetwork` | `Vre_B001` |
| output named like a state | `Y_omega_SG1B001_B001_PowerNetwork` | `Y_omega_B001SG1` |
| global controller state | `xi_AGC1PowerNetwork_PowerNetwork` | `xi_PowerNetworkAGC1` |
| global controller signal of a unit | `Pmech_SG1B001_AGC1PowerNetwork_PowerNetwork` | `Pmech_B001SG1_PowerNetworkAGC1` |

- The signals of a global controller per controlled unit are
  `gc.attach_tag(name + "_" + unit tag)`, as before.
- No compatibility: an old tag or a label with the old suffix is not
  recognized (e.g. in `add_global_controller`, `Scenario.add_offset`,
  `get_ss(Output=...)` or `sys(name, name)`). Use `string(obj)` or
  `obj.attach_tag(name)`, or read the labels from `get_variable_map`,
  instead of writing them out.
- Messages of edits (`log_edit`, `sct_stale`, the `Stale` errors) name the
  edited layer only: `"<tag>: <log>"`, and for a parameter
  `"<group>/<owner tag>: <log>"` (`powerflow/B001: edit V: 1.06 -> 1.02`,
  before `powerflow/B001/IEEE14bus: ...`). A layer renamed after it was
  added is named by its new tag; its children keep their tags.
- Removed: `LayerPackage.get_tag` (private; it built the parent chain).
- Known limit: a user-set tag equal to the tag of a non-sibling layer (two
  components tagged `G1` on different buses) gives the same labels on both;
  the lookups by `Owner` do not tell them apart either. Keep tags unique in
  the network.

---

### 1.24 モデルの物体は追加メソッドで作り、外すと削除する(Issue #119)

- **作成。** 機器・ブランチ・ローカル制御器・グローバル制御器は、キーで作るメソッド(`add_component`、`replace_component`、`add_branch`、`add_local_controller`、`add_global_controller`)の中でしか作れません。具体クラスのコンストラクタを直接呼ぶと `MATLAB:class:MethodRestricted` で止まります(例: `controller.avr.AVR_ST1("1")`、`component.generator.park("1", nan, opt)`、`branch.pi("1", opt)`)。以前は制御器、発電機、ブランチのコンストラクタは公開でした。
- **削除。** 外した物体は `delete` されます(1.4)。外した制御器を別の機器に付け直したり、外した機器を読んだりしていたスクリプトは、キーで新しく作ってください。`replace_component` の `Controllers="drop"`(既定)で残らなかったローカル制御器も削除されます。
- **親のない物体の扱いの廃止。** 親のない物体がなくなったため、それを前提にした動作もなくなりました: 系統にない層の `get_sys` が古いハンドルを作り直す動作、`comp.c_Vequilibrium` / `con.c_Vequilibrium` が `[]` を返す動作、`gc.get_sys` の系統外の名前付け、`get_Hz` の `GUILDA.config("Model","Hz")` への切り替え。エラー ID `GUILDA:Component:InputNotConnected`、`GUILDA:LocalController:ValidateNotAttached`、`GUILDA:local_LQR:NotOnComponent`、`GUILDA:PowerNetwork:GconOtherNetwork`、`GUILDA:SolverODE:ForeignControlledUnit` はなくなりました(起きえない状況の検査)。

## 2. Changes so far — model authors

新しいモデルの実装手順は `_GUILDAdoc/developer/model-implementation.html` を見てください。

- **コンストラクタのアクセス(Issue #119)。** 具体クラスはコンストラクタを作成する親クラスにだけ公開します: 機器は `methods (Access={?Bus})`、ローカル制御器は `{?Component}`、ブランチとグローバル制御器は `{?PowerNetwork}`。基底クラスを呼ぶだけでも宣言が必要です(コンストラクタのないクラスは公開の既定のコンストラクタを継承するため)。property の set メソッドは属性のない `methods` ブロックに置く必要があるので、コンストラクタとは別のブロックにします(`controller.local_LQR`)。メソッドの中では親が常にあるものとして書き、`isempty(obj.a_Bus)` などの検査は書きません(`class-design.html#parents`)。

- **Function signatures** (no bus current, no output feedthrough; see
  `notes/controller-signal-routing.md`). A component has
  `fcn_dx(obj, t, x, V, u, param, omega0)`, `fcn_I(obj, t, x, V, u, param, omega0)`,
  `fcn_Mass(obj, t, x, V, u, param, omega0)` and `fcn_Y(obj, t, x, V, param, omega0)`:
  the output takes no input `u`, so no algebraic loop runs through the inputs. A
  local or global controller has `fcn_dx`, `fcn_y`, `fcn_Mass` with
  `(t, x, V, u, param, omega0)`. The argument `I` (the bus current, the sum of all
  components on the bus) is removed everywhere, without a compatibility layer: a model
  with the old signature stops with a MATLAB error about the number of arguments. A
  model that read `I` computes the current from its states and `V`
  (`I = conj(S/V)` for a power). Declare the functions with `omega0` in the
  `classdef` too. The handles are `f_dx`, `f_I`, `f_Mass`, `f_JacobiDx`,
  `f_JacobiI` `@(t,x,V,u)` and `f_Y`, `f_JacobiY` `@(t,x,V)` for a component,
  and `@(t,x,V,u)` for a controller. `get_sys(x, V, u)` and `get_hessian(x, V, u)`
  of components and controllers drop `I` too; the Hessians are with respect to
  `z = [x; V; u]` (`[x; V]` for `Hessian_Y` of a component).
- **`omega0` is the nominal frequency in Hz**, not rad/s. Multiply by
  `2*pi` inside the model where needed. It is the network's `get_Hz()`.
- **Parameters are on the system base** (`net.tab_parameter.base.baseMVA`).
  There is no per-bus or per-component base.
- **パラメータの読み書きは `tab_parameter`。** モデルのメソッドでも `obj.para_dynamics.Xs` ではなく `obj.tab_parameter.dynamics.Xs` を使います(1.20)。コンストラクタでのエントリの追加は `a_Parameter` のタグの形です:

  ```matlab
  % 旧: obj.para_dynamics.add_entry("Ka", opt.Ka, "double", "Te", opt.Te, "double");
  obj.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", obj.a_Parameter)} = Parameter(obj, "dynamics", struct("Ka", opt.Ka, "Te", opt.Te));
  ```

  `add_entry` はありません。既定値を struct(フィールド: パラメータ名、値: 既定値)で `Parameter` に渡し、`dynamics` のコンテナを 1 行で置き換えます。各パラメータのクラスは既定値のクラスで、`add_entry` の第 3 引数のようなクラスの指定はありません(`"double"` なら既定値を double にします)。行が複数のパラメータ(`GlobalController` の制御対象ごとの値など)は N 行の列ベクトルで渡します。発電機のように table から作るときは `table2struct(tab)` を渡します。

  多数の層を回す内部のコードは、表を作らずに同じタグの形で 1 行で読めます(例: `b.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", b.a_Parameter)}.tab_parameter.Gshunt`)。
- **Analytic Jacobians** are `Static` methods named exactly `Jacobi_dx`,
  `Jacobi_I`, `Jacobi_Y`, declared in `methods (Static)` and implemented in
  files with the same names (case matters: `Jacobi_Y`, not `Jacobi_y`):

  ```matlab
  methods (Static)
      [Axx,Bxv,Bxu] = Jacobi_dx(t,x,V,u,param,omega0);
      [Cyx,Dyv]     = Jacobi_Y(t,x,V,param,omega0);      % a component: no u
      [Cix,Div,Diu] = Jacobi_I(t,x,V,u,param,omega0);
  end
  ```

  The blocks of `I` (`Bxi`, `Dyi`, `Dii`) and `Dyu` of a component are removed. A
  controller has `[Axx,Bxv,Bxu] = Jacobi_dx(...)` and `[Cyx,Dyv,Dyu] = Jacobi_Y(...)`
  with `(t,x,V,u,param,omega0)`; for a global controller `Bxv` and `Dyv` have
  `2*numel(net.a_Bus)` columns. `GUILDA:Component:CurrentDependence` is removed.

  A missing Jacobian falls back to a numerical one (`Jacobi_*_num`).
  `get_sys` and `SolverODE` use the same `f_Jacobi*` handles.
- **The old `getJacobiAxx` / `getJacobiBxu` / … style is no longer used.**
  Per-matrix files are ignored; port them to the three `Jacobi_*` methods.
- **Frequency inside a model:** read `obj.get_Hz()`, never a fixed `60`.
- **`set_odefcn` は廃止。** `f_*` ハンドルは `net.initialize()` が作ります。
  古いとき(`sct_stale.odefcn` が空でない、またはハンドルを作った周波数
  `r_odefcnHz` が系統の Hz と違う)だけ、各層の `initialize` から protected メソッド `set_odefcn` を呼び、
  現在のパラメータと系統の周波数から作り直し、`odefcn` を空にします。解析は
  作り直さず検査だけです。`s_odefcn`、`set_odefcn`、`mark_odefcn` はありません。
  - コンストラクタで `obj.set_odefcn()` を呼んでいたモデルは、その行を削除します
    (残すと未定義のメソッドでエラーになります)。
  - 自分でハンドルを作っていたモデル(`set_odefcn` をオーバーライドしていたクラス)は、
    `set_odefcn` をオーバーライドし、最後に `r_odefcnHz` を設定して
    `obj.sct_stale.odefcn = strings(0,1);` とします(例: `controller.local_LQR`)。
- **Equilibrium:** `get_equilibrium(obj, c_V, c_I, r_P, r_Q)`; do not store
  copies of V or I (see 1.2).
- **Controllers:** local controllers receive their parent through
  `set_parent`; a PSS is attached to its AVR. A local controller observes
  its component by the names of its inputs (an output of that name, else a
  state; `"Xall"` / `"Yall"` for all states / outputs, see 1.6); a class
  that uses the reserved names overrides `set_inputs`, otherwise it stops
  with `GUILDA:LocalController:ReservedInputNoOverride`. Global controllers are
  coupled to components by port names (`sv_u` / `sv_y`): they observe outputs
  (else states) and drive inputs of local controllers or components (1.6). The
  outputs of a global controller must be 0 at its equilibrium.
- **Inputs driven by a controller.** A controller output does not overwrite
  the component input in `simulate`: an input event or a global controller on
  it adds (see 1.6). `Component.get_dx_algebraic` and
  `LocalController.get_dx_algebraic` are removed: `SolverODE` evaluates each
  block (component, local controller, global controller) from its own `x`,
  `V` and `u` with the `f_*` handles. Every controller input is an algebraic
  variable of the DAE, like a component input, with the residual
  `u - (sum of its sources) = 0` built from the connection map; the outputs
  `y` are computed from `x`, `V` (and `u` for a controller) at each evaluation.
  A component output still takes no `u`, so the DAE stays index 1.
- **Working data of a simulation.** The models hold none: `iv_odeX`,
  `iv_odeU`, `iv_odeY`, `iv_odeI`, `lv_odeUfromLC`, `iv_odeYtoU`,
  `Component.l_isConnect`, `Bus.l_isFault`, `rv_Xoffset`, `rv_Uoffset` (of
  components and controllers) and `GlobalController.l_isConnect` are
  removed. `SolverODE.build_index` builds the positions of a run from the
  variable map and the connection map, and the trips, faults and input events
  of each phase stay in the run context. A model must not read any of them.
- **モデルへの要求の明文化。**
  - `get_equilibrium` は常に `c_V`, `c_I`, `r_P`, `r_Q` の 4 引数で呼ばれます。解列のときは `c_I = r_P = r_Q = 0` です。`nargin` で分岐しているモデルは 4 引数で動くように直してください。`LocalController` と `GlobalController` でも `get_equilibrium` は `Abstract` として宣言されています。
  - `fcn_Mass` は定数です。`simulate` は `t, x, V, u` を空にして呼びます。これらを使う `fcn_Mass` は `GUILDA:read_mass:NotConstant` で止まり、機器や制御器のタグを示します。
  - `getCompPQ(obj, x, V, u, param)` は `UseInternalState=true` の連続潮流でだけ必要です。ない機器は `GUILDA:build_layout:MissingGetCompPQ` で止まり、タグを示します。
- **コンストラクタのエラー。** 発電機の基底クラスは次を検査します。表の列の不足は `GUILDA:Component:MissingParameter`(不足する列と参照先を示す)、不明なパラメータ名は `GUILDA:Component:UnknownParameter`(使える名前を示す)で止まります。発電機に与えた `Q` は潮流が決めるので無視され、`GUILDA:Component:GeneratorQIgnored` で警告します(`Q` を省略するか `NaN` にしてください)。追加の列は受け付けます。コンストラクタを持たない負荷のサブクラスも動きます。
- **`validate` の修復。** `comp.validate` と `con.validate` は現行の API で動きます。従来の表に、次の 2 つが加わりました。
  - `flag.contract`: 各検査の状態(`PASS`, `FAIL`, `INFO`)です。壊れたモデルでも止まらず `FAIL` として報告し、計算できない値は NaN にします。寸法、`fcn_I` が複素スカラーか、`fcn_Mass` が定数かなどを見ます(モデル関数は母線電流を受け取らないので、`I` への依存の検査はありません)。
  - `flag.inputs`: 各入力の接続元です。綴りの誤りは `equilibrium (not connected)` と出ます。

  `comp.validate` は平衡点で、未設定なら単位長の V と I の乱数点で評価します。乱数点では値を保持するモデル(負荷など)がその点の値を保持するので、後で `net.initialize()` を実行してください。`con.validate` は系統上の機器に付いて初期化された制御器が対象で、そうでなければ `GUILDA:LocalController:ValidateNotAttached` で止まります。
- **AVR の範囲外のエラー。** `AVR_ST1` と `AVR_DC1` の平衡点が範囲外のときは `GUILDA:AVR_ST1:InvalidValueRange`、`GUILDA:AVR_DC1:InvalidValueRange` で止まり、必要な出力と上下限を示します。
- **Variable map.** `net.get_variable_map()` (and `bus.` / `comp.`) is the
  single definition of the variable order and lists every signal: `x`
  (per bus, per component, then its local controllers depth first; then the
  global controllers), bus voltages `Vre`, `Vim` interleaved per bus, `u`
  (component inputs), `uc` (inputs of the local controllers, then of the
  global controllers, one set per controlled unit), then the signals `y`
  (component outputs) and `yc` (controller outputs). The new column `Role`
  is `"variable"` (`x`, `Vre`, `Vim`, `u`, `uc`) or `"signal"` (`y`, `yc`).
  The rows `x`, `Vre`, `Vim`, `u` come first, unchanged: they are the
  variables of the linearization (`Point`, `ResultLIN.tab_variable`). The
  `Label` column equals the StateName / InputName / OutputName of `get_sys`.
  Do not rely on any other ordering.
- **Connection map.** The fourth output of `net.get_variable_map()` (the
  second of `comp.`, the third of `bus.`) is `tab_connection`, one row per
  connection: `Kind` (`"local"`, `"observe"`, `"equilibrium"`, `"global"`),
  `Source`, `Target` (Labels), `SourceIndex`, `TargetIndex` (rows of the
  map). It is the only place where routing is decided; `simulate`,
  `add_global_controller`, `gc.get_sys` and `validate` read it.
- **Hessians (optional).** `get_hessian` on `Component`, `LocalController`
  and `GlobalController` defines the contract: a class that supports it
  adds static `Hessian_dx` (required), `Hessian_I`, `Hessian_Y` with the
  arguments of `Jacobi_*`, returning `n_eq x n_z x n_z` with
  `z = [x; V; I; u]`. No shipped model implements it yet; other classes
  stop with `GUILDA:Component:HessianNotSupported`. No symbolic
  differentiation is used.

---

## 3. Planned v4 API changes (not implemented yet)

Everything that was listed here is implemented (sections 1.7–1.13 and
1.17): result classes, `[result, flag, output]` (also for `initialize`),
UpperCamelCase Name-Value options over `GUILDA.setting` defaults,
`net.calculate_continuation_powerflow`, `PowerNetwork.import_csv` /
`import_matpower`, `net.export_csv`, `Plot` / `Export` as result methods,
and simulation results in the order of `get_variable_map`. Open follow-ups
(e.g. external OPF backends) are in [status.md](status.md#未決事項).

---

## 4. Compatibility policy

- Breaking changes are acceptable. Compatibility is added only where it is
  easy.
- **All compatibility code lives in `_GUILDAsystem/_VersionSupport/`.**
- A hook in core code is **a single line tagged `% COMPAT(v3)`** that calls
  into `_VersionSupport/`.
- Deprecated forms warn once per MATLAB session through
  `_VersionSupport/Deprecated.m` with ID `GUILDA:Deprecated:<Key>`; texts in
  `SystemTools/GUILDA/en/Deprecated.xml`.
  - Silence: `warning("off", "GUILDA:Deprecated:<Key>")`
  - Show again: `clear Deprecated`

### Deprecated forms

| Old form | ID | Behavior |
|----------|----|----------|
| `net.add_bus(..., "baseMVA", x)` with x = system base | `GUILDA:Deprecated:BusBaseMVA` | warning; ignored |
| `net.add_bus(..., "baseMVA", x)` with x ≠ system base | `GUILDA:Deprecated:BusBaseMVAMismatch` | warning; ignored, system base used |
| `calculate_powerflow(mode, ...)` (positional `"algebraic"` / `"dynamic"`) | `GUILDA:Deprecated:CalculatePowerflowMode` | warning; becomes `Solver=mode` (`"algebraic"` → `Solver="fsolve"`) |
| `calculate_powerflow(..., "export", l, "filename", f)` | `GUILDA:Deprecated:CalculatePowerflowExport` | warning; becomes `Export=fullfile(GUILDA.pwd, f)` |
| `optimize_powerflow("methods", m)` | `GUILDA:Deprecated:OptimizePowerflowMethods` | warning; becomes `Method=m` |
| `build_opf_problem("methods", m)` | `GUILDA:Deprecated:BuildOpfProblemMethods` | warning; becomes `Method=m` |
| 6 outputs of `optimize_powerflow` | `GUILDA:Deprecated:OptimizePowerflowTuple` | warning; returns `{tab_bus, tab_cub, flag, output, lambda, OPFprob}` |
| `Continuation_Power_Flow(net, opt)` | `GUILDA:Deprecated:ContinuationPowerFlowFunction` | warning; returns a `ContinuationPowerFlowV3` (v3 properties, `solve`, `CPF_Result`) |
| `SolverCPF(net, Name, Value)` | `GUILDA:v3_cpf_constructor:ContinuationPowerFlowConstructor` | error |
| `simulate(..., "Reporter", v)` / `"RelativeTolerance", v` | `GUILDA:Deprecated:SimulateOptionName` | warning; becomes `Progress` / `Tolerance` |
| `SolverLIN(net, NonUnit, Name, Value)` | `GUILDA:v3_linearizer_constructor:OdeLinearizerConstructor` | error |
| `net.linearize` / `net.get_sys` の `Algorithm=a` | `GUILDA:Deprecated:LinearizeAlgorithm` | 警告。`Method=a` として扱う |
| `net.linearize` / `net.get_sys` の `NonUnit=n` | `GUILDA:Deprecated:LinearizeNonUnit` | 警告。状態のない母線は無視。状態のある母線は `Feedback` で `GUILDA:v3_nonunit_dynamic:NonUnitDynamicBus`、存在しない母線は `GUILDA:v3_nonunit_range:NonUnit` のエラー |
| `net.solver_LIN.NonUnit` への空でない値の代入 | `GUILDA:Deprecated:SolverLinNonUnit` | 警告(`.mat` の読み込みでも代入されるので、空の値では出さない)。値は Hidden のプロパティに残り、以後の実行で `NonUnit=n` と同じ扱い(呼び出しの指定が優先)。読み出しは保存した値を返し、警告なし |
| `initialize("methods", m)` | `GUILDA:Deprecated:InitializeMethods` | warning; becomes `Method=m` |
| `initialize` values `"powerflow calculation"` / `"optimal powerflow"` / `"calculate from Xequilibrium"` | `GUILDA:Deprecated:InitializeMethodValue` | warning; become `"powerflow"` / `"OPF"` / `"equilibrium"` |
| `CsvNetHandler.import(path, net, Initialize=tf)` | `GUILDA:Deprecated:CsvNetHandlerImport` | warning; calls `PowerNetwork.import_csv` |
| `CsvNetHandler.export(net, ModelName, savepath=d)` | `GUILDA:Deprecated:CsvNetHandlerExport` | warning; calls `net.export_csv(fullfile(d, "@"+ModelName))` |
| `ODEevent(tag, net, Name=Value)` | `GUILDA:Deprecated:ODEevent` | 警告。外乱 1 つの `Scenario` を作って `net` に追加して返す(1.18) |

Not kept: the v3 second output `lin` of `get_sys`, the v3 meaning of the
second output of `simulate`, and the v3 output order of `initialize` (see the
box at the top).

### Hooks

Core code reaches compatibility code only through single lines tagged
`% COMPAT(v3)`. `grep -rn "COMPAT(v3)" _GUILDAsystem _GUILDAobject @GUILDA`
lists all of them:

| File | Line | Hook |
|------|------|------|
| `@PowerNetwork/add_bus.m` | `opt.baseMVA` argument | accepts the old option |
| `@PowerNetwork/add_bus.m` | `v3_bus_baseMVA(obj, opt)` | warns and removes the option |
| `@PowerNetwork/calculate_powerflow.m` | `v3_powerflow_args(varargin)` | positional mode, `export` / `filename` |
| `@PowerNetwork/optimize_powerflow.m` | `v3_opf_args(varargin)` | `methods` option |
| `@PowerNetwork/optimize_powerflow.m` | `legacy_output(..., 6, @v3_optimize_powerflow, ...)` | 6-output tuple |
| `@PowerNetwork/build_opf_problem.m` | `v3_opf_args(varargin, "BuildOpfProblemMethods")` | `methods` option |
| `@PowerNetwork/initialize.m` | `v3_initialize_args(varargin)` | `methods` option and old values |
| `@PowerNetwork/simulate.m` | `v3_simulate_args(c_nv)` | option names `Reporter`, `RelativeTolerance` |
| `_auxiliary/@SolverCPF/SolverCPF.m` | `v3_cpf_constructor(varargin)` | rejects v3 constructor arguments |
| `_auxiliary/@SolverLIN/SolverLIN.m` | `v3_linearizer_constructor(varargin)` | rejects v3 constructor arguments |
| `_auxiliary/@SolverLIN/SolverLIN.m` | `NonUnit` property (Hidden) | 廃止した設定の保存先 |
| `_auxiliary/@SolverLIN/SolverLIN.m` | `set.NonUnit` | `v3_solver_nonunit`: 警告して保存 |
| `_auxiliary/@SolverLIN/get_options.m` | `v3_linearize_args(nv, obj.NonUnit)` | `NonUnit` を警告して取り除く |
| `_auxiliary/@SolverLIN/get_options.m` | `sct_options.NonUnit = rv_nonUnit` | 指定があるときだけ結果の `options` に残す |
| `_auxiliary/@SolverLIN/solve.m` | `v3_nonunit_range(sct_options, n_bus)` | 存在しない母線のエラー |
| `_auxiliary/@ResultLIN/get_ss.m` | `v3_nonunit_dynamic(obj.options, s.c_sysBus)` | 状態のある母線のエラー |

`DebugScript.test_F10_api_foundation` checks this list and that core code
does not call `Deprecated` outside a hook line. Update both when a hook is
added.

フックは `fe9aa3a` の時点で 25 行で、上の表の行数と一致します(`grep -rn "COMPAT(v3)" _GUILDAsystem _GUILDAobject @GUILDA` で数えました。ファイルごとの行数は F10 のテストが検査します)。
`Continuation_Power_Flow` and `CsvNetHandler` are old names; they live
entirely in `_VersionSupport/` and need no hook. CSV import ignores a bus
`baseMVA` column simply by not reading it (no compat code).
`@GUILDA/GUILDA.m` adds `_VersionSupport/` to the path before it reads the
settings (an untagged line, needed by the `get_config` hook).

### Contents of `_GUILDAsystem/_VersionSupport/`

| File | Purpose |
|------|---------|
| `Deprecated.m` | warning once per session, `GUILDA:Deprecated:<Key>` (convention in its header) |
| `legacy_output.m` | returns the old output tuple when `nargout` matches the old signature |
| `v3_bus_baseMVA.m` | `add_bus` `baseMVA` option |
| `Continuation_Power_Flow.m` | old CPF entry point (returns `ContinuationPowerFlowV3`) |
| `ContinuationPowerFlowV3.m` | v3 CPF object: `CPF*` properties, `solve`, `CPF_Result` |
| `@CsvNetHandler/` | old CSV import / export, wrappers of `import_csv` / `export_csv` |
| `v3_powerflow_args.m` | `calculate_powerflow` positional mode and `export` / `filename` |
| `v3_opf_args.m` | `methods` option of `optimize_powerflow` and `build_opf_problem` |
| `v3_optimize_powerflow.m` | v4 outputs → the v3 6-output tuple |
| `v3_cpf_constructor.m` | error for `SolverCPF(net, ...)` |
| `v3_simulate_args.m` | `simulate` option names `Reporter`, `RelativeTolerance` |
| `v3_linearizer_constructor.m` | error for `SolverLIN(net, ...)` |
| `v3_linearize_args.m` | `linearize` / `get_sys` の `NonUnit` |
| `v3_solver_nonunit.m` | `solver_LIN.NonUnit` の setter |
| `v3_nonunit_range.m` | `NonUnit` の存在しない母線のエラー |
| `v3_nonunit_dynamic.m` | `NonUnit` の状態のある母線のエラー |
| `v3_initialize_args.m` | `initialize` option `methods` and old method values |
| `ODEevent.m` | 旧イベント `ODEevent(tag, net, ...)`。外乱 1 つの `Scenario` を `net` に追加して返す |

### Adding a compat form (stages 2 and 3)

1. Put the logic in a file in `_VersionSupport/` (a wrapper for an old name,
   or a helper the hook calls). Name helpers `v3_<what>`.
2. In core code add **one** line that calls it, tagged `% COMPAT(v3)`.
   Deleting that line must leave working v4 code.
3. Add a `<entry key="Key">` to `SystemTools/GUILDA/en/Deprecated.xml` and
   call `Deprecated("Key", ...)` from the helper. Add a row to the table
   above and a test in `+DebugScript`.

Old output tuples: declare the method with `varargout` and end it with

```matlab
varargout = {result, flag, output};
varargout = legacy_output(varargout, nargout, 6, @v3_optimize_powerflow, "OptimizePowerflowTuple"); % COMPAT(v3)
```

`v3_optimize_powerflow(result, flag, output)` (in `_VersionSupport/`)
returns the old outputs as a cell row. Only output counts above 3 can select
the old form: with 1–3 outputs the v4 form is returned. `optimize_powerflow`
selects it only for 6 outputs, so 4 or 5 outputs are an error.

### Removing compat code in one step

1. Delete every line tagged `COMPAT(v3)`:

   ```bash
   grep -rl "COMPAT(v3)" _GUILDAsystem _GUILDAobject @GUILDA | xargs sed -i '' '/COMPAT(v3)/d'
   ```

2. Delete `_GUILDAsystem/_VersionSupport/`, `Deprecated.xml`, the
   `_VersionSupport` line of `@GUILDA/config/ListPath.txt`, and the
   `addpath(... "_VersionSupport")` line in `@GUILDA/GUILDA.m`.
3. Delete the tests of deprecated forms, then run `DebugScript.run_all`.
   By section title:
   - F1 "Add bus with deprecated baseMVA option"
   - F2 "COMPAT v3 positional mode and export options"
   - F3 "Deprecated methods option and values warn" (`test_F3_initialize`)
   - F4 "Legacy six-output form", "Deprecated methods option", and the
     `methods` part of "Build OPF problem with Method and deprecated
     methods option"
   - F5 "COMPAT v3 Continuation_Power_Flow and SolverCPF constructor"
   - F6 "Deprecated option names still work"
   - F7 "SolverLIN constructor of v3 names the remedy",
     "Deprecated NonUnit option warns and ignores buses without states",
     "Deprecated NonUnit naming a bus with states is rejected",
     "Deprecated NonUnit naming a missing bus is rejected",
     "Deprecated solver_LIN.NonUnit warns and acts as the option"
   - F8 "Deprecated CsvNetHandler wrappers"
   - F10 "Legacy output …", "COMPAT hook helper for add_bus baseMVA",
     "COMPAT hooks are single tagged lines …"
4. `SolverODE.get_options` reads the default `Progress` from the `Progress` key of
   `@GUILDA/config/DefaultTimeSimulation.json`; that is the config key,
   not compat code, and stays.

この手順を確認したのは第 1 段階の後のコピーだけです(そのときは列挙したテストだけが失敗しました)。第 2 段階以降は **再検証しておらず**、`faa2d13` の時点でも未検証です。上のテストの一覧は、手順を実行せずテストを読んで増やしたものです。

---

## 5. Notes for model and analysis authors (v4 analysis API)

### Result classes

A result of power flow, OPF, CPF, simulation or linearization is a subclass of
`ResultBase` (`_GUILDAsystem/_auxiliary/@ResultBase/`), in
`_auxiliary/@<Name>Result/`.

```matlab
classdef ResultPF < ResultBase
    properties (SetAccess=private)
        tab_bus            % computed results only
    end
    methods
        function obj = ResultPF(net, solver, options, flag, output, t0, tab_bus)
            obj@ResultBase(net, solver, options, flag, output, t0);
            obj.tab_bus = tab_bus;
        end
        function h = Plot(obj, opt)     % override only what the class supports
            ...
        end
    end
end
```

- The base keeps `flag`, `output`, `options` (effective settings),
  `s_solver`, `r_elapsed` (pass `tic` or seconds), `s_network` and a
  reference `a_PowerNetwork`. `l_success` is true for a positive numeric or a
  true logical flag; override `is_success` for another convention.
- Store only computed values and the settings used. Never copy model data
  (parameters, V/I owned by buses and components).
- `Plot` and `Export` are the result's methods. One that a class does not
  override stops with `GUILDA:ResultBase:Unsupported`.

### Name-Value options

Merge the defaults (a struct: the values of the analysis section of
GUILDA.setting, plus the conditions a solver keeps such as `LoadBus`) with the
call's overrides with `tools.resolve_options`; never write the overrides into
the solver or the settings file. The solvers do this in `get_options` with
their constant `OptionMap`.

```matlab
function varargout = calculate_continuation_powerflow(obj, opt)
    arguments
        obj
        opt.MaxIteration (1,1) double {mustBePositive, mustBeInteger}   % no default
        opt.Verbose      (1,1) logical
    end
    sct_cfg = GUILDA.config("ContinuationPowerFlow");
    sct_def = struct("MaxIteration", sct_cfg.MaxIteration.Value, "Verbose", sct_cfg.Verbose.Value);
    sct_map = struct("MaxIteration", "MaxIteration", "Verbose", "Verbose");
    options = tools.resolve_options(sct_def, sct_map, opt);
    ...
end
```

- Declare the options in the `arguments` block **without defaults**, so
  that only the given names are fields of `opt`; validate them there.
- `sct_map` maps each accepted name to a solver field: a name, a string array
  (several fields), a dotted path into a struct field, or `{field, converter}`.
- A name not in `sct_map` gives `GUILDA:resolve_options:UnknownName` with the
  list of accepted names.
