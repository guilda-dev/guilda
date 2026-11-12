# `PowerNetwork.get_sys` の数値計算と内部構造 (現状調査)

> 当時の調査記録です。調査の基準は `951800e` で、以後の変更は本文に反映していません。現状は [status.md](status.md) と [v4-migration.md](v4-migration.md) を見てください。

対象は `docs/get-sys-linearization` の分岐元 `951800e` のコードです。改善案は書いていません (後続の作業の担当)。
全体のワークフロー、データ所有、編集の扱い、引数は `notes/get-sys-workflow.md` を参照してください。

**ラベル**: 無印または [事実] = コードを読んで確認。[計測] = MATLAB R2026a で実行して確認。[推測] = 根拠からの推論で、直接は確認していない。[未確認] = 調べていない、または再現できなかった。

パスは次のように省略します。`S/` = `_GUILDAsystem/`、`LR/` = `S/_auxiliary/@LinearizationResult/`、`OL/` = `S/_auxiliary/@odeLinearizer/`。

## 0. 要点

1. **3 方式の固有値は一致します** [計測]。全テンプレートで最大差は 3.2e-10 (IEEE68)、F7 の許容値 1e-6 を十分下回ります。F7 は 31/31 件合格。線形モデルと非線形 `simulate` の誤差は外乱の 2 乗で減り、線形化は正しいと言えます (§5.4)。
2. **一致するのは固有値までで、モデルの形は方式で異なります** [計測]。IEEE68 では Kron の状態が 144、Feedback が 128、DAE が 280 です。Feedback は `connect` が AVR の代数状態 `Vst` を消すため状態名から消え、グローバル制御器の状態は出力に入りません。P=Q=0 の負荷の入力も、B が 0 でないのに Feedback から消えます。
3. **`NonUnit` は Feedback だけに効き、機器を落とします** [計測]。実際に負荷がある母線を指定すると固有値が変わり、IEEE14 の `NonUnit=[7 9]` では最大実部が +1.09 になります。警告はありません。F7 は P=Q=0 の B007 でしか確認していません。
4. **`flag` は数値的な失敗を表しません** [計測]。`Avv` が完全に特異 (`rcond=0`) でも `flag=true` で、Kron と Feedback は `dss` の分かりにくいエラーで止まります。
5. **疎性は保持されません** [事実・計測]。すべて密行列です。IEEE68 のブロック密度は 0.2〜4.8 % です。ただし現在の規模で支配的なのは行列演算ではなく `table` 操作で、`get_variable_map` 系が `linearize` の約 65 % を占めます。

## 1. 計算の流れ

### 1.1 呼び出しの連鎖

| 段階 | 場所 | 入力 → 出力 |
|---|---|---|
| 1 | `S/@PowerNetwork/get_sys.m:31-33` | `linearize` の後に `result.get_ss(result.options.Algorithm)`。`output.result` に結果を入れる |
| 2 | `S/@PowerNetwork/linearize.m:41-44` | `Plot` を分離し、`solver_LIN.get_options` で設定を解決して `solve` を呼ぶ |
| 3 | `OL/solve.m:22` | `require_equilibrium`: 古い `f_*` を作り直し、平衡点が古ければエラー |
| 4 | `OL/solve.m:33-34` | 変数表 `tab_map` と点 `rv_point` を取得 |
| 5 | `OL/solve.m:41-50` | 各母線の `Bus.get_sys("port","V2I")` を求め、出力を `[I]`、入力を `[V; 機器の u]` に絞る (制御器の入出力を捨てる) |
| 6 | `OL/solve.m:51-59` | グローバル制御器の `get_sys` |
| 7 | `OL/solve.m:61-62` | `Y` と `cv_V` |
| 8 | `OL/solve.m:67-78` | ブロックを `blkdiag` で連結し、グローバル制御器を閉じる |
| 9 | `OL/solve.m:85-94` | `sct_block` (DAE) と `sct_model` (Feedback 用) を作る |
| 10 | `OL/solve.m:96-110` | `flag` は全ブロックが有限かどうかだけ。`rcond_Avv` は記録するだけで判定しない |
| 11 | `LR/get_ss.m:36-43` | Kron / Feedback / DAE へ変換 |

### 1.2 階層内の組み立て

- **制御器** (`S/@LocalController/get_sys.m:35-58`): `E ẋc = Axx xc + [Bxv Bxu][V; u]`、`y = Cyx xc + [Dyv Dyu][V; u]`。
- **機器** (`S/@Component/get_sys.m`): まず `rec=false` で機器単体を作り、`:125-130` で `f_Mass` と `f_Jacobi*` を評価します。`connect_states` (`:231-253`) で制御器が読む状態を `X__<名前>` の追加出力にし、`append` と名前の対応 (`connectCondition`) から `connect(...,"Simplify",false)` します (`:78-85`)。
- **母線** (`S/@Bus/get_sys.m:47-97`): 機器を並べ、電流を足します。`Dv_sum` (`:69`)。機器がなければ状態なし、`D=0` の系を作ります (`:40-44`)。

母線 i の V2I モデルは次の形です。

```
E_i dx_i/dt = A_i x_i + Bv_i V_i + Bu_i u_i
I_i         = C_i x_i + Dv_i V_i + Du_i u_i
```

### 1.3 非縮約 DAE (`LinearizationResult` が保持する形)

連結後の式は `OL/solve.m:64-66, 86-89`、`LR/LinearizationResult.m:6-9` にあります。

```
rm_E dx/dt = Axx x + Axv v + Bx u
         0 = Avx x + Avv v + Bv u

Avx = -Cix,  Avv = Y_real - Div,  Bv = -Diu
v = [Vre1; Vim1; Vre2; ...]   (母線ごとに交互)
```

