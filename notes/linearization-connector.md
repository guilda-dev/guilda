# 線形化の接続器(`SolverLIN`)と共通の `get_sys`(Issue #121)

ブランチは `refactor/121-linearization-connector`(未 push、分岐元 `d41057ba`)です。この文書は手順 0 の仕様で、ユーザーの決定(2026-11-13、§9.1)を受けて実装しました。実装で仕様と変えた点と結果は §11 にあります。その後のフォローアップ(2026-11-13)で、点を最初の位置引数にし、ポートを V2I に固定し、v3 の互換を削除しました(§12)。§2〜§7 と §11 のうち、`Point` オプション、`Port`、電流を入力とするポート、位置引数の互換の記述は §12 で置き換わった、当時の記録です。

**ラベル**: 無印または [事実] = コードを読んで確認。[計測] = MATLAB R2026a で実行して確認。[提案] = この文書の提案で、未承認。[未確認] = 調べていない。

パスは次のように省略します。`S/` = `_GUILDAsystem/`、`A/` = `S/_auxiliary/`。

## 0. 要点

1. 各モデルオブジェクト(機器、ローカル制御器、グローバル制御器)は、自分だけの線形ブロック(A, B, C, D, E と、変数表の Label による名前)を返します。ブロックはつなぎません。
2. `SolverLIN.solve` は数値だけの接続器です。ブロック、変数表、接続表、層の入出力(ポート)、網ではアドミタンス行列を受け取り、添字で接続した記述子形式のモデルを返します。`PowerNetwork` もモデルオブジェクトも読みません。
3. `get_sys` は `PowerSystemModel` に 1 つだけ置きます。ブロックを変数表の順に集め、`SolverLIN.solve` を呼び、`Format` に応じて返します。各層が決めるのは外部入力と出力(ポート)だけです。
4. 点は `Point` だけで与えます。`x, V, u` の位置引数は `_VersionSupport` の 1 つの関数が `Point` に変換し、非推奨の警告を出します。
5. **Kron と Feedback の比較 [計測]:** 共通の状態の A, B, C, D, E は全 13 系統・平衡点とずらした点で 1e-11 以下で一致します。ただし Feedback は入力から届かない状態を消すため、状態の数が異なります。IEEE68 などで消えるのは AVR の代数状態 `Vst`(有限の固有値は変わらない)ですが、**IEEJ の 4 系統では有限の固有値を持つ状態(`Ed` など)が消え、固有値の集合が一致しません**(§8)。ユーザーの決定により Feedback は廃止します(§9.1)。

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
   - `tab_connection` で `TargetIndex` が ℓ の行の源: `y`・`yc`(ブロックの出力)、`x`(状態の選択)。`"local"`、`"observe"`、`"global"` の行を足します。`"equilibrium"` の行は偏差 0 なので何も足しません。
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
    opt.Method (1,1) string {mustBeMember(opt.Method, ["Kron","DAE"])}   % 既定なし = GUILDA.setting
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
| `GUILDA:ResultLIN:NoUnitBus`、`GUILDA:ResultLIN:NoI2V`、`GUILDA:ResultLIN:GlobalControllerPort` | なし(Feedback の廃止、§9.1) |
| `GUILDA:v3_nonunit_dynamic:NonUnitDynamicBus`、`GUILDA:v3_nonunit_range:NonUnit`、`GUILDA:Deprecated:LinearizeAlgorithm`、`LinearizeNonUnit`、`SolverLinNonUnit` | なし(§9 Q2 の削除) |

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

### 9.1 決定(2026-11-13)

- **Q1: Feedback は廃止します。Kron の別名にもしません。** `Method` は `"Kron"` と `"DAE"` だけを受け付け、`GUILDA.setting` の既定値(Linearization の `Method`)は `"Kron"` にします。`Method="Feedback"` は arguments ブロックの通常の検証エラーで、互換の警告は出しません。`via_feedback` とその補助関数、Feedback だけが使うエラー ID(`GUILDA:ResultLIN:NoUnitBus`、`NoI2V`、`GlobalControllerPort`)を削除し、Feedback を使う・名指す呼び出し元、テスト、設定の既定値、文書をすべて書き換えます。
- **Q8: `net.linearize` は削除します(案 A)。** `get_sys` は `Format="GUILDAorigin"` なら flag が false でも `ResultLIN` を返します。`"struct"` と `"ss"` では flag が false ならエラーです。`linearize` を使う呼び出し元、テスト、文書を書き換えます。
- **Q2〜Q7、Q9〜Q11:** 提案のとおりです。Q11 の基準値の置き場所は `_GUILDAdoc/developer/` の配置の規則を確かめて決めます。
- 実装の前に、ブランチを `refactor/design-alignment`(`8ba7c955`)に追いつかせます。

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

