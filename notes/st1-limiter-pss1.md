# AVR_ST1 の出力リミッタと PSS1 の時定数 0(`fix/st1-limiter-pss1-nan`)

ブランチは `fix/st1-limiter-pss1-nan` です(未 push、分岐元 `refactor/design-alignment` の `78139590`)。この文書は調査と提案です。§5 の問いには 2026-11-18 に回答があり(§5.1)、§6 の段取りで実装します。

**ラベル**: [事実] = コードを読んで確認しました。[計測] = MATLAB R2026a で実行して確認しました。[文献] = 教科書(`master_corona_final.pdf`)を読んで確認しました。[推測] = 確かめていません。[提案] = この文書の提案で、まだ承認されていません。

## 0. 要点

1. **PSS1 の時定数 0 は再現しました** [計測]。表 5.7 の例 1(`tn2 = td2 = 0`)では `1 - td2/tn2` が 0/0 = NaN になり、`initialize` が「平衡点を保てない(|dx| = NaN)」と警告し、`simulate` は t = 0 で止まり、`get_sys` は「Jacobian が有限でない」エラーになります。`td2 > 0, tn2 = 0` でも同じく壊れます(`-Inf`)。
2. **PSS1 の推奨**: 教科書の実現 (5.35b) はそのまま残し、`tn = td`(0 を含む)のブロックだけを恒等写像として扱います。今のパラメータの結果はビット単位で変わりません [推測]。
3. **AVR_ST1 の出力リミッタは、教科書と構造が違います** [事実・文献]。教科書 (5.32) は出力 `Vfield = sat(Vap; γ₋|V|, γ₊|V| − k₀ Ifield)` の静的な飽和です。GUILDA は状態 `Vap` の固定値による non-windup です。
4. **AVR_ST1 の推奨**: 今の non-windup(`Vap_max`/`Vap_min`)は残し、その後段に教科書の出力飽和(新しい列 `gamma_max`、`gamma_min`、`k0`)を加えます。IEEE 421.5 の ST1A(内部の VAMAX/VAMIN と、出力の VT·VRMAX − KC·IFD)と同じ二段の構造です。既定値(`Inf`、`-Inf`、`0`)では今と同じ式です。
5. **影響**: 既定値では式は変わりませんが、AVR に入力 `Ifield` が増えるため、`rm_variable` の列(`uc`)が AVR_ST1 1 台につき 1 列増えます [事実: AVR の入力は `uc` の列になる、計測で確認]。`simulate_baseline` の 6 例のうち `ieee68_fault`、`ieee14_trip`、`ieee9_offset` の 3 例は列の数が変わるので、基準の記録し直しが要ります。
6. **別の不具合を 1 つ見つけました** [計測]: `tap = 0`(表 5.5 の例 1、例 2)で `Vap_max`/`Vap_min` を有限にすると、non-windup が代数方程式を `0 = 0` に置き換えるため、地絡除去後の t = 1.05 s で `simulate` が止まります。

## 1. PSS1(`pss-PSS1`)の時定数 0

### 1.1 再現 [計測]

IEEE9bus(`LocalController=false`)の 3 台に `avr-ST1`(既定)と `pss-PSS1` を付け、B007 に 1.00〜1.05 s の地絡を与えました(スクリプトはリポジトリの外)。

| PSS1 のパラメータ | initialize | simulate | get_sys |
|---|---|---|---|
| 既定(`tn2 = 3.00, td2 = 5.40`) | 正常 | 10 s まで完走 | 正常 |
| 表 5.7 例 1(`kpss 9.5, tWS 1.4, td1 0.033, tn1 0.154, td2 0, tn2 0`) | 警告「`CP2`: \|dx\| = NaN」 | t = 0 で停止(「largest residual NaN」) | エラー「The Jacobian of the local controller B001SG1CP2 … is not finite」 |
| `tn2 = 0, td2 = 0.02` | 警告「\|dx\| = NaN」 | t = 0 で停止 | (同上と推測) |
| `tn1 = td1 = 0.05`(恒等) | 正常 | 完走 | 正常 |

### 1.2 原因 [事実]