`Y_real` は各要素 `a+jb` を `[a -b; b a]` にした実数表現です (`S/+tools/complex2matrix.m`)。
寸法は `n_x` × `n_x`、`n_v = 2 n_bus`、`n_u` = 全機器の入力数です。**ローカル制御器の入力は含みません** (`OL/solve.m:36-39`)。

**グローバル制御器** (`OL/solve.m:131-187`): 制御器 k を `E_k ż_k = A_k z_k + B_k w_k`、`y_k = C_k z_k + D_k w_k` とし、`w_k = S_k x` (名前で状態へ対応)、`u ← u + T_k y_k` とします。

```
Axx' = [Axx + Bxu Dux,  Bxu Cuz;  Bzx,  Az]
Cix' = [Cix + Diu Dux,  Diu Cuz]
Dux = Σ T_k D_k S_k,  Cuz = [T_k C_k],  Bzx = [B_k S_k]
```

### 1.4 Kron (`LR/get_ss.m:65-90`)

`v = -Avv⁻¹(Avx x + Bv u)` を代入します。

```
A = Axx - Axv Avv⁻¹ Avx
B = Bx  - Axv Avv⁻¹ Bv
C = I,  D = 0,  E = rm_E
```

コードは符号を反転した `Dv=-Avv`、`Cx=-Avx`、`Du=-Bv` で同じ式を計算しています (`:71-82`)。状態順は `legacy_order` によりグローバル制御器が先頭です (`:54-62`)。

### 1.5 DAE (`LR/get_ss.m:93-165`)

状態は `[x; 母線変数1...n; 母線変数1...n]` で、**母線ごとの交互ではなく**ブロック順に並び替えます (`:111-112`)。代数方程式の行を `[-Iim 式; Ire 式]` にします (`:121-126`)。次に左右から座標変換を掛けます (`:152-156`)。

| `Coordinate` | 列 (`filt_i`) | 行 (`filt_o`) の意味 [推測] |
|---|---|---|
| `theta&rho` (既定) | `δVre=-Vi θ+Vr ρ`, `δVim=Vr θ+Vi ρ` | P, Q の収支 |
| `theta&V` | `δVre=-Vi θ+(Vr/|V|) δ|V|` など | P, Q/|V| |
| `Vre&Vim` | 恒等 | `-Iim`, `Ire` の収支 |

`A = F_o A₀ F_i`、`B = F_o B₀`、`C = [I 0]`、`D = 0`、`E = blkdiag(rm_E, 0)` です。
`Coordinate` は `get_ss` の引数のみで、`net.get_sys(Coordinate=...)` は `GUILDA:resolve_options:UnknownName` になります [計測]。

### 1.6 Feedback (`LR/get_ss.m:168-218`)

1. **非 unit 判定** (`:174-177`): `lv_nonUnit` (`NonUnit` で指定、または機器なし) か、`has_I2V` が偽の母線を除きます。`has_I2V` は「状態がある、または `rcond(D) > 1e-12`」です (`:220-222`)。
2. **I2V 変換** (`:224-251`): `V = Dv⁻¹(I - C x - Du u)` を使います。

   ```
   A' = A - Bv Dv⁻¹ C,   B' = [Bv Dv⁻¹,  Bu - Bv Dv⁻¹ Du]
   出力 = [x; V]
   ```
3. **網の Kron 縮約** (`:213-217`): `Y_red = Y_uu - Y_un Y_nn⁻¹ Y_nu`。`I = Y_red V` を `ssN` にします。**非 unit 母線の機器の電流は `Y` に戻さず捨てます。**
4. **結線** (`:196`): `connect(ssG, ssN, 外部入力, 外部出力)`。`Simplify` は既定のままです。
5. **グローバル制御器** (`:200-210`): `feedback(sysODE, sysGC, feedin, feedout, +1)` を順に閉じます。

### 1.7 3 方式の関係

- 全母線が unit なら、Feedback は「各母線を反転して `Y` で閉じる」形で、Kron と同じ `Avv` の消去を別経路で行います。名前で対応させた A の相対差は 1e-17 程度、B は 1e-14 以下です [計測]。
- 非 unit 母線の電流が平衡点で 0 であれば固有値は変わりません。電流が流れている母線では別のモデルになります (§5.5)。
- DAE は消去しないので、`v` を残した同じ方程式です。F7 は DAE と Kron の伝達関数の一致を確認しています (`+DebugScript/test_F7_linearization.m:318-327`)。

### 1.8 ローカル制御器・グローバル制御器・retrofit・その他

- **ローカル制御器**: 母線モデルの中に閉じています。`local_LQR` は `Xall` を読み、状態はありません。ゲイン設計では `comp.get_sys(..., "con",false,"rec",false)` を使います (`_GUILDAobject/+controller/local_LQR.m:138`)。
- **`Point`**: `OL/point_vector.m` が値を作り、機器は `point_values` で `I` と制御器入力を算出します (`S/@Component/private/point_values.m`)。**固定項 `f(point)` は保持しません。** 結果にも出力にも載りません [事実・計測]。δ を 0.3 ずらした点で機器 1 の `|f|` は 2.1 ですが、線形モデルからは落ちます。
- **retrofit**: `controller.local_LQR_retrofit` は抽象クラス扱いで作れません (`MATLAB:class:abstract`) [計測]。v2 のインターフェース (`net.a_bus`, `get_sys4retrofit`) を使っており (`_GUILDAobject/+controller/local_LQR_retrofit.m:10-12, 65`)、`get_environment` も同様です (`_GUILDAobject/+controller/+modeling/get_environment.m:25-50`)。**現在の `get_sys` の経路には入りません。**
- **`Plot`**: `options.Algorithm` を見ず、既定で常に Kron を描きます (`LR/Plot.m:10`)。`linearize(Algorithm="Feedback", NonUnit=[7 9])` でも題名は `Eigenvalues (Kron)` でした [計測]。