## 11. 実装の記録(2026-11-13)

ブランチを `refactor/design-alignment`(`8ba7c955`)に追いつかせ(マージ `de2a93f5`)、その上で実装しました。

### 11.1 仕様から変えた点 [事実]

- **ポートの構造体:** `sv_current` の代わりに `tab_bus`(列 `Bus`、`Vre`、`Vim`、`Ire`、`Iim`。層の母線の電圧と電流の Label)を持ちます。`tab_current` は `get_sys` が加え、列は `Label`、`Bus`、`Name`(`"Ire"` か `"Iim"`)です。網の出力 `I` は `Y v`、V2I の母線の出力 `I` は機器の電流の和です。
- **ブロックの `Owner`:** ブロックの構造体に任意のフィールド `Owner`(「the component B003LPQ1 at bus B003」など)を加えました。`JacobianNotFinite` のメッセージに使います。メンバーではありません。
- **`PointNotFinite` は `SolverLIN.point_vector` で出します。** `msg` は呼び出し元のクラスの ID しか受け付けないので、`PowerSystemModel.get_sys` からは `GUILDA:SolverLIN:*` を出せません。
- **新しい ID `GUILDA:PowerSystemModel:PointAndPositional`:** `Point` と位置引数を同時に与えたとき。
- **位置引数の検証:** `x`、`V`、`u` は `(:,1) {mustBeNumeric, mustBeReal}` です。`double` にすると、削除した名前(`Controllers` など)の文字列が位置引数として数値に変換されて通ってしまうためです。
- **`StateNotInModel` も削除しました。** Feedback だけが状態を消していたためです(§9.1 の「Feedback だけが使う ID」)。
- **`GUILDA:LocalController:Stale` と `InputEdited` は残します。** `con.validate` が使います。
- **手順の分け方:** §10 の手順 2〜7 は 1 つのコミットにしました。手順 2 の「旧 `get_sys` から呼ぶ」途中の形は、旧コードを書き換える捨てるコードになり、手順 3〜5 は `SolverLIN.solve` の署名の変更で互いに依存するためです。各コミットの時点でテストは通ります。

### 11.2 基準値(Q11)[事実]

- `_GUILDAdoc/developer/` の配置の規則(`folder-structure.html`)には、テストのデータファイルの置き場所の規定がありません。テストの補助が置かれている `+DebugScript/+helper/` に `linearization_reference.mat`(約 2.2 MB)を置き、作り方を `+DebugScript/archive/make_linearization_reference.m` に残しました(置き換えた後のコードでは動かないので archive。「参照のために残すコード」の規則)。規則に追記するかはコーディネータの判断です。
- 中身: 同梱の 13 系統と GC 付きの 2 系統(Ishizaki6Bus、IEEE14bus に AVR_ST1 + PSS1 と agc-PI)、平衡点とずらした点(`rng(1)`)。網の `rm_*`、Kron(状態 150 以下はモデル、すべて固有値)、DAE(`theta&rho`)、機器(LC 付き V2I と I2V、機器単体)、母線(V2I と I2V)、LC、GC のモデル。基準のコミットは `de2a93f5`。
- 比べるのは `DebugScript.helper.linearization_reference_check` で、名前の変化(機器と LC の電圧の入力、GC の入出力)は対応表で吸収します。F7 の "Linear models match the reference values"(5 系統、medium)と "Linear models of every bundled network match the reference values"(全系統、large)です。

### 11.3 結果 [計測]

