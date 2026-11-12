# 線形化の接続器(`SolverLIN`)と共通の `get_sys`(Issue #121)

ブランチは `refactor/121-linearization-connector`(未 push、分岐元 `d41057ba`)です。この文書は手順 0 の仕様です。**実装はまだしていません。** コーディネータとユーザーの確認を待ちます。

**ラベル**: 無印または [事実] = コードを読んで確認。[計測] = MATLAB R2026a で実行して確認。[提案] = この文書の提案で、未承認。[未確認] = 調べていない。

パスは次のように省略します。`S/` = `_GUILDAsystem/`、`A/` = `S/_auxiliary/`。

## 0. 要点

1. 各モデルオブジェクト(機器、ローカル制御器、グローバル制御器)は、自分だけの線形ブロック(A, B, C, D, E と、変数表の Label による名前)を返します。ブロックはつなぎません。
2. `SolverLIN.solve` は数値だけの接続器です。ブロック、変数表、接続表、層の入出力(ポート)、網ではアドミタンス行列を受け取り、添字で接続した記述子形式のモデルを返します。`PowerNetwork` もモデルオブジェクトも読みません。
3. `get_sys` は `PowerSystemModel` に 1 つだけ置きます。ブロックを変数表の順に集め、`SolverLIN.solve` を呼び、`Format` に応じて返します。各層が決めるのは外部入力と出力(ポート)だけです。
4. 点は `Point` だけで与えます。`x, V, u` の位置引数は `_VersionSupport` の 1 つの関数が `Point` に変換し、非推奨の警告を出します。
5. **Kron と Feedback の比較 [計測]:** 共通の状態の A, B, C, D, E は全 13 系統・平衡点とずらした点で 1e-11 以下で一致します。ただし Feedback は入力から届かない状態を消すため、状態の数が異なります。IEEE68 などで消えるのは AVR の代数状態 `Vst`(有限の固有値は変わらない)ですが、**IEEJ の 4 系統では有限の固有値を持つ状態(`Ed` など)が消え、固有値の集合が一致しません**(§8)。Feedback を Kron の別名にするかは、ユーザーの判断を待ちます(§9 Q1)。

## 1. 現状(基準 `d41057ba`)

線形化のブロックは 2 つの別の方法でつながっています。

| 場所 | つなぎ方 |
|---|---|
| `S/@Component/get_sys.m` | 機器とローカル制御器を**名前**でつなぐ(`connect_blocks`)。制御器が読む状態は `X__<名前>` の出力を足して渡す(`connect_states`)。点では制御器の入力を `point_values` で求める |
| `S/@Bus/get_sys.m` | 機器の V2I モデルを並べ、電流を足す。I2V は `Dv_sum` の逆行列 |
| `A/@SolverLIN/solve.m` | 母線の V2I モデル、`Y`、グローバル制御器専用の `add_global_controllers`、点での GC の入力 `gc_input` |
| `A/@ResultLIN/get_ss.m` | Feedback: 母線を I2V にして `Y` で閉じ、GC を正帰還で閉じる(`via_feedback` と補助 8 関数) |

`get_sys` は 5 つのクラスにあり、引数が層ごとに違います。

| 層 | 引数 | 点 | 古さの検査 |
|---|---|---|---|
| `PowerNetwork` | `varargin` → `take_call_options` + `SolverLIN.get_options`(`OptionMap`、`resolve_options`、`validate_options`) | `Point` | 常に |
| `Component` | `x, V, u`、`port`、`tag`、`Controllers`、`Point`、`Format` | `x, V, u` か `Point`。`x, V, u` では制御器は**自分の平衡点**で線形化 | 点を与えないときだけ |
| `Bus` | `port`、`full`(無視)、`con`(無視)、`Point`、`Format` | `Point` | `Point` が空のときだけ |
| `LocalController` | `x, V, u`、`full`、`tag`、`Format` | `x, V, u` | 位置引数がないときだけ |
| `GlobalController` | `x, V, u`、`full`(無視)、`Format` | `x, V, u` | 常に |

## 2. `SolverLIN` に渡すデータと署名 [提案]

### 2.1 署名

```matlab
[sct_sys, output] = solve(obj, c_block, tab, tab_connection, sct_port)
```

`solve` を置き換えます(新しいメンバーではなく、署名の変更です)。`get_options`、`OptionMap`、`@SolverLIN/private/validate_options.m` は削除します。`point_vector` と `check_point`(Static, Hidden)は残します(§2.4)。

