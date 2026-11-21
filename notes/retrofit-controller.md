# Retrofit 制御(`feature/pss-retrofit`)

ブランチは `feature/pss-retrofit` です(未 push、分岐元 `refactor/design-alignment` の `b544b001`)。旧版の `controller.local_LQR_retrofit` は v2 の作りのままで、キーがなく、作ることもできませんでした。2026-11-17 にユーザーが、教科書 5.4 節「レトロフィット制御理論に基づく系統安定化装置」の式 (5.36)〜(5.42) に沿って作り直すことを決めました。この文書はその仕様です。

**ラベル**: [決定] = ユーザーまたはコーディネーターが決めた事項です。[事実] = コードを読んで確認しました。[計測] = MATLAB R2026a で実行して確認しました。

## 1. 決定事項 [決定]

- 役割は `"pss"` で、Static の AVR(`avr-static`)の下に付きます。キーは `pss-retrofit`、クラスは `controller.pss.Retrofit` です。
- 出力は `Vpss` です。Static の AVR は `Vfield = Vfd_ref + Vpss` です(ee170fc6 でマージ済み)。
- ST1・DC1 の下に付けたらエラーにします(R3)。
- 設計モデルは Θ = Θint だけです。Q と R の既定は単位行列です。
- 補正器は、教科書どおりの厳密な非線形版にします(R5)。
- 範囲外: 環境モデル(Θagc、Θext、`get_environment` の v4 化)、ST1 の電圧依存リミッタ、PSS1 で τn = τd = 0 のときの扱い。
- 旧版の `controller.local_LQR_retrofit` と `+controller/+modeling/get_environment.m` は削除します。

## 2. 式

発電機を `E ẋ = f(x, V, u)`、`u = [Pmech; Vfield]` とします。教科書の (5.42) は、次の形に書き直せます。

```
E x̂' = f(x, V, u0) − A_d (x − x̂)
Vpss = −K (x − x̂)
```

- x は観測した発電機の全状態("Xall")、x̂ は Retrofit の状態です。
- `u0 = comp.rv_Uequilibrium` です。Pmech は観測できないので、平衡点の値を使います。既定の Static ガバナでは厳密で、LPT ガバナや AGC があると近似になります(ヘルプに書きます)。
- `A_d = ∂f/∂x`、`B = ∂f/∂Vfield` で、どちらも V と u を平衡点に固定した値です。`comp.get_linear_matrix` から取ります。
- `K = lqr(E\A_d, E\B, Q, R)` です。E が特異な機器ではエラーにします。

この形から、次の性質が出ます。

- e = x − x̂ は `E ė = (A_d − B K) e` に厳密に従います(f が Vfield について線形なため。実際の Vfield = u0(Vfield) + Vpss)。
- 平衡点で x̂ = x、Vpss = 0 です。
- V を通して入る外乱(遠くの地絡など)では、x と x̂ が同じ式に従うので e ≡ 0 です。
- 線形化した系の固有値は、Retrofit がないときの系の固有値と `eig(E\(A_d − B K))` に分離します。

## 3. クラスの契約

- `classdef (Sealed) Retrofit < LocalController`。`pss.abstract` は `sv_u = "omega"` を固定で持つので継承しません。
- タグは `"CP"+tag`。`key = "pss-retrofit"`、`s_role = "pss"`。
- `sv_u = "Xall"`、`sv_y = "Vpss"`。`sv_x` は `"hat_" + comp.sv_x` で、`resolve_ports` で決めます。`sv_para` は空です。
- コンストラクタの引数は `opt.Q` と `opt.R` だけです。`Access={?Component}` にし、`tools.require_toolbox("control", ...)` を呼びます。
- `get_equilibrium` は `[comp.rv_Xequilibrium, comp.rv_Xequilibrium]` を返します。
- `initialize(l_equilibrium)` で K を設計します。プロパティ `K` と `sys_design` は読み取り専用です。
- `set_odefcn` で、親(観測する発電機)の `f_dx` と `f_JacobiDx`(親が先に作り直す)、u0、A_d、K を param の struct に入れます。設計前はゲインを 0 にします。
- static の `fcn_dx`、`fcn_y`、`fcn_Mass`(= E)、`Jacobi_dx`、`Jacobi_Y`:
  - `Axx = A_d`、`Bxv = ∂f/∂V`、`Bxu = ∂f/∂x − A_d`
  - `Cyx = K`、`Dyv = 0`、`Dyu = −K`
  - hot path の規則に従い、arguments ブロックは class と size だけにします。
- Q と R の set メソッドと検証は `local_LQR` に合わせます。単一用途のローカル関数は作りません。
- 周波数の変更は `local_LQR` と同じ扱いです。平衡点が最新なら、`set_odefcn` で K を設計し直します。
- R3 のエラーの ID は、`msg` の規則(呼び出し元のクラスの ID)に従います。

## 4. 付け替えの注意