- 基準値との一致: 298 項目すべてで相対差の最大は 1.14e-14 です。
- 基準 `de2a93f5` の small: 517 件、PASS 515 / KNOWN 1 / FAIL 0 / SKIP 1。large の F7・F8 では 3 件(F7 `PointFromASimulationResultAndATime`、F8 `MATFileRoundTripKeepsControllersAndLowerLayers`、`MATPOWERImportReproducesCase14`)が失敗し、実装後も同じメッセージで失敗します。
- 実装後(`7c4c9702`)の small: 520 件、PASS 518 / KNOWN 1 / FAIL 0 / SKIP 1、436 s。medium: 689 件、PASS 687 / KNOWN 1 / FAIL 0 / SKIP 1、694 s。large は未実行。
- Kron と DAE の固有値の一致、v3 の行列との一致(F7)、シミュレーションの Jacobian との一致(F35)は以前と同じく通ります。
- ユーザーの設定ファイルに `Method="Feedback"` が保存されていると、`GUILDA.config` は既定値に変えて読みます(`Auto-change @Method (Feedback >> Kron)`)。

### 11.4 未確認

- チュートリアル(`_GUILDAtutorial/*.mlx`)は書き換えていません。`Step6_GetLinearSystem.mlx` は v2 の `get_sys(false)` を説明しています(チュートリアルの更新は保留中のブランチで扱う)。


## 12. フォローアップ: 点の引数、制御器の変数表、`Equilibrium` 列、V2I の固定(2026-11-13)

同じ話題なので、ブランチ `refactor/121-linearization-connector` を `refactor/design-alignment`(`d77ac229`)まで早送りして続けました。

### 12.1 決定(ユーザー、2026-11-13)

1. 点は `Point` オプションではなく、最初の位置引数にします: `get_sys(obj, point, opt)`、既定 `point = []`。
2. 点の並びは、どのクラスでも `obj.get_variable_map()` の先頭の変数の行です(x, Vre, Vim、続いて u。制御器は uc)。
3. どのクラスにも `get_variable_map` を持たせます(制御器に追加)。
4. 変数表に `Equilibrium` 列を加えます。
5. ポートは V2I に固定します(`Port` オプションと電流を入力とするポートを削除)。
6. `get_sys` まわりの v3 の互換をすべて削除します。

### 12.2 実装 [事実]

- **v3 の互換の削除:** `get_sys` の位置引数 `x, V, u`(COMPAT(v3))、`_VersionSupport/v3_get_sys_point.m`、`_VersionSupport/v3_linearizer_constructor.m` とそれぞれの XML、`Deprecated.xml` の `GetSysPositionalPoint`、`PowerSystemModel.xml` の `PointAndPositional` を削除しました。`SolverLIN(arg)` は MATLAB の引数の数のエラー(`MATLAB:TooManyInputs`)です。COMPAT(v3) のフックは 9 行から 4 行になりました(F10 と `notes/v4-migration.md` の 4 章を更新)。
- **点の引数:** `get_sys(obj, point, opt)` の `point` は `[]`、数値ベクトル、`{sim, t}`、`{sim, t, Side}` で、意味は以前の `Point` と同じです。`ResultLIN.options.Point` には与えた点をそのまま記録します(フィールド名は変えていません)。`SolverLIN.check_point(point)`、`SolverLIN.point_vector(layer, point)` の引数名と、`SolverLIN.xml` の `Point*` のメッセージを「点(get_sys の最初の引数)」の言い方にしました(ID は同じ)。
- **制御器の変数表:** `@LocalController/get_variable_map.m` と `@GlobalController/get_variable_map.m` を加えました(許可された新しいメソッド。クラス定義に署名を追加)。行は自分の x、Vre/Vim(LC はその機器の母線、GC は全母線)、uc(GC は制御対象ごと)、yc で、列と Label は親(機器またはネットワーク)の表と同じです。`Bus` 列は LC では機器の母線、GC では x・uc・yc が `""`、電圧の行はその母線です。
- **`SolverLIN.point_vector`** はどの層も `layer.get_variable_map()` を 1 回読み、先頭の変数の行の `Equilibrium`(平衡点)、`Label`(`PointNotFinite` の名前)、`{sim, t}` の `tab_map` に使います。制御器のラベルを自分で組み立てる `controller_point`、平衡点を組み立てる `assemble` などの局所関数は削除しました。`get_sys` の `layer_maps` も制御器では自分の表を使い、親の表から行を選ぶ局所関数 `controller_map` を削除しました。制御器の `get_linear_port` も自分の表を読みます。
- **`Equilibrium` 列:** `PowerNetwork`、`Bus`、`Component`、2 つの制御器の `get_variable_map` の最初の出力(表の形)の最後の列です。値は x・u・uc が保存された平衡値(`rv_Xequilibrium`、`rv_Uequilibrium`)、Vre・Vim が `c_Vequilibrium`、y・yc が平衡点で出力関数(`f_Y`)を評価した値です。`Component` は自分と LC の値を直接求め、`Bus` は機器の表と母線電圧から、`PowerNetwork` は母線電圧、機器の表(母線の `"rows"` の第 2 出力で位置を求める)、GC の表から組み立てます。次のときは列全体が NaN です。
  - ネットワークがない、ネットワークの `sct_stale.powerflow` に `s_notInitialized` がある(初期化前)
  - 層のどれかのオブジェクトの `sct_stale.equilibrium` に `s_notInitialized` がある(加えた後に初期化していない)
  - 保存された平衡値の長さが `sv_x`、`sv_u` と合わない(`validate` が報告する壊れたモデル。表を作れるように NaN にします)
