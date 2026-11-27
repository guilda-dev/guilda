# 教科書のプログラム（GUILDA v4 版）

石崎孝幸 編著『電力系統のシステム制御工学 ―システム数理とMATLABシミュレーション―』（コロナ社, 2022）
の[サンプルコードとグラフ作成用コード](https://github.com/guilda-dev/textbook)を、GUILDA v4 で動くように書き直したものです。
旧版（GUILDA v1.1 用）と同じ条件で計算し、同じ図を描きます。
旧版との数値の比較は `_GUILDAverification/Textbook/`（検証用のサブモジュール）にあります。

## フォルダの内容

- `figures_textbook/`: 教科書のグラフを描くプログラムと、3 母線系統を作る `network_example3bus.m`
- `exe_figures_textbook.m`: 例の番号を入力して、グラフを描くプログラムを実行します
- `codes_textbook/`: 教科書のサンプルコード（対応表は [`codes_textbook/README.md`](codes_textbook/README.md)）

## 実行方法

GUILDA のフォルダで GUILDA を起動してから（`GUILDA.addpath`。このフォルダもパスに加わります）、

```matlab
exe_figures_textbook
```

を実行し、描きたいグラフに対応する例の番号（例 2.3 なら `2.3` または `2_3`）を入力します。
グラフが描かれ、エディターに対応するプログラムが開きます。

## `figures_textbook` フォルダ内のファイル対応表

### ネットワーク定義用ファイル `network_example3bus.m`

```matlab
net = network_example3bus(flow=Value, comp2=Value, lossless=Value)
```

潮流計算と平衡点の計算まで済ませた `PowerNetwork` を返します。

- `flow`: 潮流設定（既定 1）

  | Value | 指定内容 |
  |:---|:---|
  | 0 | 表 2.2 の定常値（δ\*、E\*）に対応する潮流設定 |
  | 1 | 表 3.1 の潮流設定 |
  | 2 | 表 3.2 の潮流設定 |

- `comp2`: 母線 2 に付加する機器（既定 `"L_impedance"`）

  | Value | 指定内容 |
  |:---|:---|
  | `"L_impedance"` | 定インピーダンス負荷（`load-impedance`） |
  | `"L_power"` | 定電力負荷（`load-power`） |
  | `"Gen_1axis"` | 同期発電機の一軸モデル（`gen-1axis`） |

- `lossless`: 損失をなくす送電線（既定 なし）

  | Value | 母線 1-2 間 | 母線 2-3 間 |
  |:---|:---|:---|
  | `{}` | 損失あり | 損失あり |
  | `"br12"` | 損失なし | 損失あり |
  | `"br23"` | 損失あり | 損失なし |
  | `["br12", "br23"]` | 損失なし | 損失なし |

`flow=0` は、表 2.2 の発電機の定常値 δ\*、E\* から母線電圧を計算し、母線 1 を slack 母線（その |V|・偏角）、
母線 2・3 を PV 母線（その P・|V|）にした潮流設定です。平衡点は表 2.2 の δ\*、E\* に一致します
（表 2.2 は母線 2 が発電機の場合の値です）。旧版は 3 母線とも PV 母線（|V|・P は表の丸め値）で slack 母線がなく、
fsolve の解は表 2.2 から偏角が約 0.25 rad 回転し、丸めた |V| のため E が最大 6e-3 ずれています。そのため例 2.3 の数値は
旧版と違います（`_GUILDAverification/Textbook/README.md`）。

### グラフ作成ファイル

| ファイル名 | 対応箇所 | 図番号 | `flow` | `comp2` | `lossless` | 制御器 |
|:---|:---:|:---|:---:|:---|:---|:---|
| `example_2_3.m` | 例 2.3 | 図 2.10〜2.12 | 0 | `Gen_1axis` | `{}` | なし |
| `example_3_3.m` | 例 3.3 | 図 3.2 | 1, 2 | `L_impedance` | `"br23"` | なし |
| `example_3_4.m` | 例 3.4 | 図 3.3、図 3.4 | 1, 2 | `L_impedance` | `"br23"` | なし |
| `example_3_5.m` | 例 3.5 | 図 3.5、図 3.6 | 1, 2 | `L_impedance` | `"br23"` | なし |
| `example_4_2.m` | 例 4.2 | 図 4.2 | 0 | `Gen_1axis` | `{}` | なし |
| `example_4_3.m` | 例 4.3 | （蓄積関数） | 0 | `Gen_1axis` | `["br12", "br23"]`、`{}` | なし |
| `example_4_4.m` | 例 4.4 | （固有値の軌跡） | 0 | `Gen_1axis` | `["br12", "br23"]`、`{}` | なし |
| `example_4_6.m` | 例 4.6 | （安定性の分類） | 0 | `Gen_1axis` | `{}`（R、X を書き換え） | なし |
| `example_5_1.m` | 例 5.1 | 図 5.2 | 2 | `L_power` | `"br23"` | なし、AGC（`agc-PI`） |
| `example_5_2.m` | 例 5.2 | 図 5.3 | 2 | `L_power` | `"br23"` | AGC（`agc-PI`） |
| `example_5_3.m` | 例 5.3 | 図 5.5 | 2（表 5.2 の 2 つの設定） | `L_power` | `["br12", "br23"]` | AGC（`agc-PI`） |
| `example_5_5.m` | 例 5.5 | 図 5.12 | 1（例 5.4 の運転点に設定し直します） | `L_impedance` | `"br23"` | AVR（`avr-ST1`）、PSS（`pss-PSS1`） |

旧版の対応表にある例 4.5、5.4、5.6 と 6.2 節、6.3 節のファイルは、旧版のリポジトリにもありません。

例 4.2 は旧版と同じく非線形モデルの初期値応答です（旧版の `'linear', false`）。平衡点からの偏差を描きます。

例 4.3、4.4、4.6 は、旧版では GUILDA を使わず、近似線形化モデルの行列を式で組み立てていました。
v4 版は `linear_model_example3bus.m` で、同じ系統を教科書の点（δ、E を数値で与えます。損失ありでは flow=0 の平衡点と同じ点、
損失なしと例 4.6 では平衡点ではありません）で
`net.get_sys(点, Type="ODE", Form="absorbed")` にかけ、その状態行列から教科書の行列を取り出します。

| 教科書の行列 | v4 の線形化（状態を [δ; Δω; E] の順に並べた `res.A` = Ψ） |
|:---|:---|
| Ψ | `res.A`（母線電圧を消去した ODE、時定数を掛けた形） |
| L | `-M * Ψ(Δω, δ)` |
| C_E | `-M * Ψ(Δω, E)` |
| B_E | `T * Ψ(E, δ)` |
| A_E | `T * Ψ(E, E)` |

母線電圧 V は、与えた δ、E で代数方程式（送電網と発電機の `I = (E e^{jδ} - V)/(j Xd')`）を満たす値にします。
教科書の式は Xq = Xd' の一軸モデルの場合で、`network_example3bus` の発電機もそうなっています。
例 4.6 は送電線の R、X と（(b)、(d) では）制動係数 D を書き換え、θ2 ごとに θ1 の 101 点をまとめて線形化します
（全体で数分かかります）。

例 5.5 は教科書の設定で計算します。平衡点は例 5.4 で選ばれた点（内部電圧 E* は表 3.3、回転子偏角の差 δ3* − δ1* = −π/6）で、
表 3.1 の潮流（flow=1、δ3* − δ1* = 0.32）の平衡点とは違います。`example_5_5.m` は flow=1 の系統から E* と負荷のインピーダンスを取り、
δ* = [π/6, 0] での母線電圧を求めて、母線 1・3 の P と |V|（母線 3 は偏角も）、母線 2 の P と Q を潮流設定にし直して `net.initialize` します。
AVR は表 5.5 の例 1、PSS は表 5.7 の例 2（`kpss=20`）、初期値は δ1(0) = 0、δ3(0) = −1 と −π/2 で、ほかの状態（AVR・PSS を含む）は平衡点の値です。
旧版の `example_5_5` は E3* の取り出しと PSS の符号が教科書と違い、図 5.12 と違う結果になります（`_GUILDAverification/Textbook/README.md`）。
図の横軸の題は、計算の設定どおり δ3(0) − δ1(0) にしています（教科書の図 5.12 の題は δ1(0) − δ3(0)）。

## 旧版（GUILDA v1.1）との書き方の違い

| 旧版 | v4 版 |
|:---|:---|
| `out = net.simulate([0, 30], 'x0_sys', x_init)`（平衡点 + 摂動の初期値） | シナリオに状態のずれを加えます: `sc = net.add_scenario("tag", Time=[0, 30]); sc.add_offset("B001SG1", ["delta"; "Eq"], [pi/6; 0.1], 0)` |
| `net.simulate(t, u, idx_u, ...)`（入力） | `sc.add_input(<機器のタグ>, <入力名>, <値>, [t_start, t_end])`。値は平衡点の入力に加わります |
| `'fault', {{[0, 0.05], 1}}` | `sc.add_fault("B001", [0, 0.05])` |
| `out.X{1}(:, 2)`（母線 1 の機器の Δω） | `res.odeResults.Bus(1).Component(1).X.omega` |
| `out.V{1}`、`out.I{1}`（[実部, 虚部]） | `res.odeResults.Bus(1).V`、`.I`（表: 実部, 虚部の列） |
| 発電機の入力の順序 `[Vfd; Pm]` | `gen-1axis` の入力は `Pmech`、`Vfield`（名前で指定） |
| 定インピーダンス負荷の入力 = アドミタンスの倍率 `Y0*(1+u)` | `load-impedance` の入力はインピーダンス `R`、`X` そのもの（例 3.4 で換算しています） |
| 数値解法 ode15s、許容誤差 1e-8（既定） | `net.simulate(..., Solver="ode15s", Tolerance=1e-8, AbsoluteTolerance=1e-8)` を指定しています（v4 の既定は 1e-6） |
| 定電力負荷の入力 = 電力の倍率 `P0*(1+u)` | `load-power` の入力は電力 `Pload`、`Qload` そのもの。`P0*u` を加えます（例 5.1） |
| `controller_broadcast_PI_AGC(net, [1,3], [1,3], -100, -500)`、`set_K_input`、`set_K_observe` | `net.add_global_controller("agc-PI", {g1, g3}, parameter=struct(alpha=..., beta=..., kP=100, kI=500))`。出力は `-alpha*(kP*w + kI*xi)` で、旧版の `Kp = -100`、`Ki = -500` と同じです |
| `net.a_bus{i}.component.governor.P = 0`（機械入力の定常値） | `sc.add_input(<発電機>, "Pmech", -<平衡点の Pmech>, [t0, t1])`（既定の `gov-static` は定常値をそのまま出すので同じです） |
| `net.simulate(..., 'x0_con_global', x0)`（AGC の状態の初期値） | `sc.add_offset(agc.s_tag, "xi", x0 - agc.rv_Xequilibrium, t0)`（平衡点からのずれとして与えます。例 5.2、5.3） |
| 区間ごとにパラメータを変えて `simulate` を繰り返す（例 5.2） | `agc.tab_parameter.dynamics.alpha = ...` と `net.initialize` の後、前の区間の最後の状態との差を `sc.add_offset` で与えて区間ごとに `simulate` します |
