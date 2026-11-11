# 変数表と接続表(信号の振り分けの一元化と DAE の変数の並び)

`PowerNetwork.get_variable_map` を、DAE の変数だけでなく系のすべての信号の表に広げ、信号の接続を表す接続表を加える。
振り分け(どの信号がどの入力に入るか)はこの接続表だけで決め、`add_global_controller`、`GlobalController.get_sys`、`Component.validate`、`SolverODE` はこれを読む。
時間応答シミュレーションの変数の並びは変数表の並びに揃え、実行ごとの位置は `SolverODE` の実行コンテキスト `ctx` だけに持つ。

- 決定: 2026-11-11、メンテナー(A〜D)。このノートの「提案」はその具体化。
- 基準コミット: `2e2004e4`(`refactor/design-alignment`)。「現状」はこのコミットのコード。
- ブランチ: `refactor/variable-connection-map`。
- 前提: `notes/controller-signal-routing.md`(信号の構造と振り分けの規則。規則そのものは変えない)。
- 区別: **決定**、**現状**(コードで確認済み)、**提案**(このノートの具体化)、**未決**。

## 1. 現状と問題(現状)

- 振り分けの規則(GC の出力は制御対象の LC(入れ子を含む、深さ優先)のうち同名の入力を持つものすべてへ、なければ機器の同名の入力へ)が
  `add_global_controller`、`SolverODE.get_units`、`GlobalController.get_sys`、`Component.validate` の 4 か所に同じ形で書かれている。
- シミュレーションの位置(`iv_odeX`、`iv_odeU`、`iv_odeY`、`iv_odeI`、`lv_odeUfromLC`、`iv_odeYtoU`、GC の `iv_odeX`)とシナリオの状態(`l_isConnect`、`l_isFault`、`rv_Xoffset`、`rv_Uoffset`)をモデルのオブジェクトに書き、`restore_working_data` で戻している。
- `simulate` が `GlobalController.sv_route` を書き換える。
- シミュレーションの変数の並び(機器ごとに [x; u]、LC ごとに [x; u]、GC の x、母線ごとに [V; I])と線形化の並び(変数表: x、V、u)が違う。
- LC の右辺は入れ子の LC を先に評価して出力を親に渡す合成で、GC は全機器より先に評価する。

## 2. 変数表(決定 A、提案)

`[tab, c_idxBus, c_idxGC, tab_connection] = net.get_variable_map()`。

### 2.1 行の並び

| 順 | Kind | Role | 内容 | 並び |
|---|---|---|---|---|
| 1 | `x` | variable | 状態 | 母線ごと、機器ごとに 機器 → その LC(深さ優先)。その後 GC(`a_GlobalController` の順) |
| 2 | `Vre`、`Vim` | variable | 母線電圧 | 母線ごとに Vre、Vim |
| 3 | `u` | variable | 機器の入力 | 母線ごと、機器ごと |
| 4 | `uc` | variable | 制御器の入力 | 母線ごと、機器ごとに LC(深さ優先)。その後 GC ごとに 制御対象ごとの `sv_u` |
| 5 | `y` | signal | 機器の出力 | 母線ごと、機器ごと |
| 6 | `yc` | signal | 制御器の出力 | 母線ごと、機器ごとに LC(深さ優先)。その後 GC ごとに 制御対象ごとの `sv_y` |

- 列: `Index`、`Kind`、`Role`(新規)、`Owner`、`Name`、`Label`、`Bus`。`Role` は `"variable"`(DAE の変数)か `"signal"`(変数から毎回計算する値)。
- 1〜3 は今の変数表と同じ行・同じ `Index`。線形化の変数(Kind が x、Vre、Vim、u)は**表の先頭の行**で、`net.linearize` とその結果はこの部分だけを使う(4 節)。
- `Label`: x、u、V は今と同じ。`uc` は LC の `attach_tag(名前)`。`y`、`yc`(LC)は `get_sys` の出力名と同じ(所有者の状態と同名なら `"Y_" + 名前`)。
  GC の `uc` と `yc` は制御対象ごとにあるので `gc.attach_tag(名前 + "_" + 制御対象のタグ)`(例 `omega_SG1B001_AGC1IEEE68bus`)。
  `Label` は Kind の中で一意。接続表は `Index` で行を指す。
- GC の行の `Owner` は GC のタグ、`Bus` は `""`(今の x の行と同じ)。
- `c_idxBus{i}`: 母線 i の行(すべての Kind)。`c_idxGC{k}`: GC k の行(x、uc、yc)。どちらも表の行番号で、変数表の順。
  線形化の部分だけが要るときは `iv(iv <= n_lin)`(先頭の部分なので、そのまま位置になる)。
- `bus.get_variable_map()`、`comp.get_variable_map()` は今と同じく網の表の制限(その行だけを同じ相対順で)。母線は `[tab, c_idx, tab_connection]`、機器は `[tab, tab_connection]` を返す。
  これらの `tab_connection` は両端がその表の中にある接続(と平衡値の行)だけで、GC の接続は網の表だけにある。