| 引数 | 中身 |
|---|---|
| `c_block` | ブロックの列(cell)。変数表の順(機器、その LC を深さ優先、…、GC)。各要素は struct `A, B, C, D, E, StateName, InputName, OutputName`。名前は変数表の `Label`。機器の電流の出力だけは表にない名前(§3.1) |
| `tab` | 層の変数表(全行。`uc`、`y`、`yc` を含む) |
| `tab_connection` | 層の接続表 |
| `sct_port` | 層の入出力。下の表 |

`sct_port` のフィールド:

| フィールド | 意味 |
|---|---|
| `sv_input` | 外部入力の名前(Label)。接続の和に**足されます**(今の `Component.get_sys` と同じ: AVR が駆動する `Vfield` への外部入力は AVR の出力に足される) |
| `sv_output` | 出力の名前。ブロックの出力・状態の Label、または母線電流の名前 |
| `sv_algebraic` | 代数変数にする母線電圧の Label(`Vre`, `Vim` の順で母線ごと)。網と I2V のときだけ。それ以外は空 |
| `cm_Y` | `sv_algebraic` の母線のアドミタンス行列(複素)。網は `get_admittance_matrix`、I2V は 0 |
| `sv_current` | `sv_algebraic` の母線ごとの電流の名前。網では出力用の `I` の名前、I2V では外部入力の電流 |
| `tab_current` | ブロックの電流の出力と母線の対応(列 `Label`、`Bus`)。`get_sys` が機器から作る |

### 2.2 接続の計算

1. ブロックを対角に並べます(`blkdiag`)。状態はブロックの順 = 変数表の `x` の順です。
2. ブロックの各入力 ℓ について、値を次の和とします。
   - `tab_connection` で `TargetIndex` が ℓ の行の源: `y`・`yc`(ブロックの出力)、`x`(状態の選択)。`"equilibrium"` の行は偏差 0 なので何も足しません。`"global"` の行も同じ扱いです。
   - ℓ が `sv_input` にあれば外部入力。
   - ℓ が母線電圧で `sv_algebraic` にあれば代数変数 v。そうでなければ外部入力(V2I、LC、GC)。
3. ブロックの入出力 u_b, y_b を消去します: u_b = K y_b + S_x x + S_v v + P w、y_b = C x + D u_b から (I − D K) y_b = …。`I − D K` が特異なら `GUILDA:SolverLIN:AlgebraicLoop`(新しい ID、§7)。今の `connect_blocks` と同じ式です。
4. `sv_algebraic` があれば、母線ごとに電流の収支の行を加えます。網: `0 = Y v − Σ I`、I2V: `0 = I_ext − Σ I`。Σ は `tab_current` でその母線の機器の電流を足したものです。v は代数変数で E = 0 です。今の `rm_Avx = −Cix`、`rm_Avv = Y − Div`、`rm_Bv = −Diu` と同じ符号です。
5. 出力 `sv_output` を C, D の行として選びます。

### 2.3 戻り値

`sct_sys` は記述子形式のモデル

```
E [dx; dv]/dt = A [x; v] + B w,   y = C [x; v] + D w
```

で、フィールドは `A, B, C, D, E, StateName, InputName, OutputName` と、代数変数の数 `n_v` です。`StateName` は `[x の Label; v の Label]`、`InputName` は `sv_input`、`OutputName` は `sv_output` です。

`output` は数値の結果だけです: `s_issue`(`""`、`"NotFinite"`、`"SingularAvv"`)、`rcond_Avv`、`n_x`、`n_v`、`n_u`。`flag` は `s_issue == ""` です。メッセージ(`output.message`、`sv_faultBus`、`l_equilibrium`)は `get_sys` が加えます。

ブロックが有限でなければ、どのブロックかを状態名で示して `GUILDA:SolverLIN:JacobianNotFinite` です(今と同じ ID)。ブロックの名前が変数表にない場合は `GUILDA:SolverLIN:VariableMap`(今の ID を、意味を変えて使う)。

### 2.4 `point_vector`

今の `point_vector(layer, Point)` を残し、`LocalController` と `GlobalController` の層を加えます(§4.2)。`get_sys` が呼びます。`SolverLIN.solve` は呼びません(点の値はブロックに入っている)。

## 3. 各層のブロックのメソッド [提案]