- **`"rows"` 形式は変えていません。** `Equilibrium` は表の形だけで計算します。表の先頭の行を持つ `ResultLIN.tab_variable` と `ResultODE.tab_variable`(`simulate` は表の形を読む)にも `Equilibrium` 列が入ります。
- **V2I の固定:** `get_sys` の `Port` オプション、`PortNotApplicable`、`NoI2V`、`l_port` の処理、6 つの `get_linear_port` の `s_port` 引数、`SolverLIN.solve` の外部電流の項、`ResultLIN` の I2V の分岐、`get_ss` の局所関数 `port_model`(代数変数の消去。V2I の層には代数変数がない)を削除しました。
- **テスト:** F7 の I2V の節を「Bus models with a zero D」(D が 0 の母線も V2I のモデルを返す)にし、v3 の位置引数の節を削除し、節「Variable maps of the controllers and the Equilibrium column」(medium)を加えました。`test_levels.m` の名前を合わせました。`+helper/linearize_v3.m` は Kron と DAE の比較に使うので残し、`v3_ports` の I2V の分岐と引数だけを削除しました。`+helper/linearization_reference_check.m` から I2V の比較を削除しました。
- **`linearization_reference.mat` は作り直していません。** I2V の項目は使わずに残します(作り方の `archive/make_linearization_reference.m` は置き換える前のコードでしか動かないため)。

### 12.3 選んだ点 [事実]

- **制御器の `get_variable_map` の出力は表 1 つだけです。** 接続表は返しません。制御器の入力の源(機器の y・x、親の制御器、GC の出力先)は制御器の表の行ではないので、`SourceIndex` が 0 になり意味を持たないためです。接続は親の表(`comp.get_variable_map()`、`net.get_variable_map()`)にあります。`get_sys` は制御器では空の接続表を使います(以前と同じ)。
- **新しい局所関数:** `@Component/get_variable_map.m` の `equilibrium`(平衡値の列)と `output_value`(LC の出力の評価)、2 つの制御器の `get_variable_map.m` の `tag`(Label を付ける)です。`@SolverLIN/point_vector.m` の `class_name` は以前からあり、制御器の場合を加えました。
- **表の形の速さ [計測]:** IEEE68bus の `net.get_variable_map()` は 31 ms から 60 ms になりました(`"rows"` は 14〜17 ms で変わらない)。初めの実装(母線の表を経由)では 127 ms だったので、ネットワークが機器の表を直接読むようにしました。`net.get_sys()` は 352 ms から 297 ms です(`point_vector` が平衡点を組み立てなくなったため)。`simulate` は内部で表の形を 1 回読むので(`simulateFcn_blocks`)、その分だけ遅くなります。

### 12.4 結果 [計測]

