# 制御器の信号構造(母線電流の廃止、GC の観測と出力の振り分け)

機器・局所制御器(LC)・大域制御器(GC)の間の信号の流れと、時間応答シミュレーションの DAE の右辺の評価順の仕様。

- 決定: 2026-11-10、メンテナー(1〜6 節の規則)。このノートの 7 節以降は実装上の詰め(**提案**)。
- 基準コミット: `4a2f7f25`(`refactor/design-alignment`)。「現状」はこのコミットのコード。
- 状態: `refactor/controller-signal-routing` で実装(2026-11-10)。記録は末尾の「10. 実装」節。
- 区別: **決定**(メンテナーの決定)、**現状**(コードで確認済み)、**提案**(このノートの詰め。未承認)、**未決**。
- 記法: 機器の状態 x_mac、入力 u_mac、出力 y_mac、注入電流 i_mac、母線電圧 v_bus。局所制御器 LC、大域制御器 GC。

## 1. 現状と問題

**現状**(`_GUILDAsystem/_auxiliary/@SolverODE/getODEFunction.m`)

- すべてのモデル関数(`fcn_dx`、`fcn_I`、`fcn_Y`/`fcn_y`、`fcn_Mass`、`Jacobi_*`)と `f_*` ハンドル `@(t,x,V,I,u)` が母線電流 I を受け取る。
  I はその母線のすべての機器の電流の和で、1 台の機器の方程式に属する量ではない。
- 機器の出力 `fcn_Y` が u を受け取れる(直達)。
- GC は制御対象の機器の状態だけを読み、V は `[]` を受け取る。出力は機器の同名の入力に足される。
- 右辺の評価順: 全 GC → 機器ごとに(出力 → LC → 機器本体)→ KCL。
- 規模(IEEE68): 状態 144、入力 150、母線の V と I 272。

## 2. ブロック構造(決定)

```
          v_bus(全母線)                       v_bus(自母線)
              │                                   │
 ┌────────────▼─────────┐  y_gcon   ┌────────────▼───────────┐
 │ GC                    ├──────────►│ LC(入れ子を含む)       │
 │  x_gc, u_gc = 観測値  │           │  u_lc = 観測値 (+ y_gcon)│
 └────────────▲─────────┘           └───────────┬────────────┘
              │ y_mac, x_mac                     │ y_lc
              │                     ┌────────────▼────────────┐
              └─────────────────────┤ 機器                     │
                       (y_gcon ───►)│  dx = f(x, v, u)         │
                                    │  i  = g(x, v, u)         ├──► KCL
                                    │  y  = h(x, v)  ← u なし  │
                                    └─────────────────────────┘
```

1. **機器**: `dx_mac = f(x_mac, v_bus, u_mac)`、`i_mac = g(x_mac, v_bus, u_mac)`、`y_mac = h(x_mac, v_bus)`。
   出力は u に依存しない。これはシグネチャで強制する: 機器の `fcn_Y` と `Jacobi_Y` は u を受け取らない。
2. **母線電流 I はどこにもない**: 機器・LC・GC のすべてのモデルメソッドとハンドル(`fcn_dx`、`fcn_I`、`fcn_Y`/`fcn_y`、`fcn_Mass`、`Jacobi_*`、`f_*`)から引数 I を除く。
   I についての Jacobian(`Bxi`、`Dyi`、`Dii` など)もなくなる。互換層は設けない(旧シグネチャは単に動かない)。
3. **LC の観測**: 自分の機器の出力と状態を名前で観測する(現状どおり、同名なら出力が優先)。自分の機器の母線電圧を V で受け取る(現状どおり)。GC の出力を受け取ることもある(5)。
4. **GC の観測**: 各制御対象の出力 y_mac を `sv_u` の名前で観測する。状態 x_mac も可(同名なら出力が優先。LC と同じ規則)。
   さらに全母線の電圧を V で受け取る(現状は `[]`)。枝の潮流は別の観測にしない: GC が V と枝の定数から計算する。
5. **GC の出力の振り分け**(名前 `sv_y`、制御対象ごと):
   - その制御対象の LC(入れ子を含む)の 1 つ以上がその名前の入力を持つなら、出力はそれらすべてに入り、機器の入力には入らない。
   - その LC の入力が観測入力(機器の出力か状態と同名)なら、LC は和 `y_mac + y_gcon` を受け取る。
   - そうでなければ、出力は現状どおり機器の同名の入力に足される。LC と GC の両方が駆動する機器の入力は和を受け取る。
   - `add_global_controller` は GC の各出力の接続先を INFO で表示する。
     実行のために振り分けを解き直したとき(インデックスの割り当て時)に、LC の追加・削除・置き換えでその記録と変わっていれば、どのポートがどこへ行くようになったかを短く INFO で表示する(例: 「機器の入力へ直接入るようになった」)。既存の INFO の仕組みと設定(`Message.ShowInfo`)を使う。
