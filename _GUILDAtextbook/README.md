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
  | 0 | 表 2.2 の入力定常値に対応する潮流設定 |
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

GUILDA v4 の潮流計算には slack 母線が 1 つ必要です。`flow=0` の旧版の設定は 3 母線とも PV 母線なので、
v4 版では母線 1 を slack 母線（|V| = 1.372、偏角 0）にしています。そのため例 2.3 の数値は旧版と少し違います
（`_GUILDAverification/Textbook/README.md`）。

### グラフ作成ファイル

| ファイル名 | 対応箇所 | 図番号 | `flow` | `comp2` | `lossless` | 制御器 |
|:---|:---:|:---|:---:|:---|:---|:---|
| `example_2_3.m` | 例 2.3 | 図 2.10〜2.12 | 0 | `Gen_1axis` | `{}` | なし |
| `example_3_3.m` | 例 3.3 | 図 3.2 | 1, 2 | `L_impedance` | `"br23"` | なし |
| `example_3_4.m` | 例 3.4 | 図 3.3、図 3.4 | 1, 2 | `L_impedance` | `"br23"` | なし |
| `example_3_5.m` | 例 3.5 | 図 3.5、図 3.6 | 1, 2 | `L_impedance` | `"br23"` | なし |
| `example_5_1.m` | 例 5.1 | 図 5.2 | 2 | `L_power` | `"br23"` | なし、AGC（`agc-PI`） |
| `example_5_2.m` | 例 5.2 | 図 5.3 | 2 | `L_power` | `"br23"` | AGC（`agc-PI`） |
| `example_5_3.m` | 例 5.3 | 図 5.5 | 2（表 5.2 の 2 つの設定） | `L_power` | `["br12", "br23"]` | AGC（`agc-PI`） |

旧版の対応表にある例 4.5、5.4、5.6 と 6.2 節、6.3 節のファイルは、旧版のリポジトリにもありません。

例 5.5（図 5.12）の v4 版はありません。旧版は AVR の電圧の目標値 Vref を平衡点と違う値にし（`avr.initialize`）、
AVR の状態の初期値も平衡点と違う値にして計算しますが、v4 のシナリオで与えられるのは機器の入力と機器の状態のずれだけで、
制御器の入力（Vref）と状態は与えられないためです（`_GUILDAverification/Textbook/README.md`）。

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