名前は `get_linear_block` です(Hidden、public)。`local_LQR.design_gain` が機器単体のブロックを使うため public にします。

```matlab
sct_block = get_linear_block(obj, x, V, u)
```

| クラス | x | V | u | 返すもの |
|---|---|---|---|---|
| `Component` | 機器の状態 | 母線電圧 `[Vre; Vim]` | 機器の入力 | 入力 `[V の Label; u の Label]`、状態 `x の Label`、出力 `[電流 2 行; y の Label]` |
| `LocalController` | 制御器の状態 | 親の母線電圧 | 制御器の入力 `uc` | 入力 `[V の Label; uc の Label]`、状態、出力 `yc の Label` |
| `GlobalController` | 制御器の状態 | 全母線の電圧 `[Vre1; Vim1; …]` | 制御対象ごとの `uc` | 入力 `[全母線の V の Label; uc の Label]`、状態、出力 `yc の Label`(制御対象ごと) |

- 中身は今の `linearize_alone`(`Component`、`LocalController`)と `GlobalController.get_sys` の行列の部分です。Jacobian の契約(`f_JacobiDx`、`f_JacobiI`、`f_JacobiY`、`f_Mass`)と、`[]` を 0 に直す `shape` は変えません。
- 名前はすべて変数表の Label です。出力の名前が自分の状態名と同じなら `"Y_"` を付けます(今と同じ)。
- `Bus`、`PowerNetwork`、`Branch` はブロックを持ちません。

### 3.1 機器の電流の名前

電流は変数表にありません(`notes/variable-connection-map.md` §2.2 の決定)。機器のブロックの電流の出力は、今の `Component.get_sys` と同じ機器のタグ付きの `Ire`、`Iim` です。母線の収支で足すために、`get_sys` が `tab_current`(Label → 母線)を機器から作ります。

### 3.2 GC のブロックの名前の変化

今の `GlobalController.get_sys` は、入力を観測する源の Label、出力を駆動する先の Label(先ごとに 1 行)で名付けています。新しいブロックは自分の `uc`、`yc` の Label です。行き先は接続表の `"observe"` と `"global"` の行で決まり、接続器がつなぎます。**`gc.get_sys()` の入出力の名前と出力の行数が変わります**(行列の値は、先ごとに複製されていた行をまとめたものと同じ)。

## 4. 各層のポートの規則 [提案]

ポートの関数は `get_linear_port`(`PowerSystemModel` で protected に宣言し、各層で上書き)です。

```matlab
sct_port = get_linear_port(obj, s_port)
```

`PowerSystemModel` の既定の実装は `GUILDA:PowerSystemModel:NoLinearModel` で止まります(`Branch` はこれを継承するので、`branch.get_sys()` はこのエラーです)。

| 層 | 集めるブロック | 外部入力 `sv_input` | 出力 `sv_output` | 母線電圧 |
|---|---|---|---|---|
| `Component`、`Port="V2I"`(既定) | 機器 + LC(深さ優先) | V、u、uc | I(機器のタグ)、y、yc | 外部入力 |
| `Component`、`Port="I2V"` | 同上 | I(機器のタグ)、u、uc | V、y、yc | 代数変数(`Y` = 0)、Kron で消去 |
| `Bus`、`Port="V2I"`(既定) | 各機器 + その LC | V、u、uc | I(母線のタグ、機器の和)、y、yc | 外部入力 |
| `Bus`、`Port="I2V"` | 同上 | I(母線のタグ)、u、uc | V、y、yc | 代数変数(`Y` = 0)、Kron で消去 |
| `PowerNetwork` | 全機器 + LC、全 GC | u | y、yc | 代数変数(`Y` = 網)、`Method` で縮約 |
| `LocalController` | 自分だけ | V、uc | yc | 外部入力 |
| `GlobalController` | 自分だけ | 全母線の V、uc | yc | 外部入力 |

- 名前の並びは変数表の順です。**今との違い:** `Bus` の入力は「機器 1 の u、機器 1 の uc、機器 2 の u、…」から「全機器の u、全 uc」に、出力も「全 y、全 yc」に変わります。`Component` と `LocalController` の電圧の入力の名前は、機器・制御器のタグから母線の Label(変数表の Vre, Vim)に変わります。
- 機器のない母線: V2I は今と同じく状態なし、I = 0、D = 0 です。I2V は Avv が特異なので `GUILDA:PowerSystemModel:NoI2V` です。
- `Port` は `Component` と `Bus` だけが受け付けます。ほかの層で与えると `GUILDA:PowerSystemModel:PortNotApplicable`(新しい ID)です。