- small(最終): 526 件、PASS 524 / KNOWN 1 / FAIL 0 / SKIP 1、382 s。
- medium(1 回): 712 件、PASS 709 / KNOWN 1 / FAIL 1 / SKIP 1、859 s。失敗は F7 `VariableMapIsConsistentWithTheLinearModel` で、表の列名に `Equilibrium` がないことを確かめていたためです。テストを直し、F7 の medium を実行し直して 45 件すべて PASS です。large は実行していません。
- 基準値との一致: F7 の "Linear models match the reference values"(5 系統、網の `rm_*`・Kron・DAE、機器と母線の V2I、機器単体、LC、GC)は PASS です。
- `test_levels.m` の `LayerGet_sys_RemovedArguments_OneSignatureAndSingleComputation__83___121_` は実際の名前(`__83__121_`)と違い、この large のテストが small で実行されていました(以前からの警告)。名前を直したので、small の件数が 1 件減りました。
- `git grep` で `Point=`、`Port=`、`I2V`、`v3_get_sys_point`、`v3_linearizer_constructor` が残るのは、`+DebugScript/archive/`、この文書の §2〜§11、ほかの過去の調査の notes だけです(`InitialPoint=` は OPF の別のオプション)。



## 13. `Type`(`"ODE"`/`"DAE"`)、`SolverLIN.reduce`、DAE を持つ `ResultLIN`、要素の寄与(2026-11-13)

ブランチは `feature/linearization-type-contribution`(未 push、分岐元 `06656d9d`)です。指示のブランチ名 `feat/...` は git-workflow の型(`feature|fix|refactor|docs|test`)のフックで拒否されたので、`feature/` にしました。§2〜§12 の `Method`、`"Kron"` の記述は、当時の記録としてそのまま残します。

### 13.1 決定(ユーザー、2026-11-13)

1. `get_sys` の `Method="Kron"|"DAE"` を `Type="ODE"|"DAE"` にします。既定は GUILDA.setting の `"ODE"` です。`"DAE"` は母線電圧を消去する前の接続したモデル、`"ODE"` は消去したモデルです。`Format` と `Coordinate` の意味は変えません。
2. DAE から ODE への消去を `SolverLIN` の Static メソッドにします。`SolverLIN.solve` は接続した DAE だけを返します。
3. `ResultLIN` は DAE を持ち、`A`〜`OutputName` は設定できる `Type` に従う Dependent プロパティにします。`rm_*` は変えません。`get_ss` の最初の引数は `Type` です。
4. `ResultLIN.get_contribution(target)` で、要素ごとの DAE への寄与を返します(研究に重要)。

### 13.2 実装 [事実]