- `get_variable_map("rows")`(内部用)は `{sm_x; sm_V; sm_u; sm_uc; sm_y; sm_yc}` と接続の行を返す。

### 2.2 母線電流 I(決定 C の選択)

- **I は変数表に入れない**。シミュレーションだけの変数で、`SolverODE` が V の後に置く。線形化は I を知らない(今と同じ)。
  理由: I は母線の KCL を DAE で解くための補助変数で、モデルの信号でも線形化の変数でもない。表に入れて「線形化では飛ばす」印を付けるより、表に無いほうが使う側の条件が少ない。

## 3. 接続表(決定 A、提案)

`tab_connection`: 1 行が 1 本の接続(源 → 入力)。列は `Index`、`Kind`、`Source`、`Target`、`SourceIndex`、`TargetIndex`。

| Kind | 源 | 先 |
|---|---|---|
| `"equilibrium"` | なし(`Source = ""`、`SourceIndex = 0`) | 他に主な源(`observe`、`local`)がない入力: その入力の平衡値 |
| `"observe"` | 機器の出力 y か状態 x | LC の観測入力 / GC の入力 |
| `"local"` | LC の出力 yc | 親(機器か LC)の同名の入力 |
| `"global"` | GC の出力 yc | 振り分けの規則の先(LC の入力か機器の入力) |

規則(今と同じ):

- 機器の入力: 最上位の LC に同名の出力があれば `local`、なければ `equilibrium`。
- LC の入力: 入れ子の LC に同名の出力があれば `local`(観測より優先)、なければ観測(`iv_obsY` が出力、`iv_obsX` が状態)で `observe`、どちらでもなければ `equilibrium`。
- GC の入力(制御対象ごと): 制御対象の出力(同名の状態より優先)か状態の `observe`。
- GC の出力(制御対象、名前): その制御対象の LC(入れ子を含む、深さ優先)のうちその名前の入力を持つものすべてへ、なければ機器の同名の入力へ `global`。どちらもなければ行を作らない(検査は使う側、3.1)。
- 並び: 先の入力の変数表の順。同じ先の中では主な源(`equilibrium`、`observe`、`local`)が先、`global` が後。
- 入力の値は、その入力を先とする行の源の和(`equilibrium` は平衡値)。機器の入力には、さらにシナリオの入力イベントが足される。
  よって LC の入力が GC に駆動されると「GC がないときの値 + y_gcon」、機器の入力は「平衡値(または LC の出力)+ イベント + y_gcon」(今と同じ)。

### 3.1 振り分けを読む側

| 使う側 | 読むもの | 検査 |
|---|---|---|
| `add_global_controller` | GC を一覧に加えた網の表の、その GC の `observe` と `global` の行 | 入力に `observe` がない、または出力に `global` がない → 一覧から外して `GconPorts`。INFO `GconRoute` は `global` の行(「源 → 先」) |
| `Component.add_local_controller`、`remove_local_controller` | 編集の前後の網の表の、その機器を制御する GC の `global` の行 | 先が変わった GC の出力を INFO `GUILDA:Component:GconRouteChanged` で示す(記録は持たない) |
| `GlobalController.get_sys` | 網の表のその GC の `observe`(入力名 = 源の Label)と `global`(出力名 = 先の Label、行 = 源の GC 出力の行) | 入力が読めない、または出力の先がない → `GlobalControllerPort` |
| `Component.validate` | 網にあれば網の表、なければ機器の表の、その機器の入力を先とする行 | なし(`flag.inputs` の文) |
| `SolverODE`(5 節) | 網の表と接続表 | GC の出力の先がない → `GconNoTarget` |

- 網にない GC の `get_sys`(制御対象は網にある): 振り分けは決まらないので、出力は制御対象ごとの GC の出力そのもの(Label は GC の `yc`)。入力の検査は今と同じ。
- `GlobalController.sv_route` と `GUILDA:SolverODE:GconRouteChanged` は削除する。

## 4. 線形化(決定 C、提案)

- 線形化は表の先頭の部分(Kind x、Vre、Vim、u)だけを使う。`ResultLIN.tab_variable`、`Point` の並び、`StateName`/`InputName`、行列は変わらない。
- 制御器の入力 `uc` は線形化では消去する(今と同じく、各層の `get_sys` が LC と GC の入力を機器の出力・状態・電圧で表して閉じる)。
- `SolverLIN.point_vector`、`SolverLIN.solve`、`Bus.get_sys`、`Component.get_sys`、`ResultODE` は表を先頭の部分に切ってから使う(`n_lin` = Kind が x、Vre、Vim、u の行の数)。
- `ResultODE.tab_variable` も先頭の部分(今と同じ列と行。`Role` の列が加わる)。

## 5. シミュレーション(決定 B、C、D、提案)

### 5.1 変数ベクトル