### 4.1 点での制御器の入力

ブロックの点(`x, V, u`)は `get_sys` が `Point` から作ります。制御器の入力 `uc` の値は、接続表の源の和(`"global"` を除く)で求めます。源の `y` は `f_Y(0, x, V)`、`yc` は深いほうの制御器から順に `f_Y(0, x, V, uc)`、`x` は状態、`"equilibrium"` は平衡値です。今の `point_values`(`Component`)と `gc_input`(`SolverLIN`)をまとめたもので、`get_sys.m` の中の局所関数です。

- 位置引数 `x, V, u` で呼んでも同じ規則なので、**制御器は与えた点で線形化されます**(今の不整合の解消。ユーザーの決定)。
- `"global"` の源を足すかは §9 Q5 です。今は足していません。

### 4.2 `LocalController` と `GlobalController` の点

この 2 層には `get_variable_map` がありません。`Point` のベクトルの並びは次のとおりです(位置引数 `x, V, u` の並びと同じ)。

- `LocalController`: 自分の x、親の母線の Vre, Vim、自分の uc。親の機器の変数表から Owner で選びます。
- `GlobalController`: 自分の x、全母線の Vre, Vim、自分の uc(制御対象ごと)。網の変数表から選びます。

`{sim, t}` は `ResultODE.get_point` が `uc` を返さないので、この 2 層では `GUILDA:SolverLIN:PointLayer` で止めます(§9 Q6)。

## 5. `get_sys`(`PowerSystemModel`)[提案]

### 5.1 署名と引数

```matlab
[sys, flag, output] = get_sys(obj, x, V, u, opt)
```

ファイルは `A/@PowerSystemModel/get_sys.m` です。`S/@Component/get_sys.m`、`S/@Bus/get_sys.m`、`S/@LocalController/get_sys.m`、`S/@GlobalController/get_sys.m`、`S/@PowerNetwork/get_sys.m` と、各 classdef の宣言を削除します。

```matlab
arguments (Input)
    obj
    x (:,1) double = zeros(0,1)   % COMPAT: 位置引数の点 (Component, LocalController, GlobalController)
    V (:,1) double = zeros(0,1)
    u (:,1) double = zeros(0,1)
    opt.Point                      % [], 層の変数表の順のベクトル, {sim, t}。既定なし = 平衡点
    opt.Port (1,1) string {mustBeMember(opt.Port, ["V2I","I2V"])}   % Component, Bus だけ。既定なし = "V2I"
    opt.Method (1,1) string {mustBeMember(opt.Method, ["Kron","Feedback","DAE"])}   % 既定なし = GUILDA.setting
    opt.Coordinate (1,1) string {mustBeMember(opt.Coordinate, ["theta&V","theta&rho","Vre&Vim"])}   % 既定なし = GUILDA.setting
    opt.PlotFcn                    % 既定なし = GUILDA.setting。tools.check_plotfcn
    opt.Input (1,:) string         % 既定なし = すべての入力
    opt.Output (1,:) string        % 既定なし = 各 Method の既定の出力
    opt.Format (1,1) string {mustBeMember(opt.Format, ["GUILDAorigin","struct","ss"])} = "GUILDAorigin"
end
```

- 既定のない名前は、呼び出しが省くと `opt` にありません。`Method`、`Coordinate`、`PlotFcn` は、そのとき `GUILDA.config("Linearization")` の値を使います。`take_call_options` は使いません。
- 名前の照合は MATLAB の規則(大文字小文字を区別しない、部分一致)なので、今の `"port"` もそのまま `Port` になります。
- **削除する引数:** `Component` の `tag`、`Controllers`、`LocalController` の `full`、`tag`、`Bus` の `full`、`con`、`GlobalController` の `full`。名前はいつも Label です。`Controllers=false`(機器単体)は `get_linear_block` で得られます。`local_LQR.design_gain` はそちらに書き換えます(§9 Q4)。
- `Method` と `Coordinate` は網だけに効きます。ほかの層では受け付けますが何もしません(§9 Q7)。
- 位置引数は `nargin > 1` のとき `v3_get_sys_point(obj, x, V, u)` が `Point` にします(§6)。`Point` と同時に与えるとエラーです。

### 5.2 流れ