- **`Type`:** `get_sys`、`get_ss`、`plot_eigenvalue` の `Method` を `Type` にし、`DefaultLinearization.json` の項目も `Type`(`"ODE"`、`"DAE"`)にしました。`"Kron"` と `Method` を使っていた呼び出し、テスト、`Tutorial10bus` のヘルプ、`Task_linearization`、開発者ページ(`feature-linearization.html`、`api-design.html`、`class-design.html`)、`v4-migration.md`、`status.md` を書き換えました。`_GUILDAverification` には該当がありません。`api-design.html` のオプション名の表には `Type`(同じ解析から返すモデルの種類)の行を加え、`Method` の例から `"Kron"` を除きました。
- **`SolverLIN.reduce(sct_dae, iv_algebraic)`(Static):** DAE の構造体(`A`〜`E` と名前)から代数変数を消去します。`iv_algebraic` の既定は `E` の行と列がともに 0 の変数です。`ResultLIN.get_ss` は母線電圧の位置を明示して渡します(AVR の時定数が 0 のときなど、機器の `E` が特異な状態は消去しないため。以前の Kron と同じ)。`A_aa` の `rcond` が `1e-14` 未満なら、定まらない代数変数を挙げて `GUILDA:SolverLIN:SingularAvv` で止まります(新しい ID)。
- **`get_ss("ODE")`:** `"Vre&Vim"` の DAE(`Output`、`Input` を適用したもの)を `SolverLIN.reduce` で消去します。`Output` がなければ、以前と同じく出力は名前のない状態です。`via_kron` は削除しました。ネットワークの `"SingularAvv"` では、これまでどおり `get_ss` が `output.message` を繰り返す `GUILDA:ResultLIN:SingularAvv` で先に止まります。`get_sys` の `"struct"`、`"ss"` は `result.get_ss(Type, ...)` を通して `reduce` を使います。
- **`ResultLIN`:** `Type`(設定できる、既定は `options.Type`)を加え、`A`〜`OutputName` を Dependent にしました。初めて読んだとき `get_ss(Type)`(`options.Input`、`options.Output`)を求め、private の hidden プロパティ `sct_cache` に `Type` ごとに保持します。`get_ss` と `plot_eigenvalue` の `Type` の既定は `res.Type` です。
- **寄与の項(`SolverLIN.solve`):** `sct_sys.sct_term` に、行列ごとの非零の項を `[Row, Column, Owner, Value]` の行で返します(`sv_owner` が所有者の一覧。`Y` は電流の出力 `Y v` 用に v だけの部分)。所有者は、状態の行がその状態のブロック(ブロックの新しいフィールド `s_tag`)、母線の電流の釣り合いの行が各機器(自分の電流の項)と各アドミタンスの部分(`sct_port.tab_stamp` の送電線の 2×2 と母線のシャント)、出力の行が出力の所有者(電圧は母線、`Y v` は Y の部分、電流の和は各機器)です。各行列の項の和はその行列です。
- **`get_sys`:** ネットワークで `sct_port.tab_stamp`(`Owner`、`Bus`、`Y`)を作り(`get_admittance_matrix` と同じ和)、`solve` の後に `sct_sys.tab_owner`(層の要素のタグとクラス。ネットワークは母線と送電線も)を加えます。ソルバーはネットワークを読みません。
- **`ResultLIN.get_contribution(target)`:** `target` をタグ、クラス名(子クラスを含む)、パッケージ名で所有者に変え、その項から同じ大きさの接続したモデルを作り、`ResultLIN` のコンストラクタで一時的な結果にして `get_ss("DAE")` と同じ経路で DAE にします。状態と母線電圧の出力(`get_ss` が単位行列の行で書く)は所有者で選びます。`sct_mask` は `"Vre&Vim"` での寄与の非零の要素で、極座標では各母線の 2 つの変数をまとめて印を付けます。当たらない対象は `GUILDA:ResultLIN:UnknownTarget`(新しい ID)です。
- **局所関数:** `reduce.m` の `algebraic_rows`、`undetermined`、`list_names`。`solve.m` の `stamps`、`add_term`、`term_table`。`get_sys.m` の `admittance_stamps`、`owner_table`。`ResultLIN.m` の `fill_cache`。`get_contribution.m` の `owners`、`gather_terms`、`pair`。

### 13.3 選んだ点 [事実]

- **縮約の名前は `reduce` です。** 命名のページの動詞+目的語の規則では `reduce_dae` も考えられますが、`SolverLIN.reduce` はクラス名が目的語(線形モデル)を示すので短くしました。
- **ODE の出力名は以前と同じく空です。** `reduce` は DAE の出力名(状態の名前)を残しますが、`get_ss("ODE")` の既定の出力は v3 からの「名前のない状態」のまま(F7 "Default channels of get_sys do not change")にしました。名前を付けるかは別の判断です。
- **キャッシュを加えました。** IEEE68bus(AVR・PSS 付き、状態 144)で `get_ss("ODE")` は 1 回 約 6 ms で、8 つのプロパティを毎回計算すると 1 回の読み出しの組で約 50 ms になるためです。キャッシュからの読み出しは 16 回で 1.6 ms でした [計測]。結果のデータは変わらないので、無効化は要りません。
- **ブランチ名:** 13 章の冒頭のとおり `feature/` です。
- **`+helper/linearize_v3.m` の `"Kron"` は残しました。** v3 のコードの写しなので、F7 の比較では `"ODE"` を `"Kron"` に読み替えて渡します。`+branch/@T/get_admittance_matrix.m` の "Kron reduction" は T 形回路の中間節点の消去(数学の用語)なので変えていません。
- **保存された設定:** ユーザーの設定ファイルにある Linearization の `Method` は、`GUILDA.config` が未知の項目として捨てて読みます(`Remove unknown environment field 'Method'.`)。

### 13.4 結果 [計測]