`_GUILDAobject/+controller/+pss/@PSS1/` は教科書 (5.35b) をそのまま実装しています。

```
td·ξ̇ = −ξ + (1 − td/tn)·v_in,   v_out = (tn/td)·(v_in − ξ)
```

- `tn = td = 0`: `1 − td/tn = 0/0 = NaN`、`tn/td = 0/0 = NaN`。`fcn_dx`、`fcn_y`、`Jacobi_dx`、`Jacobi_Y` のすべてに現れます。
- `tn = 0, td > 0`(純粋な 1 次遅れ): `1 − td/tn = −Inf`。
- `td = 0, tn ≠ 0`: 伝達関数 `1 + tn·s` は非プロパーで、状態方程式では表せません。今は `tn/td = Inf` になります。
- 洗い出しフィルタの `tWS = 0` は `xiWS = kpss·ω`(代数方程式)となり、出力は 0 です。伝達関数 `tWS·s/(1 + tWS·s)` の極限と一致するので、問題ありません。

教科書の表 5.7 例 1 の意図は「2 つ目の進み遅れブロックを使わない」(= 1)です。

### 1.3 直し方の案

| 案 | 内容 | 利点 | 欠点 | 失敗し得る条件 |
|---|---|---|---|---|
| **P-A(推奨)** | 教科書の実現は残し、`tn == td` のブロック(0 を含む)では係数 `1 − td/tn` を 0、出力の係数 `tn/td` を 1 とします。`td = 0, tn ≠ 0` はコンストラクタと表の編集時にエラーにします。`tn = 0, td > 0` は §5 の Q2 | 今のパラメータでは式が同じなので、基準はビット単位で同じ [推測]。状態 `xi1`、`xi2` の意味が教科書と一致したまま | `tn = 0, td > 0` は別扱いが要ります | 4 関数(`fcn_dx`、`fcn_y`、`Jacobi_dx`、`Jacobi_Y`)のうち 1 つでも分岐を忘れると、値と Jacobian が食い違います(F の検査で拾えます) |
| P-B | 実現を `td·ξ̇ = −ξ + v_in`、`v_out = (tn/td)·v_in + (1 − tn/td)·ξ` に替えます(`td = 0` なら `v_out = v_in`) | `tn = 0` も含め、`td > 0` のすべてで割り算が 1 つだけになります | 状態 `xi1`、`xi2` の意味(値)が教科書と違います。既存の 3 例の基準の `xi` の列が変わります | 状態の値を読む利用者のコードがあれば結果が変わります |
| P-C | `tn`、`td` に 0 を禁止する検査だけを入れます | 最小の変更 | 表 5.7 例 1 が使えません | — |

## 2. AVR_ST1(`avr-ST1`)の出力リミッタ

### 2.1 教科書の式 [文献]

- 式 (5.29)、(5.30)(p. 221): `τ·Ė = −Ifield + Vfield`、`Ifield := (X/X')·E − (X/X' − 1)·|V|·cos(δ − ∠V)`。突極機では `X'`、`X` を `Xd'`、`Xd` に替えます。
- p. 224: `Vfield = sat(Vap; Vfield_min, Vfield_max)`、`Vfield_min = γ₋|V|`、`Vfield_max = γ₊|V| − k₀·Ifield`。母線の地絡で `|V| = 0` のとき界磁電圧は出ません。
- 式 (5.32)・図 5.7(p. 225): 1 次系では `Vap = kap(Vref + Vpss − Vtr)` が代数式(`tap = 0`)で、飽和は出力側です。図 5.7 には `tap` と安定化回路もあります。
- 表 5.5: 例 1 `ttr 0.015, tap 0, kap 200, γ₊ 7.00, γ₋ −6.40, k₀ 0.04`、例 2 `0.02, 0, 210, 6.43, −6.00, 0.038`、例 3・例 4 は `γ = ±∞, k₀ = 0`。本文は「γ₋ は非負」と書きますが、表の γ₋ は負です(下限が負の値になるので、表の値が意図どおりと考えます [推測])。

### 2.2 今の GUILDA [事実]