1. 位置引数を `Point` にする(§6)。
2. 古さの検査(§5.3)。
3. 層の変数表と接続表: `Component`、`Bus`、`PowerNetwork` は `get_variable_map`。`LocalController` と `GlobalController` は親(機器、網)の表から自分の行を選ぶ(局所関数)。
4. 点: `SolverLIN.point_vector(obj, Point)`。有限でなければ `GUILDA:SolverLIN:PointNotFinite`(今と同じ)。
5. 点での制御器の入力(§4.1)と、各ブロック `get_linear_block` を集める。
6. ポート `get_linear_port(Port)`、`tab_current`、網なら `cm_Y`。
7. `SolverLIN.solve`(網は `obj.solver_LIN`、ほかは `SolverLIN()`)。
8. `ResultLIN` を作る(§5.4)。母線電圧 0 の点は今と同じく INFO とメッセージで知らせる(ID は §7)。
9. `Format`: `"GUILDAorigin"` は `ResultLIN`、`"struct"` と `"ss"` は `result.get_ss(Method, Input, Output, Format)`。

### 5.3 古さの検査

全層で 1 つの関数にし、エラーは `GUILDA:PowerSystemModel:Stale` と `GUILDA:PowerSystemModel:InputEdited` にします(`msg` は呼び出し元のクラスの ID しか受け付けないため)。メッセージには層の種類とタグを入れます。

検査する対象は集めたブロックのオブジェクトと網です。いつ検査するかは §9 Q3 です。提案は「`odefcn` と入力の編集はいつも、`powerflow` と `equilibrium` は `Point` が平衡点のときだけ」です(`f_*` が古いと、どの点でもモデルが違うため)。

### 5.4 `ResultLIN` の作り方と `get_ss`

`ResultLIN` のコンストラクタの入力を `ResultLIN(net, solver, options, flag, output, elapsed, tab_variable, rv_point, sct_sys)` にします。`sct_sys` は §2.3 の接続したモデルに、網では `cm_Y`、`cv_V`、`sv_I`(母線電流の名前)を加えたものです。

- `rm_Axx, rm_Axv, rm_Bx, rm_Avx, rm_Avv, rm_Bv, rm_E` は `sct_sys` の x と v の部分行列です。網では今と同じ値です。`Component`・`Bus` の V2I では今と同じく `rm_Axx = A`、`rm_Axv = B(:, V)`、`rm_Bx = B(:, u)`、`rm_E = E` です。
- 出力の行(y、yc)は `sct_sys.C, D` の行です。今の `sct_model.sct_output`、`c_sysBus`、`c_sysY`、`c_sysL`、`c_sysGC`、`lv_nonUnit` はなくなります。
- `get_ss` が縮約するもの:
  - `"Kron"`: v を消去(今の `via_kron`)。I2V の `Component` と `Bus` は、いつもこれです。
  - `"DAE"`: v を残し `Coordinate` で変換(今の `via_dae`)。
  - `"Feedback"`: §8 と §9 Q1 の決定による。別名にするなら `"Kron"` と同じ処理です。
  - v のない層(V2I、LC、GC): 接続したモデルそのもの。`Method` は効きません。
- `Input`、`Output` の選択(`select_output`、`input_index`)は今のままです。`Output` の種類 `"y"` は `y` と `yc` の Label です。
- `A … OutputName` のプロパティは、今と同じく `get_ss(Method)` の結果です。

## 6. 互換の関数 [提案]

`S/_VersionSupport/v3_get_sys_point.m`(新しいメンバー 1 つ):

```matlab
Point = v3_get_sys_point(layer, x, V, u)
```

- `Deprecated("GetSysPositionalPoint")` で 1 回だけ警告します(`Deprecated.xml` にキーを加える)。
- `Component`: `[x; LC の状態の平衡値; V; u]`(機器の変数表の x, Vre, Vim, u の並び)。
- `LocalController`: `[x; V; u]`(§4.2 の並び)。
- `GlobalController`: `[x; V; u]`(§4.2 の並び)。
- 省いた引数は平衡値で埋めます(今の既定値と同じ)。
- `Bus`、`PowerNetwork` で位置引数を与えると `GUILDA:v3_get_sys_point:Positional` です。