6. **残差の評価順**(`getODEFunction`): 全機器の y_mac → 全 GC → LC(現状どおり入れ子が先)→ u_mac → dx_mac と i_mac → KCL の残差。
   `getODEJacobian` もこれに合わせる: y_mac を通る連鎖律の項と GC の項を加え、I の項を除く。
   GC の平衡点(`initialize`、`get_equilibrium`)、`get_sys`、線形化は観測した出力を一貫して使う。

## 3. 理由(決定)

- **出力に直達がない**ので、u を通る代数ループができない。機器の入力 u は DAE の代数変数のまま(残差 `u - (...)`)で、
  評価順 y_mac → GC → LC → u は u_mac を読まずに一方向に決まる。
- 古典モデルの発電機と負荷の電流は u に依存する(界磁電圧、負荷の指令値)ので、電流を出力にはできない。
  母線電圧と状態だけが観測できる量で、電流を知りたい制御器は V と状態から計算する。
- 母線電流 I は母線の全機器の和で、1 台の方程式の引数として意味を持たない。
  I を読むモデルは平衡点でしか正しくなく、線形化でも `GUILDA:Component:CurrentDependence` で止めていた。

## 4. 新しいシグネチャ(決定 2 の具体化)

| 層 | 関数 | 新しい形 |
|---|---|---|
| 機器 | `fcn_dx`、`fcn_I`、`fcn_Mass` | `(t, x, V, u, param, omega0)`(通常メソッドなら先頭に obj) |
| 機器 | `fcn_Y` | `(t, x, V, param, omega0)` |
| 機器 | `Jacobi_dx` | `[Axx, Bxv, Bxu] = (t, x, V, u, param, omega0)` |
| 機器 | `Jacobi_I` | `[Cix, Div, Diu] = (t, x, V, u, param, omega0)` |
| 機器 | `Jacobi_Y` | `[Cyx, Dyv] = (t, x, V, param, omega0)` |
| LC、GC | `fcn_dx`、`fcn_y`、`fcn_Mass` | `(t, x, V, u, param, omega0)` |
| LC、GC | `Jacobi_dx` / `Jacobi_Y` | `[Axx, Bxv, Bxu]` / `[Cyx, Dyv, Dyu] = (t, x, V, u, param, omega0)` |
| 機器 | `f_dx`、`f_I`、`f_Mass`、`f_JacobiDx`、`f_JacobiI` | `@(t, x, V, u)` |
| 機器 | `f_Y`、`f_JacobiY` | `@(t, x, V)` |
| LC、GC | `f_*` | `@(t, x, V, u)` |
| 機器 | `Hessian_dx` / `Hessian_I` / `Hessian_Y` | z = [x; V; u] / [x; V; u] / [x; V] |
| LC、GC | `Hessian_dx` / `Hessian_Y` | z = [x; V; u] |

- GC の V は全母線の電圧 `[Vre1; Vim1; Vre2; Vim2; ...]`(`a_Bus` の順、2 n_bus 行)。`Bxv`、`Dyv` は 2 n_bus 列。
- `get_sys` の位置引数からも I を除く: `Component.get_sys(x, V, u)`、`LocalController.get_sys(x, V, u)`、`GlobalController.get_sys(x, V, u)`。
- 機器の `get_equilibrium(c_V, c_I, r_P, r_Q)` の `c_I` は**その機器自身の注入電流**で、母線電流ではないので残す(**提案**)。

## 5. GC の入力の並びと観測(提案)

- 入力 u は制御対象ごとに `sv_u` の名前の順に並べる: `u = [unit1 の sv_u; unit2 の sv_u; ...]`(n_unit × n_u 行)。
  `sv_u` が 1 つの現状のクラスでは今と同じ並び。
- 新しいプロパティ `iv_obsY`、`iv_obsX`(LC と同じ名前): 各入力の、制御対象の `sv_y` / `sv_x` での位置(0 はそこから読まない)。
  制御対象はコンストラクタで固定され、ネットワーク上にある間は置き換えられないので、`add_global_controller` で一度だけ解く。
- 名前が制御対象の `sv_y` にも `sv_x` にもなければ `add_global_controller` は `GUILDA:PowerNetwork:GconPorts` で止める(現状は `sv_x` だけを見る)。
- 切り離された(trip 中の)制御対象から読む値は 0(現状の `u_connect` と同じ)。

## 6. GC の出力の振り分け(提案)