- `fcn_dx`: `tap·V̇ap = −Vap + kap·Vcom`。`Limiter` が真で、`Vap` が `Vap_max` 以上かつ外へ向かう(または下限で同様)とき `dx2 = 0`(non-windup、9e4a5b19)。
- `fcn_y`: `Vfield = Vap`(出力の飽和なし)。
- AVR の入力は `Vref`、`Vpss` だけです。発電機の `sv_y` は `omega` だけで、`Ifield` はどこにも出ていません。
- 安定化回路は `Mass` の `−kst` で `tst·V̇st = −Vst + kst·V̇ap` を表しています(教科書の図 5.7 と同じ)。

### 2.3 観測の仕組み [事実]

`LocalController` は、入力名が親の `sv_y` にあればその出力を読み、どこにもなければ平衡点の値に固定します。したがって次の 2 つで AVR が `Ifield` を読めます。

1. 発電機の `sv_y` に `Ifield` を加え、`fcn_Y`、`Jacobi_Y` で計算します。定義は (5.29) と同じく「`Ifield := Vfield − Td'·Ėq`」(界磁回路の式の右辺から `Vfield` を除いたもの)で、状態と `V` だけで書けます。
   - `one_axis`、`two_axis`: `Ifield = Eq + (Xd − Xd')·Id`(= (5.30))
   - `park`: `Ifield = Eq + (Xd − Xd')·(Id + (Xd' − Xd'')/(Xd' − Xls)²·Td''·ψ̇d)`。`Td''·ψ̇d` は状態と `Id` で書けます
   - `classical`、`droop`: 界磁回路がありません。出力を加えなければ、AVR の `Ifield` は平衡点の値に固定されます(§5 の Q5)
2. AVR_ST1 の `sv_u` に `Ifield` を加えます。`get_equilibrium` は `Ifield` の平衡値を返します(界磁回路の平衡では `Ifield = Vfield` なので `u(2)`)。

全体観測の `Yall` を使う局所制御器は今はありません(`local_LQR` は `Xall`)[事実]。グローバル制御器は名前で読むので、出力が増えても影響しません [事実]。

### 2.4 直し方の案

| 案 | 内容 | 利点 | 欠点 | 失敗し得る条件 |
|---|---|---|---|---|
| **S-A(推奨)** | 今の non-windup(`Vap_max`、`Vap_min`)を残し、出力に `Vfield = sat(Vap; gamma_min·|V|, gamma_max·|V| − k0·Ifield)` を加えます。新しい列 `gamma_max`(既定 `Inf`)、`gamma_min`(既定 `-Inf`)、`k0`(既定 `0`)。`Limiter = false` は両方を無視します | IEEE 421.5 ST1A と同じ二段の構造です。既定値で今と同じ式なので、IEEE68 の ±5(PST の type 0、定数の上下限)をそのまま使えます。表 5.5 の例 1〜4 をパラメータだけで再現できます | 列が 3 つ、入力が 1 つ増えます。上下限が 2 種類あり、説明が要ります | `gamma = ±Inf` と `|V| = 0` の積が NaN になります(Inf のときは上下限なしと扱う分岐が要ります)。上限が下限を下回る瞬間(地絡で `|V|` が小さく `k0·Ifield` が大きい)の扱いを決める必要があります(Q4) |
| S-B | `Vap_max`/`Vap_min` を廃して、教科書の `gamma_max`、`gamma_min`、`k0` だけにします | 教科書と 1 対 1 | IEEE68 の ±5 は電圧に依らない定数なので表せません(`|V|` 倍になります)。9e4a5b19 の決定(±5、non-windup)を覆します | IEEE68 の結果が変わります |
| S-C | 別のクラス `avr-ST1A`(仮)を作り、AVR_ST1 は変えません | 既存の結果と基準に一切影響しません | クラスが 1 つ増え、ST1 が 2 つになります。「頼まれていないメンバーを増やさない」方針との兼ね合い | — |

### 2.5 `tap = 0` と non-windup(新しく見つけた不具合)[計測]