```
z = [ x(表の順) ; V(母線ごとに Vre, Vim) ; I(母線ごとに Ire, Iim) ; u(表の順) ; uc(表の順) ]
```

- 表の行 r(Role variable)の z の位置: x と V は r、u と uc は r + 2 n_bus。
- 出力 y、yc は変数ではない。評価のたびに x、V、u から計算する(信号ベクトル s、表の y、yc の順で、源として読まれるものだけ)。
- 機器の出力は u を取らない(直達なし)ので、入力の残差は u、uc について一方向に解け、代数部は index 1 のまま。

### 5.2 新しいメソッドと ctx

- `SolverODE.build_index(net)`(新規、`Static, Access=private`): 網の表と接続表から、z の位置、評価の位置、接続の行列を作って struct で返す。
  `solve` はこれを `ctx` に入れる。`initialize_index`、`get_units` は削除。`set_offsets`、`set_gc_connect`、`restore_working_data` も不要になり削除する。
- `ctx` の主な中身:
  - `n_z`、`iv_V`、`iv_I`、`iv_in`(u と uc の位置)、`sv_owner`(z の各要素の所有者のタグ: 解列・地絡で除く要素)、`rv_z0`(平衡値の z)、`rm_M`(質量行列)。
  - `c_comp`、`c_lc`、`c_gc`: 各ブロックのオブジェクトと、その x、V、u の z の位置、出力の s の位置。
  - 接続の行列: `S_sig`(入力 × s)、`S_var`(入力 × z、状態の観測)、`rv_e`(`equilibrium` の平衡値)。
  - 相ごとの状態(`solve` が相の初めに更新): `lv_compOn`、`lv_gcOn`、`lv_fault`、入力イベントの関数と位置、状態のオフセット。
- 削除するプロパティ: `Component` の `iv_odeX`、`iv_odeU`、`iv_odeY`、`lv_odeUfromLC`、`iv_odeYtoU`、`l_isConnect`、`rv_Xoffset`、`rv_Uoffset`。
  `LocalController` の `iv_odeX`、`iv_odeU`、`iv_odeY`、`lv_odeUfromLC`、`iv_odeYtoU`、`rv_Xoffset`、`rv_Uoffset`。
  `GlobalController` の `iv_odeX`、`l_isConnect`、`rv_Xoffset`、`rv_Uoffset`、`sv_route`。`Bus` の `iv_odeX`、`iv_odeI`、`iv_odeU`、`l_isFault`。
- `l_isConnect`、`rv_Uoffset`、`rv_Xoffset`(と `l_isFault`)は ctx に移せる(読むのは SolverODE の中だけ)。`simulate` はモデルのオブジェクトに何も書かない。

### 5.3 右辺

1. 源として読まれる機器の出力 `s(y) = f_Y(t, x_mac, V_bus)`。
2. 機器: `dx = f_dx(t, x, V, u)`、`i = f_I(...)`(解列中は 0)。
3. LC: `dx = f_dx(t, x, V_bus, u_lc)`、`s(yc) = f_Y(...)`。各 LC は自分の x、V、u だけを読む(入れ子の合成はない)。
4. GC(接続中): `dx = f_dx(t, x, V_all, u_gc)`、`s(yc) = f_Y(...)`。解列中は評価せず出力 0。
5. 入力: `res(iv_in) = z(iv_in) - (rv_e + イベント(t) + S_sig s + S_var z)`。解列中の制御対象から読む GC の入力は重み 0(今の「0 を読む」)。
6. KCL(今と同じ)。

### 5.4 Jacobian

- ブロックごと: 機器の x の行に `[Axx, Bxv, Bxu]`、V の行に `-[Cix, Div, Diu]`、LC と GC の x の行に `[Axx, Bxv, Bxu]`。
- 入力の行: 単位行列 − `S_var` − `S_sig · Js`。`Js` は s の各行の `[Cyx, Dyv]`(機器)、`[Cyx, Dyv, Dyu]`(LC、GC)。
- I の行と列は今と同じ。

### 5.5 相、解列、地絡、結果

- 除く要素: 所有者のタグが解列(機器、GC)か地絡(母線)の z の要素(今と同じ規則。GC の解列では GC の uc も除く)。
- 次の相の初期値(`getNextPhase`)、初期値(`initial_condition`)、相の結果(`phase_result`)は ctx の位置と相の状態を使う。
- `phase_result` は z を線形化の部分の並び(x、V、u)に直して返す。`ResultODE` の列は表の先頭の部分と同じ並びになる。

## 6. 測定と確認(決定)

- IEEE14、IEEE68(AVR+PSS)、AGC の例で、変更の前後の軌道が解法の許容誤差の中で一致すること。
- IEEE68 の `simulate` の時間(1 スレッド、5 回の中央値)と変数の数を前後で報告する。15% を超えて遅くなれば最適化の前に報告する。

## 7. 未決

- なし(実装後の記録は 8 節)。

## 8. 実装

(実装後に記録する)