v3 の `Algorithm` と `NonUnit`(`v3_linearize_args`)の扱いは §9 Q2 です。提案は PF と同じく削除です。削除すると、`v3_linearize_args.m`、`v3_nonunit_range.m`、`v3_nonunit_dynamic.m`(と XML)、`v3_solver_nonunit.m`、`SolverLIN.NonUnit`、`Deprecated` のキー `LinearizeAlgorithm`、`LinearizeNonUnit`、`SolverLinNonUnit` がなくなり、`Algorithm=` と `NonUnit=` は arguments ブロックのエラーになります。

## 7. 消えるエラー ID と新しい ID [提案]

| 消える ID | 代わり |
|---|---|
| `GUILDA:Component:Stale`、`GUILDA:Bus:Stale`、`GUILDA:LocalController:Stale`、`GUILDA:GlobalController:Stale`、`GUILDA:SolverLIN:Stale` | `GUILDA:PowerSystemModel:Stale` |
| `GUILDA:Component:InputEdited`、`GUILDA:Bus:InputEdited`、`GUILDA:LocalController:InputEdited`、`GUILDA:GlobalController:InputEdited`、`GUILDA:SolverLIN:InputEdited` | `GUILDA:PowerSystemModel:InputEdited` |
| `GUILDA:Component:NoI2V`、`GUILDA:Bus:NoI2V` | `GUILDA:PowerSystemModel:NoI2V` |
| `GUILDA:SolverLIN:GroundFault`(INFO) | `GUILDA:PowerSystemModel:GroundFault` |
| `GUILDA:SolverLIN:GlobalControllerPort` | なし(GC のポートは `add_global_controller` と GC のブロックで検査済み) |
| `GUILDA:resolve_options:UnknownName`(線形化) | MATLAB の arguments ブロックのエラー |
| `GUILDA:ResultLIN:NoUnitBus`、`GUILDA:ResultLIN:NoI2V`、`GUILDA:ResultLIN:GlobalControllerPort` | なし(Feedback を別名にする場合) |
| `GUILDA:v3_nonunit_dynamic:NonUnitDynamicBus`、`GUILDA:v3_nonunit_range:NonUnit`、`GUILDA:Deprecated:LinearizeAlgorithm`、`LinearizeNonUnit`、`SolverLinNonUnit` | なし(§9 Q2 で削除する場合) |

残る ID: `GUILDA:SolverLIN:PointType`、`PointSize`、`PointSimType`、`PointSimSize`、`PointLayer`、`PointNotFinite`、`JacobianNotFinite`、`VariableMap`(意味を変える)、`GUILDA:GlobalController:GlobalControllerPort`(ブロックのメソッドで)、`GUILDA:ResultLIN:NotFinite`、`SingularAvv`、`UnknownOutput`、`StateNotInModel`、`UnknownInput`。

新しい ID: `GUILDA:SolverLIN:AlgebraicLoop`、`GUILDA:PowerSystemModel:NoLinearModel`、`GUILDA:PowerSystemModel:PortNotApplicable`、`GUILDA:v3_get_sys_point:Positional`、`GUILDA:Deprecated:GetSysPositionalPoint`。

## 8. Kron と Feedback の比較 [計測]

基準 `d41057ba`、MATLAB R2026a。各系統で `net.linearize(Point=p)` を 1 回求め、`get_ss("Kron")` と `get_ss("Feedback")`(`Format="struct"`)を状態名・入力名で対応させて比べました。ずらした点は、状態に `0.01·randn·max(1,|x|)` を足したものです(`rng(1)`)。Kron の出力は状態そのもの(C = I)なので、Feedback の出力と名前で対応させて C, D を比べました。固有値は有限のものの相対距離(片方の各固有値から他方の最も近い固有値まで)の最大です。