上と同じ IEEE9bus で、AVR_ST1 を `ttr 0.015, tap 0, kap 200, Vap_max 5, Vap_min −5` にすると、`simulate` が t = 1.05 s(地絡除去)で止まります(「phase 3 … largest residual 30.49」)。`tap = 0` では `Vap` の式が代数方程式なので、`dx2 = 0` に置き換えると `0 = 0` になり、`Vap` が決まりません。`Vap_max = ±Inf`(表 5.5 例 1 そのもの)なら完走します。

案: `tap = 0` のときは non-windup の代わりに `0 = −Vap + sat(kap·Vcom; Vap_min, Vap_max)` とします(静的な飽和。`tap → 0` の極限と一致します)。S-A の中で直すか、別にするかは Q3 です。

## 3. 既存の結果への影響

### 3.1 PSS1(P-A の場合)

- 今のパラメータ(IEEE68 `tn = 0.07/td = 0.02`、IEEE9 `0.05/0.015, 0.08/0.01`、既定 `0.05/0.02, 3.00/5.40`、Tutorial10bus)はどれも `tn ≠ 0, td ≠ 0` なので、式は変わりません。`simulate_baseline` は 6 例とも isequaln の見込みです [推測]。

### 3.2 AVR_ST1(S-A の場合)

| 対象 | 変わるもの |
|---|---|
| `Limiter` スイッチ | 意味は「AVR のすべての上下限を適用するか」のまま。`false` で `Vap_*` と `gamma_*`/`k0` の両方を無視します |
| IEEE68 の既定 ±5 | 値は変えません。`gamma_*`/`k0` は CSV に既定値(`Inf`、`-Inf`、`0`)で明示します(9e4a5b19 で `Limiter` を明示したのと同じ扱い)。式は同じです |
| IEEE9bus、Tutorial10bus、利用者の AVR_ST1 | 式は同じです |
| 状態・入力の数 | AVR_ST1 1 台につき `uc` が 1 列(`Ifield`)増えます。発電機の `sv_y` も 1 つ増えます(rm_variable の列には現れません [推測]) |
| `simulate_baseline` | `ieee68_fault`(16 台)、`ieee14_trip`(5 台)、`ieee9_offset`(3 台)は `rm_variable` の列の数が変わるので isequaln になりません。既存の列の値は、DAE の変数が増えて誤差の評価やニュートン法の反復が変わるため、丸めの程度でずれる可能性があります [推測]。`ieee68_nolc`、`ieee14_open`、`agc_trip` は AVR_ST1 がないので変わらない見込みです [推測]。3 例は記録し直しが要ります |
| 線形化 | `Ifield` の Jacobian(発電機の `Jacobi_Y` と AVR の `Dyu`)が加わります。既定値では出力の飽和は効かないので、`A` 行列は変わりません [推測] |
| 既存のテスト | `sv_para`、`sv_u`、`sv_y` の並びを固定で調べているテスト(F28 など)の修正が要ります [推測、実装時に洗います] |

## 4. パラメータの既定値 [提案]

| クラス | 列 | 既定値 | 理由 |
|---|---|---|---|
| AVR_ST1 | `gamma_max` | `Inf` | 既存の結果を変えないため。表 5.5 の例 3・例 4 と同じ |
| AVR_ST1 | `gamma_min` | `-Inf` | 同上 |
| AVR_ST1 | `k0` | `0` | 同上 |
| AVR_ST1 | 既存の列 | 変えません | — |
| PSS1 | すべて | 変えません | 既定の `tn2 = 3.00, td2 = 5.40` は表 5.7 例 2 と同じ |

## 5. 決めてほしい点