## 2. Jacobian の求め方

| 対象 | 方法 | 根拠 |
|---|---|---|
| `Component` | `Jacobi_dx/I/Y` があれば解析的、なければ中心差分。3 つ別々に判定 | `S/@Component/Component.m:173-189` |
| `LocalController`, `GlobalController` | 解析的のみ。**フォールバックなし** (抽象メソッド) | `S/@LocalController/LocalController.m:53-57, 245-246`、`S/@GlobalController/GlobalController.m:167-168` |
| 記号微分 | 線形化の経路では使っていない | `Component`, `LocalController`, `GlobalController` の `get_sys` と `set_odefcn` を確認。全リポジトリの調査はしていない |

**出荷モデル** [事実]: 発電機 5 種 (`classical`, `one_axis`, `two_axis`, `park`, `droop`)、負荷 2 種 (`impedance`, `power`)、`AVR_ST1`, `AVR_DC1`, `PSS1`, `local_LQR`, `broadcast_PI_AGC` は解析的です。数値フォールバックを使うのは利用者定義クラスと未完成の `未+GFM`, `未+farm` です (`Jacobi_` の記述なしを grep で確認。これらの動作は [未確認])。

**フォールバック** (`S/@Component/private/Jacobi_{dx,I,Y}_num.m`):

- 刻み `d=1e-5` の中心差分で、状態のスケールによらず固定です。
- `x, V, I, u` の全列を毎回評価します。`fcn` を 1 ブロックあたり `2(nx+4+nu)` 回呼びます。
- `I` は複素スカラーが前提です (`Component.m` の `fcn_I` の規約)。

**精度** [計測]:

| 比較 | 結果 |
|---|---|
| 解析解と差分 (`h=1e-5`、平衡点、機器 7 種) | 最大 9.7e-11 |
| 解析解と差分 (`jacobian_error`, `h=1e-6`、ずらした点) | 機器 最大 9.7e-10、`AVR_ST1` 2.5e-9、`PSS1` 1.1e-11、AGC 2.8e-10 |
| スタブの実際のフォールバックと閉形式 (x=0〜1) | 1e-12〜7e-11 |
| 同 (x=10, `Cyx`≈300) | 9.6e-9 (相対 3e-11) |
| 線形な式でのフォールバック (`stubcs`) | `-0.999999999995` (1 との差 4.6e-12) |

差分誤差が丸めで 1e-11 ほど乗ることと、`E` や `A` が厳密な 0 にならない場合があることに注意してください。

**`I` 依存の判定**: `any([Bxi; Dii; Dyi] ~= 0)` は完全一致の比較です (`S/@Component/get_sys.m:137`)。`I` を使わないスタブでは差分がちょうど 0 になり誤検出はありませんでした。`dx` が `I` に依存するスタブは `GUILDA:Component:get_sys:CurrentDependence` で止まりました [計測]。`I` への依存が丸め誤差でのみ現れる場合は [未確認]。

## 3. 名前と順序

### 3.1 変数表

`net.get_variable_map()` の順は `x` (母線順、機器→制御器の深さ優先、最後にグローバル制御器) → `Vre, Vim` (母線ごとに交互) → `u` (機器の入力のみ) です (`S/@PowerNetwork/get_variable_map.m:7-12`)。`rm_*` と `Point` はこの順です。

ただし `get_ss` は別の順を返します。

| | 状態順 | 根拠 |
|---|---|---|
| 変数表 / `rm_*` | 機器 → グローバル制御器 | `get_variable_map.m:59` |
| Kron, DAE | **グローバル制御器** → 機器 | `LR/get_ss.m:54-62` |
| Feedback | 機器 → グローバル制御器 | `:209`、F7 `:106-114` |

`class-design.html:278` の「Do not define another order」と、v3 互換のこの順は食い違っています。`get_ss` の help には明記されています (`LR/get_ss.m:6-8`)。

### 3.2 ラベル

`attach_tag` で親のタグを連ねます [計測]。

```
omega_SG1B001_B001_PowerNetwork
Vfield_CAavr1_SG1B001_B001_PowerNetwork
xi_agc_PowerNetwork
```

**末尾はネットワークのタグです。** help の例 `Y_omega_SG1B001_B001` (`S/@Component/get_sys.m:14`) は末尾がありません。

### 3.3 `Y_` と `Xall` / `Yall`

- `Y_<名前>`: 持ち主の状態と同名の出力に付けます (`S/@Component/get_sys.m:271-276`, `S/@LocalController/get_sys.m:43-46`)。**`tag=false` では付きません** (`:46`)。内部の結線は無印の名前を使うためです。
- `Xall` / `Yall`: 接続時に `sv_x` / `sv_y` へ展開します (`S/@LocalController/LocalController.m:178-199`)。同名なら出力を優先します (`:195-196`)。`Xall` を `local_LQR` が使います。
- LQR の入力ラベルは `delta_CLl1_SG1B001_B001_PowerNetwork` のように展開されます [計測]。`comp.get_sys` の外部入力にも残り、観測信号に足す入力として扱われます (`S/@Component/get_sys.m:15-18`)。
- **`net.get_sys` に `Y_` は現れません。** 出力が状態ラベルそのものだからです。

### 3.4 入出力の選び方

**`net.get_sys` にサブセットの指定オプションはありません。** 全体を作ってから添字で切り出します [計測]。

| 操作 | Kron | Feedback | DAE | comp | bus |
|---|---|---|---|---|---|
| `sys(:, "入力名")` | ○ | ○ | ○ | 下記 | ○ |
| `sys("出力名", "入力名")` | **× `OutputName` が空** | ○ | ○ | **× 曖昧エラー** | ○ |
| 先頭一致 (`omega_SG1B001_B001`) | 入力のみ | ○ | ○ | × | [未確認] |