- 出力の並びは入力と同じく制御対象ごと: `y = [unit1 の sv_y; unit2 の sv_y; ...]`。
- 接続先は(制御対象、出力名)ごとに決まる:
  1. その制御対象の LC(`controllers_depth_first` の順、入れ子を含む)のうち、`sv_u` にその名前を持つものすべての、その入力。
  2. 1 が空なら、機器の同名の入力。
  3. どちらもなければ、インデックスの割り当て時に `GUILDA:PowerNetwork:GconPorts` と同じ文で止める(LC の削除で接続先が消えた場合)。
     `add_global_controller` も同じ規則で検査する(機器の入力にも LC の入力にもない名前は付けられない)。
- LC の入力が受け取る値は「GC がないときの値 + y_gcon」:
  観測入力なら `y_mac`(または `x_mac`)+ y_gcon、入れ子の LC の出力が駆動する入力なら その出力 + y_gcon、それ以外(参照値など)なら平衡値 + y_gcon。
  機器の入力も現状どおり「平衡値 + 入力イベント + LC の出力の変化 + y_gcon」。
- GC の出力は平衡点で 0 でなければならない(現状も `initialize` のモデル残差で検査している)。
- 実行ごとの振り分けのデータは SolverODE のコンテキスト(`ctx`)に持つ: GC ごとに、接続先の DAE 変数の位置 `iv_tgt` と、そこへ入る出力の行 `iv_src`。
  1 つの出力が複数の LC に入るので、GC の既存プロパティ `iv_odeY`(出力 1 つにつき位置 1 つ)では表せない。
  `iv_odeU`(観測する状態の位置)も観測が出力になると意味を失うので、GC の `iv_odeU` / `iv_odeY` は廃止する。
- 記録: GC の新しいプロパティ 1 つ(`sv_route`)に、(制御対象、出力名)ごとの接続先の文字列を持つ。
  `add_global_controller` で作って INFO に表示し、インデックスの割り当て時に作り直した文字列と比べる。
  違う行があればその行を INFO に表示し、記録を新しい文字列で置き換える(同じ変化を実行のたびに表示しない)。

## 7. 右辺と Jacobian(提案)

右辺(`getODEFunction`):

1. 出力を読まれる機器(LC がある、または GC が観測する)の y_mac = `f_Y(t, x_mac, v_bus)`。出力のない機器は計算しない。
2. 各 GC: u_gc を y_mac と x_mac から集め、`f_dx(t, x_gc, V_all, u_gc)` と `f_Y(...)`。出力を `y_GC`(DAE 変数と同じ長さ)の接続先の位置に足す。
3. 機器ごとに、LC(入れ子が先)の残差 `u_lc - (元の値 + y_GC(u_lc の位置))`、機器の入力の残差 `u_mac - (平衡値 + イベント + LC の出力の変化 + y_GC)`、dx_mac、i_mac。
4. KCL の残差。

Jacobian(`getODEJacobian`): 上の順に、

- 機器の y_mac の Jacobian `[Cyx, Dyv]` を、LC の観測入力の行と GC の行で共用する。
- GC の行: `dx_gc` に `Axx`(x_gc)、`Bxv`(全母線の V)、`Bxu · ∂u_gc/∂z`(観測した機器の x と自母線の V)。
  接続先の入力の行に `-(Cyx, Dyv, Dyu · ∂u_gc/∂z)`。
- I の列はなくなる。

`Component.get_dx_algebraic(obj, t, x, Vi, u, y, y_GC, DAEvec)`、`LocalController.get_dx_algebraic(obj, t, x, Vi, obs, y_GC, DAEvec)`: y は解法が計算した機器の出力、y_GC は GC の出力の和(DAE 変数と同じ長さ、GC がなければ空)。

## 8. 線形化(提案)

- `GlobalController.get_sys`: 入力は全母線の電圧(`net.get_variable_map()` の Vre / Vim のラベル)と u(観測する機器の出力または状態のラベル)、出力は y。
- `SolverLIN`(`net.linearize`): GC の入力 w = Wx x + Wv v(機器の出力は母線モデルの出力行、状態は単位行)、
  出力は機器の入力の列(`Bx`、`Bv`)または LC の入力の列(母線モデルの入力のうちその LC の入力)に入る。
  GC が V に依存するので `Axv` と `Avv` も変わる。
- `ResultLIN.get_ss` の `"Feedback"`: GC の入力を母線モデル(I→V)の出力から取る。非単位母線の電圧に依存する GC は対応しない(エラー)。

## 9. 未決

- 10 節の「確認してほしい点」。

## 10. 実装

ブランチ `refactor/controller-signal-routing`(基準 `4a2f7f25`)。