1. **PSS1 の直し方**: P-A(教科書の実現を残し、`tn = td` を恒等とする)でよいですか。
2. **PSS1 の `tn = 0, td > 0`(純粋な 1 次遅れ)**: (a) エラーにする、(b) この場合だけ P-B の実現に切り替えて扱う、のどちらにしますか。推奨は (b) です(状態の意味は変わりますが、今は NaN で動かない場合だけなので既存の結果に影響しません)。
3. **AVR_ST1 の直し方**: S-A(non-windup を残し、出力の飽和を加える)でよいですか。§2.5 の `tap = 0` の不具合も同じブランチで直してよいですか。
4. **上限が下限を下回るとき**(地絡で `|V|` が小さいなど): 教科書は定めていません。推奨は「下限を優先する」(`Vfield = max(min(Vap, 上限), 下限)` の順)です。PST や PSS/E の ST1A も同じ順で評価します [推測]。
5. **`classical`、`droop` 発電機**: `Ifield` を出力しないので、AVR の `Ifield` は平衡点の値に固定されます。(a) そのまま許す、(b) `k0 ≠ 0` の AVR_ST1 を付けたら `initialize` でエラーにする、のどちらにしますか。推奨は (a) に説明を添えることです。
6. **列名**: `gamma_max`、`gamma_min`、`k0` でよいですか(教科書の記号 γ₊、γ₋、k₀ に対応。`Vap_max` と同じ `_max`/`_min` の形)。
7. **基準データ**: `ieee68_fault`、`ieee14_trip`、`ieee9_offset` の 3 例を記録し直すことになります。simulate のコーディネーターとの調整のうえ、このブランチで記録し直してよいですか。

### 5.1 決定(ユーザー、2026-11-18、Retrofit のコーディネーター経由)

Q1〜Q7 はすべて推奨どおりです。

| # | 決定 |
|---|---|
| Q1 | PSS1 は P-A(`tn = td` のブロックを恒等とする)。`td = 0, tn ≠ 0` はエラー |
| Q2 | `tn = 0, td > 0` のときだけ P-B の実現に切り替えます |
| Q3 | AVR_ST1 は S-A(non-windup の後段に出力の飽和)。`tap = 0` の不具合もこのブランチで直します |
| Q4 | 上限が下限を下回るときは下限を優先します |
| Q5 | `classical`、`droop` では `Ifield` を平衡点の値に固定し、ヘルプに書きます |
| Q6 | 列は `gamma_max` / `gamma_min` / `k0`、既定値は `Inf` / `-Inf` / `0` |
| Q7 | 基準の 3 例は、simulate のコーディネーターと調整したうえでこのブランチで記録し直します |

追加してよいメンバーは次だけです(それ以外は作る前に相談します)。

- AVR_ST1 の列 `gamma_max`、`gamma_min`、`k0` と入力 `Ifield`
- `one_axis`、`two_axis`、`park` の出力 `Ifield`(`fcn_Y` と `Jacobi_Y` の行)
- PSS1 のパラメータの検査(`td = 0, tn ≠ 0` のエラーとメッセージ)

発電機の `sv_y` に `Ifield` を足すことで影響しうる箇所(export/import の F70、名前で読む AGC、`Yall`、Retrofit、出力の並びを固定で調べるテスト F22・F28 など、クラスページの自動生成)は、実装のときに確かめます。

## 6. 実装の段取り

1. simulate のコーディネーター(AVR リミッタ 9e4a5b19 と基準データの担当)に知らせます。
2. PSS1 の修正(1 コミット)。新しいテスト `test_F78_pss1_zero_time_constant.m`(表 5.7 例 1 で NaN が出ないこと、`tn = td` の場合に恒等になること、`get_sys` が有限であること)。
3. 発電機の `Ifield` 出力(1 コミット)。
4. AVR_ST1 の出力飽和と `tap = 0` の修正(1 コミット)。新しいテスト `test_F79_st1_field_limit.m`(表 5.5 例 1 で地絡を完走すること、既定値で今と同じ値になること、Jacobian と数値微分の一致)。
5. CSV(IEEE68、IEEE9)に新しい列を明示し、基準を記録し直します。
6. 関係する分類(model、powerflow、simulate、linearize)の small を各段で流し、マージ前に medium を 1 回流します。新しいテストは `test_categories.m` と `test_levels.m` に登録します。

## 7. 実装の結果(2026-11-18)

### 7.1 コミット