- Kron は `C=I` なので `StateName` から行番号を引けます。
- 機器と制御器は `InputGroup` / `OutputGroup` をチャネルと同名で作るため、**完全な名前でも曖昧エラーになります** (§6-B2)。
- `net.get_sys` の出力は状態だけで、`V`, `I`, 機器の `y` は取り出せません。DAE でも `C=[I 0]` です (`LR/get_ss.m:113`)。必要なら `rm_*` を使います。

## 4. 階層の違い

IEEE14 の発電機 1 に AVR+PSS、AGC を付けた例です [計測]。

| | 入力 | 状態 | 出力 | 寸法 (in/x/out) | 点の与え方 |
|---|---|---|---|---|---|
| PSS | `Vre, Vim, omega` | PSS | `Vpss` | 3/3/1 | 位置引数 |
| AVR | `Vre, Vim, Vref, Vpss` | AVR | `Vfield` | 4/3/1 | 位置引数 |
| 機器 V2I | `V; umac; ucon` | 機器+制御器 | `I; Y_omega; Vfield; Vpss` | 7/12/5 | 位置引数, `Point` |
| 母線 V2I | `V; 各機器の u, ucon` | 同上 | `I; 各 y` | 7/12/5 | `Point` のみ |
| グローバル制御器 | 制御対象の `omega` | `xi` | 制御対象の `Pmech` | 2/1/2 | 位置引数 |
| 系統 Kron | 機器の `u` | 全状態 | 全状態 (**名前なし**) | 34/37/37 | `Point` |
| 系統 Feedback | 機器の `u` (P=Q=0 の負荷を除く) | `Vst` を除く全状態 | 機器の状態全部 (`xi` を含まず) | 32/36/36 | `Point` |
| 系統 DAE | 機器の `u` | 全状態+母線変数 | 全状態 | 34/65/37 | `Point` |

**同名同義の原則について**:

