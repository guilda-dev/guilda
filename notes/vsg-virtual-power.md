# VSG_classical の動揺方程式を仮想電力 P̃ にする(`feature/vsg-virtual-power`)

ブランチは `feature/vsg-virtual-power` です(未 push、分岐元 `refactor/design-alignment` の `5ed50ac9`)。仕様はユーザーが決めました(2026-11-20)。

**ラベル**: [事実] = コードを読んで確認しました。[計測] = MATLAB R2026a で実行して確認しました。

## 1. 変更の内容

`component.GFMInverter.VSG_classical`(キー `gfm-vsg-classical`)の動揺方程式の電力を、母線へ出す電力から、回す前の古典モデルの電流の仮想電力に替えました。クラス名・キー・パラメータの列(M, D, Xd, Xq, alpha)は変えていません。新しいパラメータ・オプション・クラスもありません。

- 古典モデルの電流: I0 = e^{jδ}(Iq − jId)
- 母線へ流す電流: I = e^{jα} I0(変更なし)
- 動揺方程式: M ω̇ = −D ω − P̃ + Pref、P̃ = Re(V conj(I0)) = cos α · P − sin α · Q
  (以前は P = Re(V conj(I)))
- α = 0 では以前と同じで、古典モデルの発電機と一致します。

平衡点: 潮流計算は今までどおり母線の P, Q を決めます。`get_equilibrium` は δ, Vref を以前と同じに求め、Pref = cos α · P − sin α · Q(= 平衡点の P̃)にします。

変えたファイル(すべて `_GUILDAobject/+component/+GFMInverter/@VSG_classical/`。`@abstract` は変えていません):

| ファイル | 変更 |
|---|---|
| `fcn_dx.m` | 動揺方程式の電力を P̃ に |
| `Jacobi_dx.m` | P̃ の微分(`Jacobi_I` の結果を α だけ戻して使う) |
| `get_equilibrium.m` | Pref = P̃ |
| `get_hessian.m` | 説明のみ(計算は `Jacobi_dx` と `fcn_I` から組むので自動で追従)。状態の行は古典発電機と同じになり Hxx は対称、母線の行は回した電力のヤコビアンのまま |
| `get_spring_node.m` | 矢印の大きさを I0 で計算(仮想リアクタンスを流れる電流、動揺方程式の電流)。`cv_I` は母線電流のまま |
| `VSG_classical.m` | クラスの説明と式 |

`fcn_I`、`Jacobi_I`、`fcn_Y`、`getCompPQ` は変更不要でした [事実](母線電流と母線電力の定義は変わらないため)。

## 2. 理由

NEDO 報告のスライドで、研究室のメンバーの全 IBR 9 母線の多断面 OPF、および Koizumi ら(損失のある系統と位相補償 GFM)の安定性の結果と GUILDA が合わない原因が、動揺方程式の電力でした。論文と研究室の GUILDA の部品 `vsm_lossy` は仮想電力 P̃ を使い、GUILDA の VSG_classical は母線電力を使っていました。すべての線路のインピーダンス角が α のとき、P̃ を使うと回した座標で系統が無損失になり、論文のエネルギー関数の議論が成り立ちます。ユーザーは、新しいクラスやオプションを作らずに VSG_classical をこの形に置き換え、結果が変わることを受け入れると決めました。

## 3. 確認

### 3.1 受け入れ確認 [計測]

| 確認 | 変更前 | 変更後 |
|---|---|---|
| 全 IBR WSCC 9 母線、48 断面の 12:00 の最大実部(0 の固有値を除く) | +0.0048 | +3.6081(研究室の GUILDA・OPF 側の `ReA_max` と同じ) |
| 同、48 断面すべての `ReA_max` との差の最大 | — | 6.9e-8 |
| 同、不安定な断面(実部 > 1e-4)の数 | — | 1(OPF 側も 1) |
| テーマ B(損失と位相補償、(π/6, π/6) 一様)の 568 点で論文のモデルと安定の判定が違う点 | 79 | 0(安定はどちらも 400 点) |

(スクリプトは `_GUILDAslides` の `nedo_uc2_ibr9.m` の `build_ibr9`、`nedo_stability/stab_lossy9.m`・`stab_pcvsg.m` と同じ網・判定をリポジトリの外で実行しました。スライドのリポジトリには何も書いていません。)

### 3.2 テスト

- `test_F98_inverter_components`: 動揺方程式が P̃ であること、平衡点の Pref = cos α P − sin α Q、状態の行が同じパラメータの古典発電機と一致すること、を追加・修正しました。新しいテスト「The Hessian form of lossy VSG networks gives the eigenvalues of get_sys」で、線路に抵抗のある網と、すべての線路のインピーダンス角をそろえた網(α = 0, 0.3)について、`get_sys(Form="hessian")` の E_h dz/dt = H z の固有値と安定の判定が記述子形式・ODE の `get_sys` と一致することを確かめます。
- `test_F83_energy_hessian`: α = 0.3 の VSG を加えました(ヤコビアンとの一致、Hxx が対称で Hvx ≠ Hxv.')。
- medium [計測]: 1110 件中 PASS 1107、SKIP 2、FAIL 1。FAIL は `test_F72`「get_parameter and set_parameter stop with clear errors and write nothing」で、分岐元 `5ed50ac9` でも同じく失敗します(この変更とは無関係)。

### 3.3 基準値

`grep -rl "gfm-vsg-classical\|VSG_classical"` で見つかるのは `test_F22`、`test_F83`、`test_F98` だけで、VSG を使う記録済みの基準(`simulate_baseline` など)や `_GUILDAverification` のファイルはありません [事実]。変わった値はテストの中の 1 つだけです。

- `test_F98`「A rotated VSG and a GFL inverter are at the equilibrium after initialize」(α = 0.3): Pref は母線の P = 0.5 から、cos α · P − sin α · Q = 0.3403(Q = 0.4649)になりました [計測]。δ = 0.2555、Vref = 2.0851 は変わりません(平衡点の電流は同じ)。テストは値を書かず式で確かめます。