| コミット | 内容 |
|---|---|
| `1b38bbeb` | §5.1 の決定を記録 |
| `c43de135` | PSS1: `tn = td = 0` は恒等、`tn = 0` は 1 次遅れ、`td = 0, tn ≠ 0` は `GUILDA:PSS1:ImproperLeadLag`(`PSS1.xml` を新設)。F78 |
| `1e4f3392` | `one_axis`、`two_axis`、`park` の出力 `Ifield`(`fcn_Y`、`Jacobi_Y`) |
| `b06e307e` | AVR_ST1 の出力の飽和(`gamma_max`、`gamma_min`、`k0`、入力 `Ifield`)と `tap = 0` の静的な飽和。F79。F1・F7・F63 の並びの検査を更新 |
| `50cd21ba` | IEEE68、IEEE9 の `avr-ST1/parameter.csv` に新しい列を既定値で明示 |

### 7.2 実装の要点 [事実]

- PSS1: 通常のパラメータでは式を 1 文字も変えていません(分岐は `tn = 0` のときだけ)。PSS1 の段の後で `simulate_baseline` は 6 例とも isequaln でした [計測]。
- AVR_ST1: `sv_para` の末尾に `gamma_max; gamma_min; k0` を追加(`Limiter` は 8 番目のまま)。`fcn_y` は `Limiter` が真で値が有限のときだけ飽和を計算します。既定値では `y = Vap` のままです。`|V| = 0` のとき `Jacobi_Y` の `d|V|/dV` は 0 とします。
- `get_equilibrium`: `Ifield` の平衡値は `Vfield`。平衡点の検査は `(max(Vap_min, gamma_min|V|), min(Vap_max, gamma_max|V| - k0·Ifield))` で行い、メッセージ `InvalidValueRange` に出力の上下限を書き足しました(新しい ID はありません)。
- `tap = 0` かつ `Limiter`: `0 = -Vap + sat(kap·Vcom; Vap_min, Vap_max)`。`Vap_max = ±Inf` なら今までと同じ式です。

### 7.3 影響の確認 [計測]

| 項目 | 結果 |
|---|---|
| export/import(F70) | medium で PASS。列が欠けた古いフォルダは、コンストラクタの既定値で読み込まれます [事実: import は残りの列を `parameter=` に渡す] |
| AGC(名前で読む) | `agc_trip` の基準は isequaln。medium 全体で PASS |
| `Yall` を使うもの | ありません [事実] |
| Retrofit(F68) | PASS(`Xall` なので影響なし) |
| 出力の並びを固定で調べるテスト | F1(AVR の `iv_obsY`)、F7(発電機の出力名に `Ifield`)、F63(`Limiter` が最後)を更新。F22、F28 は変更なしで PASS |
| クラスページ | 生成物なので、ヘルプ(AVR_ST1、PSS1、3 つの発電機)を直しただけです |

### 7.4 基準データ [計測]

AVR の段の後の `simulate_baseline` の比較:

| 例 | 結果 | 新しい列(`uc` の `Ifield`) | 既存の列 |
|---|---|---|---|
| `ieee68_fault` | DIFFERENT(列の数) | 16(446 → 462 列) | `rv_t`、`rm_I`、既存の列はすべて isequaln |
| `ieee14_trip` | DIFFERENT(列の数) | 2(121 → 123 列) | 同上、isequaln |
| `ieee9_offset` | DIFFERENT | 3(69 → 72 列) | 点の数は同じ(295)。時刻の差は最大 4.1e-7 s、値の差は最大 1.3e-7、`rm_I` の差は最大 1.4e-7(丸めの程度。DAE の変数が増えたため) |
| `ieee68_nolc`、`ieee14_open`、`agc_trip` | isequaln | — | — |

### 7.5 わかった制約 [計測]

- `gen-classical`(界磁回路のないモデル)に有限の `gamma_max` を付けて、地絡で上限に当たると、地絡除去時の初期値の計算が収束しません(3 母線系統の B003 の地絡)。`Vfield` が内部電圧そのものなので、`Vfield = gamma_max|V| − …` と `V` が代数ループになるためと考えます [推測]。上限に当たらなければ動きます(F79)。Q5 の決定どおりエラーにはしていません。

### 7.6 テスト [計測]

- 各段で、関係する分類(model、simulate、linearize。発電機の段からは io も)の small または medium を流しました。
- マージ前の medium(全分類): 930 件、PASS 929、SKIP 1(F4: MATPOWER がパスにない)、FAIL 0(2101 s、R2026a)。