- 下 3 層は「`V → I` のポート付きモデル、状態は出力でない」で揃っています (`class-design.html:141`、F7 `:227-276`)。
- **`PowerNetwork` は揃っていません。** 同じ文に「On every layer ... states are never outputs」とありますが、系統の出力は状態です [事実・計測]。名前の一意性も崩れます。`StateName` と `OutputName` が同じです。`notes/v4-migration.md:30-31` は `net.get_sys` を変更なしとしており、v3 互換を意図したものと考えます [推測]。
- グローバル制御器は `opt.full` が未使用で (`GlobalController.m:128`)、`Point` もありません。
- 入力名 `omega_...` は機器の状態ラベルと同じで、`Y_omega_...` ではありません (`GlobalController.m:150`)。`class-design.html:202` は「グローバル制御器は出力 Y を読む」と書いていますが、線形化は**状態名で対応**させ (`OL/solve.m:160`)、`gc_input` も状態を読みます (`:123`)。名前が一致するので動いています。
- 戻り値も層で違います。系統だけ `[sys, flag, output]`、機器と制御器は `[sys, 名前...]`、母線は `sys` のみです。`LocalController` の `varargout` の入力名は `V` なしで出力名は状態込み (#in=2, #out=4 で `sys` の 4, 1 と不一致)、`Component` は `sys` と一致します [計測]。

**効かないオプション** [事実・計測]:

- `Bus` の `full`, `con`: 無視と明記 (`S/@Bus/get_sys.m:22-23`)。
- `Component` の `full`, `con`: `rec=true` では読みません (`S/@Component/get_sys.m:55`)。`con=false` でも A は同一、`full=true` でも出力数は同じでした。
- `LocalController` の `full`: 有効です。

## 5. 計測

**環境**: MATLAB 26.1.0 (R2026a)、`-batch`、macOS arm64。スタブ追加と `GUILDA` 起動 (`add_component.m` の生成) が必要なため、作業ツリー外のコピーで実行しました。コードは `951800e` と同一です。起動設定の `PrintLogo`, `CheckRequirement`, `Tutorial` のみ切っています。他の処理と並行した時間帯があるので、時間は目安です。`rcond` は `output.rcond_Avv`、「最大差」は固有値の最近傍距離の最大です。

### 5.1 寸法と疎性

| 系統 | n_bus | n_x | n_v | n_u | Kron A | Feedback A | DAE A | `rcond_Avv` | `cond` |
|---|---|---|---|---|---|---|---|---|---|
| Tutorial3bus | 3 | 12 | 6 | 6 | 12 | 12 | 18 | 1.2e-2 | 49 |
| Txt3Bus | 3 | 6 | 6 | 6 | 6 | 6 | 12 | 1.4e-2 | 38 |
| Ishizaki6Bus | 6 | 4 | 12 | 12 | 4 | 4 (入力 8) | 16 | 6.5e-3 | 92 |
| IEEE9bus | 9 | 27 | 18 | 12 | 27 | **24** | 45 | 3.1e-3 | 153 |
| IEEE14bus | 14 | 30 | 28 | 34 | 30 | 30 (入力 32) | 58 | 5.0e-3 | 88 |
| TEST31bus | 31 | 60 | 62 | 78 | 60 | 60 (入力 76) | 122 | 1.4e-4 | 4158 |
| IEEE68bus | 68 | 144 | 136 | 102 | 144 | **128** | 280 | 7.5e-4 | 798 |

**IEEE68 のブロック** (すべて `issparse=0`):

| ブロック | 寸法 | nnz | 密度 |
|---|---|---|---|
| `rm_Axx` | 144×144 | 400 | 1.9 % |
| `rm_Axv` | 144×136 | 95 | 0.5 % |
| `rm_Bx` | 144×102 | 32 | 0.2 % |
| `rm_Avx` | 136×144 | 64 | 0.3 % |
| `rm_Avv` | 136×136 | 884 | 4.8 % |
| `rm_Bv` | 136×102 | 140 | 1.0 % |
| `rm_E` | 144×144 | 112 | 0.5 % |

**疎性が失われる箇所** [事実]:

- `shape` の `full` (`S/@Component/get_sys.m:299`, `S/@LocalController/get_sys.m:81`)
- `get_admittance_matrix` の密な `table` (`S/@PowerNetwork/get_admittance_matrix.m:22`)
- `complex2matrix` の `zeros` (`S/+tools/complex2matrix.m:10`)
- `dss` / `ss`: Control System Toolbox の `ss` が疎行列をそのまま保持するかは試していません [未確認]

**結果の密度** [計測]: Kron A は IEEE68 で 9.0 %、IEEE14 で 70.6 %、TEST31 で 70.0 %。DAE A は IEEE68 で 1.9 %。IEEE68 の Kron B の nnz は 3392 で、Kron は本質的に密になります。DAE は疎を保てる形です。

### 5.2 段階ごとの時間 (中央値, ms)

IEEE68 は 3 回、他は 5 回の中央値です。

| 段階 | Txt3Bus | IEEE9 | IEEE14 | TEST31 | IEEE68 |
|---|---|---|---|---|---|
| `get_variable_map` | 8.8 | 22.8 | 35.4 | 88.8 | 152 |
| `point_vector` (表を再度作る) | 20.6 | 57.4 | 112 | 226 | 405 |
| 母線 `get_sys` 全部 | 15.4 | 78.9 | 72.9 | 88.2 | 228 |
| `get_admittance_matrix` | 5.1 | 11.7 | 18.0 | 32.1 | 63.4 |
| `complex2matrix` | 0.08 | 0.08 | 0.07 | 0.08 | 0.09 |
| `rcond` | 0.04 | 0.05 | 0.06 | 0.09 | 0.17 |
| **`linearize` 全体** | 58 | 155 | 203 | 455 | **861** |
| `get_ss("Kron")` | 2.0 | 14.4 | 25.2 | 18.3 | 14.2 |
| `get_ss("Feedback")` | 31.5 | 31.0 | 34.6 | 96.0 | 105 |
| `get_ss("DAE")` | 2.1 | 2.1 | 2.0 | 3.2 | 2.6 |
| **`get_sys()` 既定** | 90 | 233 | 297 | 550 | **1126** |
| `eig` Kron | 0.27 | 0.21 | 0.26 | 1.0 | 5.0 |
| `eig` DAE | 0.07 | 0.31 | 0.53 | 3.0 | 21 |

- IEEE68 では `get_variable_map` + `point_vector` が 557 ms で `linearize` の **65 %** です。段階の合計は 848 ms で全体の 98 % を説明します。
- プロファイラ (オーバーヘッドで全体 14 s に膨らむので比率のみ): `table.table` 1835 回、`get_variable_map` 系統全体 3 回、母線 272 回、`Component.get_variable_map` 204 回。`table` 関連が上位を占めます。行列演算で目立つのは `ssdata.feedbackG` 1.3 s (`connect` 17 回) です。
- 最大の 68 母線で約 1 秒なので、現状で使用に支障はありません。より大きな規模への外挿は [未確認] です。

**疎行列にした場合の参考** [計測, 現行コードではない]: IEEE68 の `Axv/(-Avv)` は密 16.75 ms、疎 0.23 ms (結果の nnz は 6528/19584 = 33 %)。

### 5.3 メモリ

`ps` の RSS は実行中に単調増加するだけで (1.0→1.5 GB、MATLAB 本体を含む)、段階ごとの増分は測れませんでした。**直列化サイズ**を示します。

| 系統 | 7 ブロック | `sys` Kron / Feedback / DAE | `c_sysBus` (`whos`) |
|---|---|---|---|
| Txt3Bus | 2.4 KB | 8.0 / 8.6 / 11.1 KB | 7.7 KB |
| IEEE9 | 26 KB | 32 / 30 / 60 KB | 30 KB |
| IEEE14 | 49 KB | 48 / 50 / 104 KB | 38 KB |
| TEST31 | 219 KB | 176 / 178 / 425 KB | 101 KB |
| IEEE68 | 998 KB | 745 / 657 / 1924 KB | 202 KB |

### 5.4 固有値と非線形シミュレーションとの比較

**固有値** [計測] (`DebugScript.helper.finite_eigs` と同じ処理):

| 系統 | 有限固有値の数 (K/F/D) | K-F | K-D | F-D | 最大実部 | `|e|<1e-6` の数 |
|---|---|---|---|---|---|---|
| Tutorial3bus | 12/12/12 | 2.5e-13 | 3.7e-13 | 1.2e-13 | -1.4e-13 | 1 |
| Txt3Bus | 6/6/6 | 1.9e-14 | 3.7e-13 | 3.5e-13 | -1.7e-11 | 1 |
| Ishizaki6Bus | 4/4/4 | 7.7e-13 | 1.8e-12 | 1.1e-12 | -4.2e-9 | 1 |
| IEEE9 | 21/21/21 | 8.1e-12 | 1.3e-11 | 5.2e-12 | -5.2e-13 | 1 |
| IEEE14 | 30/30/30 | 2.0e-12 | 1.3e-11 | 1.3e-11 | -4.9e-11 | 1 |
| TEST31 | 60/60/60 | 1.8e-12 | 1.2e-11 | 1.4e-11 | -5.8e-9 | 1 |
| IEEE68 | 112/112/112 | 1.1e-10 | 3.0e-10 | 3.2e-10 | **+3.6e-12** | 1 |

- `|e|<1e-6` の 1 個は回転不変性による 0 固有値です (F7 `:55` のコメントと同じ解釈)。
- IEEE68 の最大実部が正なのは、この 0 固有値の丸めです。`isstable` は IEEE9 でも IEEE68 でも `0` を返しました。
- **F7**: `DebugScript.test_F7_linearization` は 31 件すべて合格 (約 61 s)。F7 の許容値 1e-6 に対し上表の差は十分小さいです。
- DAE の無限固有値: IEEE68 で 168 個 = `n_v` 136 + 質量 0 の状態 32。

**非線形との比較** [計測]: `Tolerance=1e-9`, `AbsoluteTolerance=1e-10`, `TimeLimit=Inf`(IEEE68)、t=0〜10 s、0.01 s の格子へ線形補間。線形側は Kron で、質量 0 の状態を消去してから `lsim` しました (下記のとおり `lsim` が直接使えないため)。誤差は全状態の最大絶対値です。

| 系統 | 外乱 | ε | max\|δx\| 非線形 | max 誤差 | 相対 |
|---|---|---|---|---|---|
| IEEE9 (AVR+PSS) | `delta` ずらし | 0.1 | 1.27e-1 | 4.10e-2 | 3.2e-1 |
| | | 0.01 | 1.20e-2 | 3.90e-4 | 3.2e-2 |
| | | 0.001 | 1.20e-3 | 3.94e-6 | 3.3e-3 |
| IEEE9 (制御器なし) | `delta` ずらし | 0.1 | 2.78e-1 | 2.77e-1 | 1.0 |
| | | 0.01 | 1.21e-2 | 2.61e-3 | 2.1e-1 |
| | | 0.001 | 1.21e-3 | 2.59e-5 | 2.2e-2 |
| IEEE14 | `delta` ずらし | 0.1 | 1.00e-1 | 1.78e-2 | 1.8e-1 |
| | | 0.01 | 1.00e-2 | 1.80e-4 | 1.8e-2 |
| | | 0.001 | 1.00e-3 | 1.82e-6 | 1.8e-3 |
| IEEE68 | `delta` ずらし | 0.1 | 6.10 | 3.15e-1 | 5.2e-2 |
| | | 0.01 | 6.17e-1 | 3.27e-3 | 5.3e-3 |
| | | 0.001 | 6.18e-2 | 3.51e-5 | 5.7e-4 |
| IEEE9 (AVR+PSS) | `Pmech` ステップ | 0.1 | 4.56 | 2.15e-1 | 4.7e-2 |
| | | 0.01 | 4.37e-1 | 2.33e-3 | 5.3e-3 |
| | | 0.001 | 4.35e-2 | 2.34e-5 | 5.4e-4 |
| IEEE14 | `Pmech` ステップ | 0.1 | 1.94e+1 | 8.20e-2 | 4.2e-3 |
| | | 0.01 | 1.95 | 7.77e-4 | 4.0e-4 |
| | | 0.001 | 1.95e-1 | 7.73e-6 | 4.0e-5 |
| IEEE68 | `Pmech` ステップ | 0.1 | 5.71e-1 | 7.23e-3 | 1.3e-2 |
| | | 0.01 | 5.71e-2 | 7.37e-5 | 1.3e-3 |
| | | 0.001 | 5.71e-3 | 1.64e-6 | 2.9e-4 |

- **誤差は ε² に比例** (10 倍小さくすると約 100 分の 1)。線形化が 1 次まで正しいことの根拠です。IEEE68 の ε=0.001 だけ比が 45 倍なのは、積分誤差が見え始めたためと考えます [推測]。
- 母線電圧の誤差も同じ傾向です (IEEE14, ε=0.001 で `|δV|` 5.5e-4 に対し 1.9e-6、`v = -Avv⁻¹ Avx x` から算出)。
- Kron と Feedback の応答差は最大 4.6e-14 です。
- IEEE68 を既定の `TimeLimit=10 s` で実行すると、厳しい許容誤差では t≈1.4〜2.2 s で `flag=0` になります。最初の計測がこれで切れたため、上表は `TimeLimit=Inf` の再計測です。

### 5.5 エッジケース

| ケース | 結果 [計測] |
|---|---|
| 制御器なし (`IEEE9, LocalController=false`) | 正常。上表 |
| ローカル制御器 / グローバル制御器 (F7 の構成) | 3 方式一致。F7 合格 |
| グローバル制御器 + `Point` | 平衡点では `Axx` の差 0 |
| AVR に `local_LQR` を追加 | `ReplaceController` の警告で AVR が置換され、同じ入力を 2 つで駆動する状態は API で作れない |
| 機器なし母線 (`build_9bus`) | Feedback は自動で非 unit。`Y_nn` の `rcond` 0.7。n=15 |
| P=Q=0 の `load-power` | `Div=0`。`has_I2V` が除外。K-F 差 7.8e-15。ただし入力は消える (§6-B5) |
| `NonUnit=7` (IEEE14, P=Q=0) | F 差 2e-12。**Kron, DAE は `NonUnit` を無視** (A が同一) |
| `NonUnit=[7 9]` (B009 は負荷あり) | Feedback の最大実部 **+1.09**、最大差 1.09。警告なし |
| `NonUnit=2` (発電機+負荷) | F の n=24 に減少、最大差 1.59 |
| `NonUnit=[2 3]` | n=18、最大差 1.43 |
| `NonUnit` = 全母線 | `linearize` は `flag=true`。Feedback は意味不明なエラー (§6-B1) |
| `NonUnit=[7 7]` / `99` / `1.5` | 正常 / `GUILDA:odeLinearizer:NonUnit` / `mustBeInteger` |
| AGC の対象を `NonUnit` 指定 | Kron は n=31 で正常。Feedback は `GUILDA:LinearizationResult:GlobalControllerPort` |
| AGC + `gen-droop` | `initialize` は通り、`get_sys` が `cellfun` のエラー (§6-B3) |
| 枝抵抗 R=0 (`IEEE14bus_lossless`) | K-F 1.0e-12、K-D 2.0e-12、`rcond` 6.4e-3。問題なし |
| 枝抵抗 R≠0 (`IEEE14bus`, `_NoTap`) | K-F ≤2.0e-12、K-D ≤5.0e-11 |
| 特異な `Avv` (スタブのみの 2 母線) | `rcond=0`, `flag=true`, メッセージは正常。Kron と Feedback はエラー (§6-B4)。DAE は通る |
| `Y_nn` が特異 | R=0, B=0 の直列枝で試したが `rcond` 4.2e-2 で**特異にならず**、再現できなかった。全母線 `NonUnit` は B1 で先に止まる [未確認] |
| 状態があり `Div=0` の機器 (スタブ) | Kron, DAE は正常 (K-D 7.7e-14)。Feedback はエラー (§6-B4) |
| 未初期化 | `GUILDA:PowerNetwork:EquilibriumStale`。編集後も同じ |
| 潮流が解けない系 | `initialize` が `InitializePowerflowFailed`、その後の `get_sys` は `EquilibriumStale` |
| 孤立母線 | `initialize` が非収束で、線形化に到達しない |
| 故障中の `Point={sim, 0.52}` | §6-R2 |
| `net.get_sys` の `lsim` (質量 0 あり) | IEEE9, IEEE68 の Kron は `lsim` の初期値付きがエラー。`dss2ss` で 21 / 112 状態になり、固有値差 1.2e-11 / 3.8e-10 |
| retrofit | 作れない (§1.8) |

**補足**: `DebugScript.helper.build_ieee14` の直後に `get_sys` が通りました [計測]。同 helper のコメント「平衡点は未設定」(`+DebugScript/+helper/build_ieee14.m:6`) と食い違います。未初期化の確認には手で組んだ系統を使いました。

## 6. 観察された問題

### バグ (最小再現つき)

**B1. 全母線を `NonUnit` にすると意味不明なエラー** (`LR/get_ss.m:180, 185`)。`blkdiag()` が `[]` を返し `.InputName` で落ちます。

```matlab
net = network.IEEE14bus();  net.get_sys(NonUnit=1:14);
% MATLAB:structRefFromNonStruct
```

**B2. 機器と制御器の `sys` を完全な名前で添字指定できない** (`S/@Component/get_sys.m:105-106`, `S/@LocalController/get_sys.m:67-68` [後者は同じ構成からの推測])。チャネルと同名のグループを作るためです。母線はグループがなく動きます。

```matlab
c = net.a_Bus{1}.a_Component{1}.get_sys();
c(c.OutputName{3}, c.InputName{3})   % 「チャネルとグループの両方で一致」のエラー
```

**B3. 出力のない機器に AGC を付けると `get_sys` が内部エラー** (`S/@GlobalController/GlobalController.m:150`)。`initialize` は通ります。`GlobalControllerPort` にも届きません。

```matlab
net = DebugScript.helper.build_3bus("gen-droop");
net.add_global_controller(controller.agc.broadcast_PI_AGC(net,"agc",net.a_Bus{2}.a_Component{1}));
net.initialize();  net.get_sys();   % MATLAB:cellfun:NotAScalarOutput
```

**B4. `has_I2V` の判定漏れと、特異時の診断なし** (`LR/get_ss.m:221`, `:76`, `:216`, `OL/solve.m:96`)。

- 状態があれば `D` が特異でも I2V へ進み、`D^-1` が `Inf` になって `dss` が `"A" 行列は Inf または NaN を含まない...` で止まります。
- `Avv` が特異でも `flag=true` のままで、Kron で同じエラーになります。Feedback の結線も同じです。`output.rcond_Avv` は `0` と出ますが誰も見ません。
- 再現には電流源形のスタブが必要です (`dx = u-x`, `I = x(1)+1j*x(2)`, Jacobian なし)。スタブだけの 2 母線で `rcond=0`、`flag=1`。出荷モデルだけで踏むかは [未確認] です。

**B5. Feedback が P=Q=0 の負荷の入力を黙って落とす** (`LR/get_ss.m:176`)。`has_I2V` が偽になった母線の入力ごと消えます。入力の B は 0 ではありません (Kron の B の列ノルム)。

```matlab
net = network.Ishizaki6Bus();  r = net.linearize();
% Kron 入力 12, Feedback 入力 8
% 消えるのは Pload/Qload_LPQ1B002, LPQ1B004。Kron の |B列| = 0.767, 0.737, 0.052, 0.098
```

IEEE14 でも `LPQ1B007` の `Pload` (0.558)、`Qload` (0.15) が消えます。**既定の `get_sys` は Feedback なので、利用者がこの入力の応答を取れません。** B/C/D の v3 との一致はテスト済み (F7 `:279-315`) なので、v3 から同じ動作と考えます [推測]。

**B6. `I2V` で `NaN` の `D` を警告なく返す** (`S/@Component/get_sys.m:176`, `S/@Bus/get_sys.m:87`)。

```matlab
b = n.a_Bus{4};            % 機器なし母線 (build_9bus)
b.get_sys("port","I2V").D  % [NaN NaN; NaN NaN]
```

P=Q=0 の `load-power` でも同じです。実行時に警告は記録されませんでした。

### 数値リスク

- **R1. 形の違いが固有値では見えない。** Feedback の `Vst` 消去 (IEEE9: 27→24, IEEE68: 144→128)。`StateName` で引くと見つからず、`OutputName` にはあります (C は 144×128)。残るのは `Vtr` などで、`E` はなお特異です (rank 112/128)。消えるのが `Vst` だけである理由は `connect` の `Simplify` によると考えますが [推測]、条件までは調べていません。F7 の寸法確認は `>=` のみで、対象は質量 0 の状態を持たない IEEE14 です (`test_F7_linearization.m:35`)。
- **R2. `Point` は網の状態を反映しない。** `cm_Y` は常に現在の `Y` です (`OL/solve.m:61`)。故障中の `{sim, 0.52}` で `Y` の差は 0、`flag=true` です。`|V_B008|=0` の点で Kron/Feedback の最大実部 +17.4、DAE (`theta&rho`) +3.9e-3 と**方式で値が違います**。`V=0` で座標変換が退化するためと考えます [推測]。`theta&V` はエラーです。
- **R3. `Point` の固定項を捨てる** (§1.8)。平衡点以外の `x` を「偏差」と見た応答は、そのままでは非線形の接線になりません。
- **R4. `NonUnit` は等価変換ではない。** 非 unit 母線の機器を電流ごと落としますが、点は元のままで、平衡が保たれません。
- **R5. `NonUnit` を Kron, DAE が無視する。** `get_sys` の help にある通り (`S/@PowerNetwork/get_sys.m:15`) で、仕様ではあります。ただし `Plot` は Kron なので、`NonUnit` が描画に反映されません。F7 の `Non unit bus` (`:62-67`) は `Kron` と `Feedback` の一致を確かめていますが、B007 は P=Q=0 で差が出ない場合です。
- **R6. `has_I2V` の `1e-12` は絶対値の `rcond`。** スケールの根拠はコードにありません。
- **R7. 固定刻み `d=1e-5`。** 状態のスケールが大きい利用者モデルでは相対的に粗くなります (出荷モデルでは影響なし)。
- **R8. `eig` の扱い。** `isstable` は 0 固有値があると偽を返します (IEEE9, IEEE68 で確認)。`finite_eigs` は `abs(e) < 1e6` で切ります (`+DebugScript/+helper/finite_eigs.m:8`) が、今回 `|e|≥1e6` の有限固有値は 0 個でした。

### 重複

- **I2V 変換が 3 か所**: `S/@Component/get_sys.m:176-182`、`S/@Bus/get_sys.m:87-91`、`LR/get_ss.m:224-251`。
- **グローバル制御器の閉ループが 2 通り**: `OL/solve.m:131-187` (行列) と `LR/get_ss.m:200-210` (`feedback`)。
- **複素→実数変換が 2 か所**: `S/+tools/complex2matrix.m` と `LR/get_ss.m:214` の局所関数 (`cell2mat` + `arrayfun`)。
- **`all_controllers` が 3 か所**: `S/@Component/get_sys.m:286`、`S/@Component/get_variable_map.m:61`、`OL/point_vector.m:110`。**`shape` は 2 か所**。
- 検証の二重化: `validate_options` と `set.Point`、`check_point` が `point_vector` の中でも再度呼ばれます (`OL/odeLinearizer.m:81-84`, `OL/point_vector.m:27`)。

### 未使用・効かないコード

- `tools.for_ss.*`, `tools.ssfeedback`: 自身の内部以外から呼ばれていません (grep)。
- `GUILDA.config("Model","port_vw")`: `class-design.html:345` に記載があり `@GUILDA/config/DefaultModel.json` に値がありますが、`.m` で読むコードは `_GUILDAsystem`, `_GUILDAobject`, `@GUILDA` にありません。
- `Bus` の `full`, `con`、`Component` の `full`, `con` (`rec=true`)、`GlobalController` の `full` (§4)。`OL/solve.m:54, 57` は意味のない `"full",true` を渡しています。
- `rec=false`, `con`, `full` は「内部用」と書かれていますが公開引数で、`local_LQR` が使っています。
- `local_LQR_retrofit`, `get_environment` は v2 のインターフェースのままで動きません。

### 名前と説明

- Kron だけ `OutputName` が空です (`LR/get_ss.m:89`)。F7 が v3 との一致として固定しています (`:310-311`)。
- help の例にネットワークのタグがありません (`S/@Component/get_sys.m:14`)。ラベルは `net` の名前に依存するので、別名の系統では文字列が変わります。
- DAE の母線変数は `theta1`, `rho1` で、母線のタグでなく**番号**です (`LR/get_ss.m:158-159`)。他のラベルと形式が違います。
- `get_sys` の説明は「reduced state-space model」ですが、DAE は縮約ではありません (`S/@PowerNetwork/get_sys.m:2`)。
- `get_ss` は「Outputs: the states」(`LR/get_ss.m:11, 15`) としていますが、Feedback はグローバル制御器の状態を含まず、消去した `Vst` を含みます。
- `class-design.html:141` の「states are never outputs」と系統の出力の矛盾 (§4)。
- `class-design.html:202` の「グローバル制御器は出力 Y を読む」と状態名による接続の違い (§4)。

### 性能

- **変数表の再構築**: `solve` は `get_variable_map` と `point_vector` で表を何度も作ります。1 回の `linearize` で系統の表を 3 回、母線の表を 272 回、機器の表を 204 回です (IEEE68 のプロファイル)。平衡点でも同じです。
- **`get_admittance_matrix`**: `table` のラベル添字を枝ごとに使っています (`:27-28`)。
- **`connect`**: 機器ごと (制御器があるとき) と Feedback で呼びます。IEEE68 で 17 回。
- **密行列**: 現状の規模では行列演算は支配的ではありません。

## 7. 調査の判断と限界

- 「nonzero R」は枝抵抗と解釈しました。`local_LQR` の重み `R` の影響は調べていません。
- `Point` で平衡点以外の `u` を使う場合に、機器の入力が制御器の出力込みかどうかは確認していません [未確認]。出荷モデルの Jacobian が `u` に依存するかも確認していません。
- 再現用のスタブとスクリプトは一時フォルダに置き、コミットしていません。B4 の再現に使ったスタブの式は本文に記載しました。
- `notes/README.md` は変更していません。