| 系統 | 点 | 状態 Kron / Feedback | 共通の状態の A, B, C, D, E の最大差 | 固有値 F→K / K→F | Feedback が消す状態 |
|---|---|---|---|---|---|
| IEEE14bus | 平衡 | 30 / 30 | ≤ 3.6e-15 | 7.6e-13 / 7.6e-13 | なし |
| IEEE14bus | ずらす | 30 / 30 | ≤ 2.4e-15 | 2.1e-14 / 2.1e-14 | なし |
| Ishizaki6Bus | 平衡 | 4 / 4 | ≤ 4.0e-15 | 1.1e-12 / 1.1e-12 | なし |
| Ishizaki6Bus | ずらす | 4 / 4 | ≤ 5.1e-15 | 3.2e-13 / 3.2e-13 | なし |
| IEEE68bus | 平衡 | 144 / 128 | ≤ 4.1e-12 | 1.1e-11 / 1.1e-11 | `Vst`(AVR、E = 0)16 個 |
| IEEE68bus | ずらす | 144 / 128 | ≤ 4.6e-12 | 3.4e-12 / 3.4e-12 | 同上 |
| IEEE9bus | 平衡・ずらす | 27 / 24 | ≤ 6.2e-15 | ≤ 1.7e-13 | `Vst` 3 個 |
| IEEE39Bus、IEEE14bus_lossless、IEEE14bus_NoTap、TEST31bus、Txt3Bus | 平衡・ずらす | 同数 | ≤ 6.8e-14 | ≤ 3.3e-12 | なし |
| IEEJ_EAST10 | 平衡・ずらす | 140 / 124 | ≤ 9.7e-14 | 1.3e-13 / **3.3e-1** | `Ed` など 16 個(有限の固有値 −1, −1/9, −4, −5) |
| IEEJ_WEST10 | 平衡・ずらす | 140 / 130 | ≤ 9.0e-13 | 8.5e-13 / **4.7e-1** | `Ed` など 10 個(固有値 −1) |
| IEEJ_EAST30 | 平衡・ずらす | 420 / 375 | ≤ 8.9e-14 | 5.0e-13 / **3.3e-1** | 45 個 |
| IEEJ_WEST30 | 平衡・ずらす | 410 / 368 | ≤ 4.3e-14 | 6.4e-13 / **6.3e-1** | 42 個 |

グローバル制御器と PSS を付けた場合(第 1 発電機に AVR_ST1 + PSS1、Pmech を持つ最初の 2 機に `agc-PI`):

| 系統 | 点 | 状態 Kron / Feedback | 共通の状態の最大差 | 固有値 | 消す状態 |
|---|---|---|---|---|---|
| Ishizaki6Bus | 平衡・ずらす | 11 / 10 | ≤ 2.0e-15 | ≤ 4.4e-14 | `Vst` 1 個 |
| IEEE68bus | 平衡・ずらす | 145 / 129 | ≤ 5.0e-12 | ≤ 2.3e-10 | `Vst` 16 個 |

(IEEE14bus に GC を付けた場合は 1 回目の試行で平衡点・ずらした点とも差 ≤ 1.1e-14、固有値 ≤ 1.6e-13 でした。)

**結論:**

- 指定の 3 系統(IEEE14、Ishizaki6、IEEE68)では、平衡点・ずらした点とも、共通の状態の A, B, C, D, E は 5e-12 以下、有限の固有値は 2.3e-10 以下で一致します。Feedback が消すのは `E = 0` の `Vst` だけで、有限の固有値は変わりません。
- ただし Feedback は形が違います: 状態が少ない(`remove_unreachable_states` が入力から届かない状態を消す)、GC の状態が最後(Kron は最初)、出力名がある(Kron は出力名なし)。
- **IEEJ の 4 系統では、Feedback が有限の固有値を持つ状態を消します。** 消える状態は入力から届かない(可制御でない)部分で、伝達関数は同じですが、固有値の集合は一致しません。例: IEEJ_EAST10 で −1(×10)、−1/9(×2)、−4(×2)、−5(×2)が Feedback にありません。
- よって「数値精度で一致」は共通の状態の行列については成り立ちますが、モデル全体(状態の数と固有値)では成り立ちません。指示どおり、ここで止めて報告します。別名にすると Feedback の結果は Kron と同じ形(状態が増え、IEEJ では固有値が増え、GC の状態が先頭、出力名なし)に変わります。

計測のスクリプトはスクラッチパッドにあり、コミットしていません。実装では F7 に同じ比較を入れます(§10)。

## 9. 未決の事項(ユーザーの判断)

