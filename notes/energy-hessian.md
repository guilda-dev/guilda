# エネルギー関数のヘッセ行列 (`get_hessian`)

機器の層はブランチ `feature/energy-hessian`(6c2dd8fd で統合)、系統の層 `get_sys(Form="hessian")` と `ResultLIN.Form` はブランチ `feature/linearization-hessian-form` で実装しました(下の「系統の層」)。

参考文献: 西野・小泉・石崎「エネルギー関数の凸性に基づく電力系統の定態安定性判別手法」電気学会 B 部門大会 2025 の 2〜3 章、式 (15)〜(30)。

## 契約

`sct = obj.get_hessian(x, V, u)` を使います。点の既定値は平衡点で、`V = [Vre; Vim]` です。

| フィールド | 大きさ | 意味 |
|---|---|---|
| `Hxx` | n_x × n_x | ∂²U/∂x² |
| `Hxv` | n_x × 2 | ∂²U/∂x∂v |
| `Hvx` | 2 × n_x | ∂w_dev/∂x(エネルギー関数があれば `Hxv.'`) |
| `Hvv` | 2 × 2 | ∂w_dev/∂v |
| `R` | n_x × n_x | dx/dt = −R ∇_x U の R(質量行列の逆を含み、定数) |
| `StateName` | n_x × 1 | 変数表の状態のラベル |
| `PortName` | 2 × 1 | `theta_<母線タグ>`, `V_<母線タグ>`(変数表の `Vre_<母線タグ>` と同じ形) |

- 線形モデルはポート "PI"(v = [θ; V])で、dx/dt = −R (Hxx x + Hxv v)、w_dev = Hvx x + Hvv v です。
- w_dev = ∂U/∂v = −[P; Q/V] です。P, Q は機器が母線へ供給する電力で、母線へ入る向きが正です。符号は論文と同じです(定電力負荷は U = −Pθ − Q log V、式 (19)、(27))。
- 入力 u は点の定数として扱い、そのヤコビアンはこの形式に含めません。
- 各ブロックは平衡点に限らず、どの点でも厳密です。R が定数で、状態方程式が E dx = −R̃ ∇_x U + (u の定数項) の形をしているからです(R = E⁻¹R̃)。
- 基底(`Component`、`LocalController`、`GlobalController`)は `GUILDA:<層>:HessianNotSupported` で停止し、メッセージにクラス名を示します。メッセージは理由 `{1}` を受け取り、基底では "the class does not override get_hessian" です。
- 旧契約(静的メソッド `Hessian_dx` / `Hessian_I` / `Hessian_Y` による 2 階微分テンソル、`HessianSize`)は削除しました。`+DebugScript/+helper/HessianStub.m` も削除しました。キー `test-hessian-stub` は一覧に出なくなります。

## 実装したクラス