- `add_local_controller` の "pss" の分岐は、古い PSS を消して新しい PSS を付けてから `resolve_observe` を呼びます。R3 の判定を後で出すと、古い PSS が消えたまま止まることがあります。
- Static を別の AVR に置き換えると、その下の PSS は新しい AVR に移ります(警告なし)。そのため、`set_avr("avr-ST1")` で Retrofit が ST1 の下に移ってしまいます。
- 方針: どちらの場合もエラーにして、発電機を呼び出し前の状態のまま残します。利用者には、先に Retrofit を外すよう案内します。
- 実装(案 A、2026-11-17 コーディネーター・潮流計算・設定の了承): `@Component/add_local_controller.m` のローカル関数 `check_outputs` だけを変えました。(1) "pss" のとき、出力の確認に `con.driven_inputs(chain)` を使います。(2) 新しい制御器の役割が "avr" で、今の AVR に PSS があるとき、移る PSS を `pss.driven_inputs(new_con)` で確かめます。"local" への置き換えは PSS を消すので確かめません。Retrofit は `driven_inputs` を上書きし、Static でない AVR なら `GUILDA:Retrofit:ParentNotStatic` で止めます。どちらも状態を変える前に呼ばれます。基底の `driven_inputs` は `sv_y` を返すので、PSS1 の振る舞いは変わりません。

## 5. テスト(`+DebugScript/test_F68_pss_retrofit.m`)

- (a) Static の下に付けられる。キー、役割、`sv_x` の名前、Q と R の既定値。
- (b) 平衡点が、付ける前と変わらない。平衡点で Vpss = 0。
- (c) `get_ss` の固有値が、Retrofit なしの系の固有値と `eig(E\(A_d − B K))` を合わせたものと一致する。
- (d) `add_offset` で自機の状態に初期値の外乱を入れると Vpss ≠ 0 になり、Retrofit なしより速く戻る。遠くの母線の地絡では Vpss がほぼ 0。
- (e) ST1・DC1 の下に付けるとエラーになり、発電機が呼び出し前の状態のまま残る(古い PSS も含めて)。
- (f) Retrofit を付けた発電機で `set_avr("avr-ST1")` を呼ぶとエラーになり、状態が変わらない。
- (g) Jacobian が数値微分と一致する。

## 6. 実装と計測 [計測] (R2026a、2026-11-17)

- 設計は `initialize(true)` が関数を古いと印を付け、続く `set_odefcn` で行います。`set_odefcn` は、平衡点が最新なら毎回 K を設計し直すので、周波数の変更も同じ経路で扱います(`local_LQR` の `r_designHz` に当たるものは要りません)。平衡点が古いあいだは K と A_d を 0 にします。
- §3 の一覧の外で足したもの: `set_inputs`(`"Xall"` を使う制御器が上書きを求められる)、`driven_inputs`(§4 の事前チェック用、案 A で承認)、`private/weight.m`(Q と R の 2 か所から呼ぶ)、メッセージ `SystemTools/GUILDA/en/Retrofit.xml`(`ParentNotStatic`、`SingularMass`、`WeightSize`、`WeightShape`)。
- 固有値の分離: IEEE9bus の B002 と 3 母線系統で、Retrofit なしの固有値と `eig(E\(A_d − B K))` を合わせたものとの差は 1e-12 程度です。
- 誤差 e = x − x̂ は、シミュレーションでも `expm(E\(A_d − B K) t) e(0)` と 1e-4 以内で一致します(ソルバーの許容誤差の程度)。
- 遠くの地絡(IEEE9bus の B001、B005、B007、B009)で max|Vpss| は 1e-14 程度です。
- **既定の重み(Q = I、R = 1)では、効きは小さいです。** IEEE9bus の B002(one_axis、`delta, omega, Eq`)では、閉ループの極が −0.551 ± 9.08i から −0.557 ± 9.08i に動くだけで、`delta` に 0.1 の初期値の外乱を入れたときの ∫|ω| は変わりません(0.00155)。R = 0.01 にすると、`Eq` の外乱で ∫|ω| が 0.0214 から 0.0046 に減ります。テスト F68 と教材は R = 0.01 を使います。
- 既定値はユーザーの決定(2026-11-17)で Q = I、R = 1 のままです。ヘルプと教材に、効きが小さいことがあること、R を小さくすること(例 R = 0.01)、保証されるのは e の減衰だけであることを書きました。
- 「外乱からの戻りが速い」は、発電機の状態の全体については保証されません。保証されるのは e の減衰です(x = x̂ + e で、x̂ は V を通して系統の残りから動かされます)。3 母線系統では、`delta` の外乱で ∫|ω| が R = 1 で 0.00034 から 0.00046 に、Q の ω の重みを 1e6 にした IEEE9bus でも 0.00155 から 0.00215 に増えます。
- 古典モデル(`gen-classical`)では `Vfield` が状態に効かないので B = 0、K = 0 になり、何もしません(エラーにはなりません)。

## 7. 残り

- `Bus.replace_component`(`move_local_controllers`)では Static の AVR は移らないので、その下の Retrofit も移りません。この経路は確かめていません。