| # | 問い | 提案 |
|---|---|---|
| Q1 | Feedback を Kron の別名にするか。共通の状態は一致するが、Feedback は可制御でない状態を消すため、IEEJ では固有値が減る(§8) | 別名にする。固有値解析では消さない Kron が正しく、`remove_unreachable_states` が必要なら `get_ss` の後に利用者が `minreal` などで行える。設定の既定値 `Method="Feedback"` は `"Kron"` に変える |
| Q2 | v3 の `Algorithm=`、`NonUnit=`、`solver_LIN.NonUnit` を残すか | PF と同じく削除(§6、§7) |
| Q3 | 古さの検査をいつ行うか | `odefcn` と入力の編集はいつも、`powerflow`・`equilibrium` は平衡点のときだけ(§5.3) |
| Q4 | `Controllers`、`tag`、`full`、`con` を削除してよいか | 削除。`local_LQR.design_gain` は `comp.get_linear_block(x0, V, u)` を使う |
| Q5 | 点での制御器の入力に `"global"` の源(GC の出力)を足すか | 今と同じく足さない。シミュレーションとの一致を求めるなら別の Issue |
| Q6 | `LocalController`、`GlobalController` で `Point={sim, t}` を受け付けるか | 受け付けない(`PointLayer`)。必要なら網の点から作る |
| Q7 | 網以外で `Method`、`Coordinate` を与えたらエラーにするか | 何もしない(エラーにしない) |
| Q8 | `net.linearize` をどうするか。今は `get_sys(Format="GUILDAorigin")` と同じ `ResultLIN` を返し、違いは flag が false のときにエラーにしないことだけ | 案 A(推奨): 削除し、`get_sys` の `"GUILDAorigin"` は flag が false でもエラーにせず結果を返す(`"struct"`、`"ss"` はエラー)。案 B: `get_sys(…, Format="GUILDAorigin")` を呼ぶだけの関数として残す。どちらも新しいメンバーは不要 |
| Q9 | `comp.get_sys` などの `varargout`(StateName、InputName、OutputName の cellstr)を残すか | 削除。出力は全層で `[sys, flag, output]` |
| Q10 | `get_sys` の入出力の名前と並びの変化(§3.2、§4)を受け入れるか | 受け入れる。変数表の Label と順に揃える |
| Q11 | 今のモデルとの一致を確かめる基準値をどう持つか | 基準 `d41057ba` で全同梱系統と全機器・制御器のモデルを求め、MAT ファイルにして `+DebugScript` に置く(置き場所の規則の確認が必要)。名前で対応させて比べる |

## 10. 実装の手順(承認後)

各手順の後に small(`DebugScript.run_all("FailOnUnexpected",false)`)を実行してコミットします。既知の失敗は F7 `PointFromASimulationResultAndATime` と F8 の 2 件です。

1. `test:` 基準値の MAT ファイル(Q11)と比較のテスト(全同梱系統の Kron・DAE、平衡点とずらした点、全機器・制御器のモデル、名前で対応)。
2. `refactor:` `get_linear_block`(3 クラス)と `get_linear_port`(`PowerSystemModel` と 5 層)を加える。この時点では旧 `get_sys` から呼ぶ。
3. `refactor:` `SolverLIN.solve` を接続器にし、`get_options`、`OptionMap`、`validate_options`、`add_global_controllers` を削除。
4. `refactor:` `PowerSystemModel.get_sys` と `v3_get_sys_point` を加え、5 つの `get_sys`、`connect_blocks`、`connect_states`、`point_values`、`gc_input` を削除。呼び出し元(`SolverLIN`、`local_LQR`、`get_environment` は v2 の未使用コード)を書き換え。
5. `refactor:` `ResultLIN` を `sct_sys` から作る。Feedback(Q1)と `net.linearize`(Q8)。
6. `refactor:` v3 の互換(Q2)。
7. `test:` DebugScript の呼び出しと期待するエラー ID を書き換え。
8. `docs:` 開発者ページ(`feature-linearization.html`、`api-design.html`、`class-design.html`)、ヘルプ、`status.md`。JA です・ます、最後に Update log。
9. medium を 1 回実行。

### 10.1 新しいメンバーの一覧

| メンバー | 場所 | 許可 |
|---|---|---|
| `get_sys` | `PowerSystemModel` | 指示で許可 |
| `get_linear_block` | `Component`、`LocalController`、`GlobalController` | 指示で許可(層ごとに 1 つ) |
| `get_linear_port` | `PowerSystemModel`(既定でエラー)、`Component`、`Bus`、`PowerNetwork`、`LocalController`、`GlobalController` | 指示で許可(層ごとに 1 つ) |
| `SolverLIN.solve`(署名の変更) | `SolverLIN` | 指示で許可(接続器の入口 1 つ) |
| `v3_get_sys_point` | `_VersionSupport` | 指示で許可 |

これ以外の新しいメンバーはありません。点での制御器の入力、古さの検査、LC・GC の変数表の選択、`tab_current` の作成は `get_sys.m` の局所関数です。`ResultLIN` のコンストラクタの引数は変わりますが、メンバーは増えません(`sct_model` は中身が変わる)。