| クラス | U(定数項と u の 1 次の項を除く) | R̃(E dx = −R̃∇U) | 出典 |
|---|---|---|---|
| `generator.classical` | ω_sMω²/2 + (V_field − V_q)²/(2X_d) + V_d²/(2X_q) | [0 −1/M; 1 D/(ω_sM)] | 式 (17)(VSG) |
| `generator.one_axis` | ω_sMω²/2 + E_q²/(2(X_d−X_d')) + (E_q−V_q)²/(2X_d') + V_d²/(2X_q) | 上 ⊕ (X_d−X_d') | 式 (16) |
| `generator.two_axis` | ω_sMω²/2 + E_q²/(2(X_d−X_d')) + E_d²/(2(X_q−X_q')) + (E_q−V_q)²/(2X_d') + (V_d−E_d)²/(2X_q') | 上 ⊕ (X_d−X_d') ⊕ (X_q−X_q') | 式 (15) |
| `generator.park` | 下の導出 | 上 ⊕ (X_d−X_d') ⊕ (X_q−X_q') ⊕ c_q ⊕ c_d | 自分で導出 |
| `load.power` | −Pθ − Q log V | (状態なし) | 式 (19)、(27) |
| `load.impedance` | 無効電力の部分だけ B V²/2。有効電力はポートの収支のヤコビアン | (状態なし) | 自分で導出 |
| `controller.governor.Static`、`controller.avr.Static` | 空のブロック(状態なし、電流なし) | — | — |

- ω_s = 2π f₀、V_q = V cos(δ−θ)、V_d = V sin(δ−θ) です。
- 対応しないクラス: `generator.droop`(同期機ではありません)、ほかの制御器、すべてのグローバル制御器。
- 4 つの発電機は共通の補助関数 `component.generator.abstract.energy_hessian_dq`(protected static)を使います。ブロックと名前への分割は `Component.pack_hessian`(protected)です。
- R は論文の式 (29) と状態の順が違います(論文は (ω, δ, …)、GUILDA は (δ, ω, …))。順を合わせると振動方程式の 2×2 は論文と同じです。界磁の項は、論文が τ'/(X−X') と書いているのに対し、GUILDA のモデルからは (X−X')/τ' になります。数値の照合では後者が正しいです。

### park の導出

E_q'' = a_d E_q + b_d ψ_d、E_d'' = a_q E_d − b_q ψ_q とします。a = (X''−X_ls)/(X'−X_ls)、b = (X'−X'')/(X'−X_ls)(a + b = 1)、c = (X'−X_ls)²/(X'−X'') です。

U = ω_sMω²/2 + E_q²/(2(X_d−X_d')) + (E_q−ψ_d)²/(2c_d) + E_d²/(2(X_q−X_q')) + (E_d+ψ_q)²/(2c_q) + (E_q''−V_q)²/(2X_d'') + (V_d−E_d'')²/(2X_q'') − V_field E_q/(X_d−X_d')

- ∂U/∂δ = V_d I_d + V_q I_q = P です。
- ∂U/∂ψ_d = −(E_q−ψ_d)/c_d + b_d I_d、c_d b_d = X_d'−X_ls から、ψ_d の式の右辺は −c_d ∂U/∂ψ_d です。
- E_q の式の T_d''ψ̇_d の項は b_d/(X_d'−X_ls) = 1/c_d により (E_q−ψ_d)/c_d と (1−a_d) I_d に分かれ、右辺は −(X_d−X_d') ∂U/∂E_q です。q 軸も同じです。
- R̃ は対角(振動方程式の 2×2 を除く)になります。

### 縮退するパラメータ

X = X'(または X' = X'')では、そのフラックスの状態は一方向にしか結合しないため、エネルギー関数がありません。`one_axis`(X_d_p = X_d)、`two_axis`、`park`(4 つの組のどれか)は `HessianNotSupported` で停止し、理由を示します。IEEJ の LGT=4 機(`Xq_p = Xq`、F27)はこれに当たります。

## 照合(F83)

`network.Tutorial10bus` の各機器で照合しました。`get_linear_matrix` のヤコビアンを PI ポートへ変換したものとの相対誤差(最大値で正規化)です。状態の行は E⁻¹[A, B_v T] と比べます(T = ∂[Vre; Vim]/∂[θ; V])。収支の行は −[P; Q/V] の厳密なヤコビアン(I·dV の積の項を含む)と比べます。非平衡点は x + 0.1 randn、|V| ×1.05、θ + 0.2 rad、u ×(1 + 0.1 randn) です。

| クラス | 平衡点 状態 / 収支 | 非平衡点 状態 / 収支 | 非対称 ‖H−Hᵀ‖/‖H‖ | rcond(R) |
|---|---|---|---|---|
| park (B001SG1) | 1.5e-16 / 2.0e-16 | 1.5e-16 / 2.0e-16 | 0 | 1.9e-3 |
| two_axis (B002SG1) | 1.5e-16 / 3.0e-16 | 1.5e-16 / 1.5e-16 | 0 | 1.1e-2 |
| one_axis (B003SG1) | 1.5e-16 / 1.7e-16 | 1.5e-16 / 1.6e-16 | 0 | 3.1e-2 |
| classical (B004SG1) | 1.5e-16 / 2.6e-16 | 1.5e-16 / 3.6e-16 | 0 | 1.0 |
| power (B008LPQ1) | — / 1.4e-15 | — / 1.1e-15 | 0 | (状態なし) |
| impedance (B007, B009, B010) | — / ≤1.2e-16 | — / ≤2.2e-16 | 1.39〜1.40 | (状態なし) |

- 許容値は 1e-8(相対)で、すべて丸め誤差の水準です。
- R は実装した 4 つの発電機ですべて正則です(det R̃ の振動方程式部分 = 1/M、ほかは X−X' > 0、c > 0)。
- インピーダンス負荷の非対称は Hvv(1,2) − Hvv(2,1) = 2GV(G = R/|Z|²)です。Tutorial10bus では 2.449(B007)、1.969(B009)、0.978(B010)でした。Hvv(2,1) = 0 で、ほぼ抵抗負荷なので、相対的な非対称は √2 に近くなります。

## 系統の層: `ResultLIN.Form` と `get_sys(Form="hessian")`

ブランチ `feature/linearization-hessian-form`。変更したのは `get_sys.m`、`SolverLIN.solve`、`@ResultLIN`(`ResultLIN.m`、`get_ss.m`、`disp_summary.m`)、メッセージ(`ResultLIN.xml`、`PowerSystemModel.xml`)、`functionSignatures.json`(再生成)です。テストは F85(`+DebugScript/test_F85_linearization_hessian_form.m`、カテゴリ linearize)です。

### 公開の追加

- `ResultLIN.Form`: "descriptor"(既定)、"absorbed"、"hessian"。`Type` と同じく A ... OutputName の見え方を切り替えます(キャッシュは Type と Form の組ごと)。既定は get_sys の Form です。
- `get_sys(..., Form=)` と `get_ss(..., Form=)`(get_ss の既定は res.Form)。
- 読み取り専用の `ResultLIN.rv_asymmetry`(断面ごと、hessian の形式がなければ NaN)。`disp_summary` にも "- Energy function: asymmetry ..." の行を出し、Model の行の末尾に Form を加えました。

### 3 つの形式

- **descriptor**: これまでどおりです。E は時定数をもちます。
- **absorbed**: 状態の行に E⁻¹ を掛けます(A と B)。E は状態で単位行列、母線の変数で 0 です。descriptor から作るので、どの結果(機器の層のポートモデルも)でも使えます。時定数 0 の状態(IEEE9bus の AVR_ST1 など、E の行が 0)はその行を残し、E も 0 のままです。E の 0 でない行のブロックが正則でないときは `GUILDA:ResultLIN:SingularE` です。
- **hessian**: `net.get_sys(Form="hessian")` だけが作ります。get_sys が各断面の点で、各機器と局所制御器と大域制御器の `get_hessian` を `get_linear_matrix` と同じ値で呼び、`SolverLIN.solve` が組み立てます(ブロックの `sct_hessian` フィールドと `sct_port.cv_V` で渡し、`sct_sys.sct_hessian` に H、R、r_asymmetry を返します)。descriptor のデータも残すので、`res.Form = "descriptor"` で戻せます。

### 符号の規約(hessian)

z = [x; θ_1..θ_n; V_1..V_n](ポート PI、母線は tab_bus の順、状態は get_ss と同じく大域制御器が先)で

```
E_h dz/dt = H z + B_h u,   E_h = −blkdiag(R⁻¹, 0),   H = [Ĥxx  Ĥxv; Hvx  Ĥvv + Ȟvv]
```

- 状態の行は −R⁻¹ dx/dt = Ĥxx x + Ĥxv v、つまり dx/dt = −R(Ĥxx x + Ĥxv v) で、論文の式 (21)〜(30) と同じです。
- 母線の行は 0 = Hvx x + (Ĥvv + Ȟvv) v です。w = Σ w_dev + w_net、w_dev = ∂U/∂v = −[P; Q/V](機器が母線へ供給する電力)、w_net = [P; Q/V](母線から送電線と分路へ出る電力 S = V conj(YV))です。Ȟvv は w_net の [θ; V] についての厳密なヤコビアンです(MATPOWER の dSbus_dV と同じ式に Q/V の微分 −Q/V² を加えたもの)。
- 損失がなければ w_net は U_net = −½ Σ B_ij V_i V_j cos(θ_i − θ_j) の勾配で、H 全体がエネルギー関数のヘッセ行列(対称)になります。H が対称になるのはこの符号の組み合わせのときだけで、IEEE14bus_lossless で確かめました(下の表)。
- PQ は PI から ρ = log V、dV = V dρ、dQ = V d(Q/V) で導きます(H → T H T、T = diag(1, …, 1, V_1, …, V_n)、E_h はそのまま)。合同変換なので対称性は保たれます。項 (Q/V) dV は収支が成り立つ点で消えます。
- B_h は descriptor の B の状態の行に E_h E⁻¹ を掛け、母線の行はそのままにしたものです。C と D は descriptor と同じです(変数が同じなので)。入力 u はエネルギー関数では点の定数で、B_h は descriptor と同じ伝達関数を保つためだけのものです。
- Type "ODE" は H の母線の変数を消去します(E = −R⁻¹、A = Ĥxx − Ĥxv(Ĥvv+Ȟvv)⁻¹Hvx)。
- I·dV の項: 機器ごとの Hvv と網の Ȟvv はどちらも積の微分の項を含みます。母線での和は (I_net − Σ I_dev)·dV で、収支が成り立つ点(平衡点、シミュレーションの点)では 0 です。このため hessian の J は descriptor の PI ポートの DAE の行に E_h E⁻¹ を掛けたものと一致します。収支が成り立たない任意の点の行列を与えると、hessian は [P; Q/V] の収支の厳密なヤコビアンで、descriptor の port_filter(点の電圧で行を変換するだけ)とは収支の残差の分だけ違います。

### 非対称の尺度 `rv_asymmetry`

‖H_b − H_bᵀ‖_F / ‖H_b‖_F、H_b = Ĥvv + Ȟvv(母線のブロック、PI)です。Ĥxx は対称、Hvx = Ĥxvᵀ(エネルギー関数をもつ機器)なので、損失は母線のブロックにだけ現れます。H 全体で測ると ω_s M の大きな成分に埋もれて小さく出る(Tutorial10bus で 4.0e-4)ので、母線のブロックにしました。

### エラー

| 場合 | ID |
|---|---|
| get_hessian をもたない機器・制御器 | `GUILDA:Component:HessianNotSupported`、`GUILDA:LocalController:HessianNotSupported`、`GUILDA:GlobalController:HessianNotSupported`(各クラスの get_hessian のまま) |
| `get_sys(Form="hessian", Port="I")` | `GUILDA:PowerSystemModel:HessianPort` |
| 網以外の層の `get_sys(Form="hessian")` | `GUILDA:PowerSystemModel:HessianNetworkOnly` |
| `get_ss("DAE", Form="hessian", Port="I")` | `GUILDA:ResultLIN:HessianPort` |
| hessian のない結果で `Form="hessian"`(get_ss、`res.Form =`) | `GUILDA:ResultLIN:NoHessianForm` |
| ポートモデルで `get_ss(Form="hessian")` | `GUILDA:ResultLIN:NetworkOnly` |

Static の制御器(状態なし)は空のブロックを返すので止まりません。

### 測定(F85)

Tutorial10bus はそのままでは hessian にできません(AVR_DC1/ST1、IEEJ 調速機、local_LQR、PSS、droop 機、AGC)。F85 は、制御器を `avr-static`/`gov-static` に替え、AGC を外し、droop 機 B005SG1 を `gen-classical` に替えた網を使います(Tutorial10bus のクラスは変更していません)。状態 17、母線 10。

| 項目 | 値 |
|---|---|
| hessian と descriptor の DAE の行(E_h E⁻¹ 倍)の差、平衡点、PI | 2.1e-13(最大値で正規化) |
| 同、PQ | 2.1e-13 |
| 状態の行 −R[Ĥxx Ĥxv] と E⁻¹[Axx Axv] | 1.5e-16 |
| ODE の E⁻¹A の差 | 4.4e-11(相対) |
| 時間断面(B002SG1 の δ に 0.3 rad を与えた応答、t = 0.3, 0.8, 1.2、PQ) | 1.0e-9、8.6e-10、5.7e-11(積分の許容誤差による収支の残差) |
| rv_asymmetry(Tutorial10bus の変形、PI / PQ) | 0.196 / 0.196 |
| 断面ごとの rv_asymmetry(上の時間断面) | 断面ごとに正の値(F85 で確認) |
| H 全体の非対称(参考) | 4.0e-4(Hxx と Hxv−Hvxᵀ はちょうど 0) |
| IEEE14bus_lossless の rv_asymmetry | 1.2e-18 |
| get_sys の時間(Tutorial10bus の変形) | hessian 0.71 s、descriptor 0.37 s |

- 平衡点の 2e-13 は、二つの経路(機器の解析的なヘッセ行列と、descriptor の I 座標から port_filter への変換)の丸めの差です。
- 固有値 −0.0896 は条件数 2.5e5(condeig)で、行列の差 4e-11 が固有値の差 9e-6 になります。F85 は固有値を 1e-4、伝達関数を相対 1e-6 で比べます(s = 0.3 はこの固有値に近い)。

## 後のセッションへの注意

- 機器ごとの w_dev は I·dV の積の項を含みます。`ResultLIN.get_ss` の `port_filter` は点の電圧だけを使い、この項を入れません。母線で Σ I = 0 になるため、和では消えます(上の「符号の規約」)。
- get_hessian のブロックは入力の B 行列(u のヤコビアン)を含みません。`get_sys(Form="hessian")` の B_h は descriptor の B から作ります。Static 以外の制御器が付いた発電機では、制御器側の `get_hessian` が必要です(今は `HessianNotSupported`)。