- small(手順ごと): 手順 1+2 の後 529 件、PASS 526 / KNOWN 1 / FAIL 1 / SKIP 1(`get_sys("Typ", ...)` が `Type` の前方一致で通るので、テストを `"Typo"` に直して PASS)。手順 3 の後と手順 4 の後 531 件、PASS 529 / KNOWN 1 / FAIL 0 / SKIP 1。
- medium(1 回): 718 件、PASS 714 / KNOWN 1 / FAIL 2 / SKIP 1、583 s。2 件(F7 `BusModelsWithAZeroD`、`LinearModelsMatchTheReferenceValues`)は、ブロックのない層(機器のない母線)で `solve` の所有者の `repelem` が止まったためです。直した後の small は 531 件、PASS 529 / KNOWN 1 / FAIL 0 / SKIP 1、F7 の medium は 50 件すべて PASS です。large は実行していません(F7 の large を手順 3 で 1 回実行し、`linearize_v3` の名前の読み替えを直しました)。
- 基準値との一致: F7 "Linear models match the reference values"(`"ODE"` は以前の Kron、`"DAE"`)は PASS(許容 1e-9)です。
- 寄与の和: すべての要素の寄与の和と DAE の相対差の最大は、IEEE14bus(AVR・PSS・AGC 付き、54 要素)で 1.3e-17、IEEE68bus(235 要素)で 5.0e-17 です。1 要素あたり 7〜9 ms です。
- テスト(F7): "Type switches the model of the result"、"Reduce eliminates the algebraic variables of a DAE"(small)、"Contributions by tag, by class and by several targets"、"Contributions of all elements sum to the DAE"、"... of IEEE68"(medium)を加えました。

## 14. `get_linear_port` の廃止(2026-11-13)

### 14.1 決定(ユーザー、2026-11-13)

- `get_linear_port` はメソッドとして要りません。中身のほとんどは変数マップから導け、呼ぶのは `get_sys` だけで、`get_sys` はすでに `tab_current` と `tab_stamp` を自分で `sct_port` に加えていました。
- 固有の中身は、層ごとのポートの規則(ネットワーク: V が代数変数で u が入力。機器・母線: V が入力で I が出力。制御器: V と uc が入力で yc が出力)、電流の Label `Ire`/`Iim`(`attach_tag`。変数マップにない)、ネットワークのアドミタンス行列だけです。
- これらは `get_variable_map` に入れません。変数マップは `simulate`/`ResultODE` と共有で、Y は変数ではなくネットワークのデータだからです。

### 14.2 実装 [事実]

- 6 つの `get_linear_port.m`(`@PowerNetwork`、`@Bus`、`@Component`、`@LocalController`、`@GlobalController`、`_auxiliary/@PowerSystemModel`)と classdef の宣言を削除しました。空になった `methods (Access=protected)` の区画(`Component`、`LocalController`、`PowerSystemModel`)も除きました。XML ヘルプと `functionSignatures.json` には項目がありませんでした。
- `get_sys.m` の局所関数 `port(obj, tab, a_obj)` が、`layer_maps` が読んだ変数マップから `sct_port` 全体(`sv_input`、`sv_output`、`sv_algebraic`、`cm_Y`、`tab_bus`、`tab_current`、ネットワークでは `tab_stamp`)を作ります。`get_variable_map` は 1 回だけ呼びます。規則とフィールドは以前と同じで、`SolverLIN.solve` の署名は変えていません。
- `layer_maps` の対象外の層(`Branch` など)は、クラスの判定で `GUILDA:PowerSystemModel:NoLinearModel` を出します。
- `get_variable_map` は変えていません。新しい局所関数は `port` だけです。

### 14.3 結果 [計測]

- small: 554 件、PASS 551 / KNOWN 1 / FAIL 1 / SKIP 1。medium(1 回): 745 件、PASS 742 / KNOWN 1 / FAIL 1 / SKIP 1、1239 s。FAIL は両方とも F34 `functionSignatures_jsonMatchesTheArgumentsBlocks` で、マージ済みの `Branch` の `Circuit` 引数が `functionSignatures.json` にないためです(この変更とは無関係。`GUILDA.update_keymap(Signature=true)` で 1 行加わることを確認し、ここでは戻しました)。large は実行していません。
- F7 "Linear models match the reference values" と、寄与の和のテスト(IEEE14、IEEE68)は PASS です。
- IEEE68bus の `net.get_sys()`(10 回の中央値): 変更前 0.355 s、変更後 0.254 s。機器 1 つの `get_sys()`: 0.0157 s → 0.0131 s。別々の MATLAB セッションでの計測なので、差には負荷の揺れを含みます。少なくとも遅くはなっていません。
