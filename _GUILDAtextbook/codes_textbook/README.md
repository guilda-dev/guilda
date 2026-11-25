# 教科書のプログラム（codes_textbook）の GUILDA v4 版

石崎孝幸 編著『電力系統のシステム制御工学 ―システム数理とMATLABシミュレーション―』（コロナ社, 2022）の
プログラム3-1〜3-38（例3.8〜3.19）を GUILDA v4 で書き直したものです。
旧版は [guilda-dev/textbook](https://github.com/guilda-dev/textbook) の `codes_textbook` です。

## 実行方法

GUILDA を起動すると、`GUILDA.addpath` が `_GUILDAtextbook` をパスに加えます。
コマンド ウィンドウで `exe_codes_textbook` を実行し、例の番号を入力します（例: `3.18`）。
番号を引数で与えることもできます。

```matlab
exe_codes_textbook("3.18")
```

v4 版スクリプトはベースワークスペースで実行されるので、実行後に変数（`net`, `res`, `t`, `x`, `V`, `I` など）を確かめられます。

## v4 版を作らなかった例

例3.8〜3.10 と例3.14 には v4 版がありません。

- 例3.8（fsolve の使い方）と例3.14（RLC 回路の ODE と DAE）は電力系統の解析ではなく、MATLAB の `fsolve` と `ode45`・`ode15s` の使い方を示す例です。
  GUILDA で置き換える処理がありません。
- 例3.9・3.10 は潮流方程式を `fsolve` で解く手順を、関数を手で書いて示す例です。
  GUILDA で書き直すと例3.13 の v4 版と同じ `calculate_powerflow` の呼び出しになり、手順を示すという例の目的がなくなります。
  計算する潮流は例3.11・3.13 と同じなので、検証では例3.13 の v4 版の結果と比べています。

これらは旧版をそのまま実行してください（`exe_codes_textbook` は旧版の場所を表示します）。

## ファイル対応表

旧版の対応表に v4 版ファイルの列を加えたものです。
旧版の補助ファイル（`branch.m`, `bus_*.m`, `generator.m`, `load_impedance.m`, `func_*.m`, `calculate_power_flow.m`,
`get_admittance_matrix.m`, `simulate_power_system.m`）は GUILDA の機能に置き換わるため、v4 版にはありません。
置き換え先は [旧版の処理と v4 の機能](#旧版の処理と-v4-の機能) にまとめています。

|フォルダ名|ファイル名|電力テキスト内のプログラム番号|v4 版ファイル|
|:----|:----|:----|:----|
|example3.8|func_ex1.m|プログラム3-1|（なし: GUILDA を使わない例）|
| |main_ex1.m|プログラム3-2|（なし）|
|example3.9|func_ex2.m|プログラム3-3|（なし: 潮流方程式を手で書く例）|
| |main_ex2.m|プログラム3-4|（なし）|
|example3.10|func_ex3.m|プログラム3-5|（なし: 潮流方程式を手で書く例）|
| |main_ex3.m|プログラム3-6|（なし）|
|example3.11|bus_slack.m|プログラム3-7|`add_bus(V=2, Varg=0)` と `l_isSlack`|
| |bus_generator.m|プログラム3-8|`add_bus(V=2)` と `add_component(..., "P", 0.5)`|
| |bus_load.m|プログラム3-9|`add_component(..., "P", -3, "Q", 0)`|
| |func_power_flow.m|プログラム3-10|`calculate_powerflow`|
| |main_ex4.m|プログラム3-11|example3.11/main_ex4.m|
|example3.12|branch.m|プログラム3-12|`add_branch("pi", ...)`|
| |get_admittance_matrix.m|プログラム3-13|`get_admittance_matrix`|
| |main_admittance.m|プログラム3-14|example3.12/main_admittance.m|
|example3.13|calculate_power_flow.m|プログラム3-15|`calculate_powerflow`|
| |main_power_flow.m|プログラム3-16|example3.13/main_power_flow.m|
| |branch.m| | |
| |bus_generator.m| | |
| |bus_load.m| | |
| |bus_slack.m| | |
| |func_power_flow.m| | |
| |get_admittance_matrix.m| | |
|example3.14|func_RLC_ode.m|プログラム3-17|（なし: GUILDA を使わない例）|
| |main_RLC_ode.m|プログラム3-18|（なし）|
| |func_RLC_dae.m|プログラム3-19|（なし）|
| |main_RLC_dae.m|プログラム3-20|（なし）|
|example3.15|func_simulation_3bus.m|プログラム3-21|`simulate`（gen-1axis, load-impedance の式）|
| |main_simulation_3bus_simple.m|プログラム3-22|example3.15/main_simulation_3bus_simple.m|
| |branch.m| | |
| |get_admittance_matrix.m| | |
|example3.16|generator.m|プログラム3-23|`gen-1axis`（`component.generator.one_axis`）|
| |load_impedance.m|プログラム3-24|`load-impedance`（`component.load.impedance`）|
| |func_simulation.m|プログラム3-25|`simulate`|
| |simulate_power_system.m|プログラム3-26|`simulate`|
| |main_simulation_3bus.m|プログラム3-27|example3.16/main_simulation_3bus.m|
| |branch.m| | |
| |get_admittance_matrix.m| | |
|example3.17|generator.m|プログラム3-28|`initialize`（平衡点の計算）|
| |load_impedance.m|プログラム3-29|`initialize`（平衡点の計算）|
| |main_simulation_3bus_equilibrium.m|プログラム3-30|example3.17/main_simulation_3bus_equilibrium.m|
| |branch.m| | |
| |bus_generator.m| | |
| |bus_load.m| | |
| |bus_slack.m| | |
| |calculate_power_flow.m| | |
| |func_power_flow.m| | |
| |func_simulation.m| | |
| |get_admittance_matrix.m| | |
| |simulate_power_system.m| | |
|example3.18|func_simulation.m|プログラム3-31|`add_fault`（母線の地絡）|
| |simulate_power_system.m|プログラム3-32|`simulate`|
| |main_simulation_3bus_fault.m|プログラム3-33|example3.18/main_simulation_3bus_fault.m|
| |branch.m| | |
| |bus_generator.m| | |
| |bus_load.m| | |
| |bus_slack.m| | |
| |calculate_power_flow.m| | |
| |func_power_flow.m| | |
| |generator.m| | |
| |get_admittance_matrix.m| | |
| |load_impedance.m| | |
|example3.19|generator.m|プログラム3-34|`add_input`（Pmech）|
| |load_impedance.m|プログラム3-35|`add_input`（R, X）|
| |func_simulation.m|プログラム3-36|`simulate`|
| |simulate_power_system.m|プログラム3-37|`simulate`|
| |main_simulation_3bus_input.m|プログラム3-38|example3.19/main_simulation_3bus_input.m|
| |branch.m| | |
| |bus_generator.m| | |
| |bus_load.m| | |
| |bus_slack.m| | |
| |calculate_power_flow.m| | |
| |func_power_flow.m| | |
| |get_admittance_matrix.m| | |

## 旧版の処理と v4 の機能

v4 版は旧版と同じ系統・同じ条件を、GUILDA の公開されている機能で組みます。

| 旧版 | v4 版 |
|:---|:---|
| `branch(from, to, y)`（送電線のアドミタンス `y`） | `net.add_branch("pi", [from,to], R=real(1/y), X=imag(1/y))`（インピーダンスで与えます） |
| `get_admittance_matrix(n_bus, a_branch)` | `net.get_admittance_matrix()`（母線のタグを行と列の名前にもつ table） |
| `bus_slack(2, 0)` | `net.add_bus(V=2, Varg=0)` と `bus.l_isSlack = true` |
| `bus_load(-3, 0)` | `bus.add_component("load-impedance", "P", -3, "Q", 0)` |
| `bus_generator(0.5, 2)` | `net.add_bus(V=2)` と `bus.add_component("gen-1axis", "P", 0.5)` |
| `calculate_power_flow` / `fsolve` | `net.calculate_powerflow(Format="powerflow(tab)")`（V, I, P, Q） |
| `generator(omega0, M, D, tau, X, X_prime, Pmech, Vfield)` | `gen-1axis`。パラメータ `M`, `D`, `Xd = X`, `Xq = Xd_p = X_prime`, `Td_p = tau`。`omega0 = 2*pi*Hz`（`Hz = 60`） |
| `load_impedance(z)` | `load-impedance`。入力 `[R; X]` が `z = R + jX` です |
| `set_equilibrium` | `net.initialize()`（`rv_Xequilibrium`, `rv_Uequilibrium`） |
| `simulate_power_system`（ode15s, `RelTol = 1e-6`） | `net.simulate(..., Solver="ode15s", Tolerance=1e-6, AbsoluteTolerance=1e-6)` |
| 初期値 `x0` を平衡点からずらす | `sc.add_offset(tag, state, 値, 0)` |
| `Pmech`, `Vfield`, `z` を数値で与える（例3.15・3.16） | 平衡点の入力との差を `sc.add_input(tag, name, 差, [0, 50])` で全区間に加えます |
| 地絡 `fault_bus = 1`, `fault_tspan = [0, 50e-3]` | `sc.add_fault("B001", [0, 50e-3])` |
| 入力 `U`, `bus_U`（負荷 `z` を `0.05*t/50` の割合で増やす） | `sc.add_input(load2.s_tag, ["R";"X"], [0, 0, 0; 50, 0.05*R0, 0.05*X0], [0, 50])`（直線補間） |

### モデルの対応

旧版の `generator` は非突極の 1 軸モデルで、内部電圧 `E∠δ` が過渡リアクタンス `X'` の背後にあります。

```
dδ/dt = ω0 ω
M dω/dt = -D ω - P + Pmech,        P = Re(V conj(I))
τ dE/dt = -(X/X') E + (X/X' - 1) |V| cos(δ - ∠V) + Vfield
I = (E e^{jδ} - V) / (j X')
```

v4 の `gen-1axis` は dq 座標で書いた 1 軸モデルです（`Vq = |V| cos(δ - ∠V)`, `Vd = |V| sin(δ - ∠V)`）。

```
dδ/dt = 2π Hz ω
M dω/dt = -D ω - P + Pmech,        P = Vd Id + Vq Iq
Td' dEq/dt = -Eq - (Xd - Xd') Id + Vfield,   Id = (Eq - Vq)/Xd',  Iq = Vd/Xq
```

`Xq = Xd'` とすると、`Id`, `Iq` は旧版の `I = (E e^{jδ} - V)/(jX')` の dq 成分に、
`Td' dEq/dt` の右辺は `-(Xd/Xd') Eq + (Xd/Xd' - 1) Vq + Vfield` になり、旧版と同じ式です。
状態の並び `[δ; ω; E]` と `[delta; omega; Eq]`、電流の向き（機器から母線へ流れ込む向きが正）も同じです。

旧版の `load_impedance` は `V + z I = 0`、v4 の `load-impedance` は `I = -V/(R + jX)` で、同じ式です。
旧版の例3.19 の入力 `u` は `z = real(z)(1 + u1) + j imag(z)(1 + u2)` と働きますが、
v4 の入力は `R`, `X` そのもの（平衡点の値に加える値）なので、v4 版では `R0 u1`, `X0 u2` を加えます。

旧版の地絡は、地絡中の母線1の電流の式 `I1 = (Y V)_1` を `V1 = 0` に置き換えます。
v4 の母線の地絡（`add_fault`, 状態 `"BG"`）も地絡中の母線の電圧を 0 に保ちます。

## 検証

旧版と v4 版の数値の比較は `_GUILDAverification/Textbook/codes/README.md` にあります。