| 段階 | コミット | 内容 |
|---|---|---|
| 0 | `5dd94011` | このノート |
| 1 | `84420b17` | 全モデル関数・ハンドル・`get_sys`・`get_hessian` から I を削除。機器の `fcn_Y` / `Jacobi_Y` から u を削除 |
| 2 | `af2e642a` | GC の観測(出力 → 状態、全母線の V)、出力の振り分け、INFO、評価順、Jacobian、平衡点の検査、`get_sys`、線形化。テスト `test_F35_controller_signal_routing` |
| 3 | `6bb9c7d0` | `notes/v4-migration.md`、For Developer のページ |
| 修正 | `5e4c3f4b` | `get_ss("Feedback")` で使わない GC 入力(全母線の V)を落とす(medium の F7 で発見) |
| 修正 | `f0f0f02b` | `get_ss("Feedback")` で GC が消去した母線の電圧と機器の出力を読めるようにした(ブランチ `fix/feedback-eliminated-bus-observation`)。テストは F35 に追加 |

**現状**(実装後のコード)

- 新しいメンバー: `GlobalController.iv_obsY`、`iv_obsX`(コンストラクタで解く)、`sv_route`(`add_global_controller` が作り、`SolverODE.get_units` が変化を INFO で表示して更新)。
- 削除したメンバー: `GlobalController.iv_odeU`、`iv_odeY`(1 つの出力が複数の入力に入るため。実行ごとの接続は `ctx.c_gc`)。`SolverODE/private/getSubJacobian.m`(未使用)。メッセージ `GUILDA:Component:CurrentDependence`。
- 変えたシグネチャ: `SolverODE.get_units` は `[c_unit, c_gc]` を返す。`Component.get_dx_algebraic(t, x, Vi, u, y, y_GC, DAEvec)`、`LocalController.get_dx_algebraic(t, x, Vi, obs, y_GC, DAEvec)`。
- 新しいメッセージ: `GUILDA:PowerNetwork:GconRoute`(INFO)、`GUILDA:SolverODE:GconRouteChanged`(INFO)、`GUILDA:SolverODE:GconNoTarget`(エラー)。`GconPorts` と `GlobalController:GlobalControllerPort` の文を新しい規則に合わせた。
- `GlobalController.get_sys` の出力は、駆動する入力ごとに 1 行(その入力の名前)。`SolverLIN` はこの名前で機器の入力か LC の入力(母線モデルの列 `c_sysL`)に接続する。
- `ResultLIN.get_ss("Feedback")`: GC は非単位母線(機器のない母線と、状態がなく I→V の形がない母線)の電圧と、その母線の機器の出力も読める。ネットワークのブロックが、消去した母線の KCL から V_n = Ybar_nn^-1 (Diu_n u_n - Y_nu V_u)(Ybar_nn = Y_nn - Div_n)と y_n = Dyv_n V_n + Dyu_n u_n を出力に加える(GC が使うものだけ。既定の出力は変わらない)。非単位母線の LC の入力を GC が駆動するときは、従来どおり `GUILDA:ResultLIN:GlobalControllerPort` で止まる。使わない入力(B と D の列が 0)は照合の前に落とす。
- 機器の `get_equilibrium(c_V, c_I, r_P, r_Q)` の `c_I` は機器自身の注入電流なので残した(4 節)。`FixedInput`(`solve_fixed_input`)の未知数 I も機器ごとの電流で、母線電流ではない。
- `component.ConstSource.power`(v1 の `get_dx_constraint`)は作成も追加もできない死んだコード(クラスの help にも記載)なので変更していない。`component.load.history`、`_GUILDAobject/+component/未+GFM`、`未+farm` も旧インターフェースの保管で、パス上の `+` パッケージではないか登録されないため変更していない。
- 測定(MATLAB R2026a、IEEE68bus 既定(AVR+PSS)、先頭母線の地絡 [1, 1.05] s、`simulate([0,10])`、1 スレッド、5 回の中央値): 変更前 0.832 s、段階 1 の後 0.914 s、段階 2 の後 0.870 s。軌道の最終値のノルムは 3 回とも 60.7713729221(同一)。差は測定のばらつきと、出力の先行計算・引数の追加の範囲。

**確認してほしい点**(提案、未承認)

- 振り分けの規則(LC の木をたどる)は `add_global_controller`、`SolverODE.get_units`、`GlobalController.get_sys`、`Component.validate` の 4 か所に数行ずつ同じ形で書いた(新しい補助関数を足さないため)。共通の関数にまとめるかは判断待ち。
- `sv_route` は「`add_global_controller` で表示した記録」に加え、実行時に変化を表示した後は新しい接続で上書きする(同じ変化を毎回表示しないため)。
- GC の出力が LC の入力に入るときの値は「GC がないときの値 + 出力」(観測入力なら y_mac + y_gcon、入れ子の LC の出力が駆動する入力ならその出力 + y_gcon、それ以外は平衡値 + y_gcon)。
- `GlobalController.get_sys` と `get_hessian` の既定の V は全母線の平衡点の電圧。GC の `get_equilibrium(obj)` は引数なしのまま(観測した出力の平衡値は `PowerNetwork.initialize` のモデル残差の検査で使う)。
