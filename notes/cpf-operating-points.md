# 連続潮流計算の各ステップの運転点 (S1)

ブランチ: `feature/cpf-operating-points`(`refactor/design-alignment` から作成)。
連続潮流計算の拡張(S1: データ、S2: GraphChart・GraphBase・ResultLIN、S3: plot_* とドキュメント)のうち S1 です。

## 行ったこと

- `ResultCPF` に次の公開メンバーを追加しました(承認済みの一覧のみ)。
  - `tab_variable` / `rm_variable`: `ResultODE` と同じ形式。`net.get_variable_map()` の行 x, Vre, Vim, u, uc。`rm_variable` の行 k がステップ k(`rv_lambda` の添字、`r_noseStep` と同じ数え方)。
  - `cm_Icomponent`: 各機器が母線へ注入する電流 [pu]。行は系統順の機器(母線順、母線内は `a_Component` 順)、列はステップ。
  - `sct_network`: 計算時の `struct(net, false)`。
  - `get_point(Step, tab_map)`(`@ResultCPF/get_point.m`): ステップ `Step` の `tab_map` の行の値。`Step` は 1〜`numel(rv_lambda)` の整数で、それ以外は `GUILDA:ResultCPF:PointStep`。行の照合は `ResultODE.get_point` と同じ Kind, Owner, Name, Bus(エラー ID は `GUILDA:ResultCPF:InvalidMap`、`GUILDA:ResultCPF:UnknownVariable`)。ステップ間の補間はしません。
  - `rv_sigmaMin`: 各ステップの潮流ヤコビアン(未知数について、λ の列を除く)の最小特異値。
  - `tab_weakbus`: ノーズでの弱い母線の順位。列は Bus, Participation(最小特異値の右特異ベクトルの |V| 成分、最大 1 に正規化), dVdLambda(ステップ 1 からノーズまでの平均 d|V|/dλ、符号付き。ノーズが最初の点なら NaN)。Participation の降順です。
  - `r_marginP`: [pu] `r_lambdaMax` × 平衡点で LoadBus の機器が消費する有効電力(その母線の発電は差し引く)。
- `SolverCPF.solve` は経路をたどった後に、新しい private 関数 `@SolverCPF/private/operating_points.m` で各ステップの運転点を作り、ResultCPF の新しい引数 `sct_point`(構造体)で渡します。最小特異値と参与率は、各ステップの点を確定した直後に `solve.m` の局所関数 `stability_index` で計算します(Q 切替後はその時点の式で計算)。
- `SolverLIN.point_vector` と `check_point` は変更していません。`{sim, rv_t}` の経路は `sim.get_point(t, tab)` を呼ぶだけなので、`net.get_sys({res, [1 res.r_noseStep]})` はそのまま 2 区間の ResultLIN を返します(区間の時刻 `rv_t` はステップ番号です)。
- F34 の規則(結果クラスの公開 `get_*` は `update_keymap` の一覧に要る)に従い、`@GUILDA/update_keymap.m` の ResultCPF に `get_point` を加え、`GUILDA.update_keymap(Signature=true)` で `functionSignatures.json`(2 か所)を作り直しました。差分は `ResultCPF.get_point` の項目だけです。keymap は変わっていません。
- テスト `+DebugScript/test_F94_cpf_operating_points.m`(分類 cpf, linearize)。6 件のうち 5 件を medium として `test_levels.m` に登録しました。

## 機器への分け方

各ステップ k で、母線の注入 `S_i = V_i conj((Y V)_i)` を `initialize` と同じく `tools.distribute_power` で機器へ分けます。

1. 各機器はまず CPF の式(`pf_equation`)で注入している電力から始めます。`UseInternalState=false` では平衡点の電力で、LoadBus の母線の機器はすべて (1+λ) 倍です(CPF-3 のとおり、負荷だけでなくその母線の全機器)。
2. 系統のスナップショットの母線の `tab_parameter.powerflow` の P と Q(NaN でない Q だけ)をこの電力に置き換えてから `distribute_power(bus, P_i, Q_i)` を呼びます。スラック母線の残りの P は Q = NaN の最初の機器へ、残りの Q は Q = NaN の機器(PV 母線の発電機)へ `"baseMVA"` の比で配ります(`initialize` の既定と同じ)。Limits="Q" で PQ に切り替えた母線も、母線の Q が固定値を含むので、発電機の Q の和は境界の値になります(テストで確認)。
3. `UseInternalState=true` では、すべての式が解かれているので、各機器の `getCompPQ` の電力 × (1+λ) をそのまま使います(配分しません)。
4. 機器の電流 `I_j = conj(S_j / V_i)` から、機器の純粋な `get_equilibrium(V, I, P, Q)` で (x, u) を得ます。`UseInternalState=true` のときは、CPF の状態を持つ機器は x を CPF の状態(`rm_x` の `comp.iv_CPFX` の行)に、u を CPF の式が使う `rv_Uequilibrium` にします(2026-11-19 の決定)。状態を持たない機器(負荷など)は get_equilibrium の u のままです(dx の式がなく、(1+λ) 倍の電力をこの u が表すため)。
5. ローカル制御器は `Component.set_equilibrium` と同じ順(深さ優先、親の後に入れ子)で `get_equilibrium(V, u)`(u は機器の入力)を呼びます。観測している入力(`iv_obsX` / `iv_obsY` が正)は、そのステップの機器の x または `f_Y(0, x, V)` の値で置き換えます(`initialize` の残差の確認と同じ対応)。
6. グローバル制御器の x と uc は平衡点の値のままです(`tab_variable.Equilibrium`)。
7. あるステップで get_equilibrium がエラーになる機器・制御器(AVR の範囲外など)は、そのステップの値を NaN にします。そのステップを `get_sys` に渡すと `GUILDA:SolverLIN:PointNotFinite` で変数名が出ます。

モデルへは書き込みません(呼ぶのは `get_equilibrium`、`f_Y`、および今回の実行で作られた作業データ `f_PQ2Bus` と `iv_CPFX` の読み出しだけです)。ステップ 1 は平衡点と一致します(3 母線、IEEE14 + Limits="Q"、UseInternalState のいずれも差は 1e-14 程度)。途中のステップの線形化は、負荷を (1+λ) 倍した系統で潮流計算と `initialize` をした結果と A 行列の相対差 1e-9 程度(3 母線、ノーズの半分のステップ)で一致し、運転点の差は 2e-7 程度です(差は CPF の Tolerance による)。

## テスト

- small(cpf, linearize, env): 81 件すべて PASS(48 s)。
- medium(cpf, linearize, env): 207 件すべて PASS(221 s)。
- 決定の反映後、small(cpf, linearize): 40 件すべて PASS(31 s)。
- F5 のみ large(solve を変えたため、IEEE14 の経路のテストを確認): 12 件すべて PASS(189 s)。

## 計算時間

IEEE14、LoadBus 6 母線、40 ステップで、CPF 全体 5.1 s のうち `stability_index`(各ステップの数値ヤコビアンと SVD)が約 1.0 s、`operating_points` が約 0.6 s でした(約 3 割の増加)。数値ヤコビアンは修正子の最後の反復のものを使い回せば省けますが、`MethodNewtonRaphson` の中にあるため今回は別に計算しています。

## 決定事項 (2026-11-19、ユーザーの判断)

- **UseInternalState=true の u**: 状態を持つ機器の u は `rv_Uequilibrium`(CPF の式が使う値)にしました。テストで、スラック母線以外の発電機の全行と、スラック母線の発電機の 3 行目以降の dx が各ステップで 1e-6 未満であることを確かめています。スラック母線の発電機の delta, omega は CPF の未知数ではないため、その 2 行(特に動揺方程式)は CPF の式に含まれず、λ とともに 0 からずれます(3 母線、λ = 0.16 で 4e-4)。状態を持たない機器は get_equilibrium の u のままとしました(上の 4.)。
- **UseInternalState=true の機器の電流**: CPF の式は発電機の `getCompPQ` の電力も (1+λ) 倍するので(CPF-3)、`cm_Icomponent` は CPF の式の電流で、`f_I(x, V, u)` の (1+λ) 倍です。母線ごとの和は Y V と一致します。
- **r_marginP**: CPF が実際に (1+λ) 倍する機器の初期の消費 P(発電は差し引く)× `r_lambdaMax` にしました。通常は LoadBus の母線の機器、UseInternalState=true では全母線の機器です。後者では負荷と発電の差、つまり損失の符号を変えた値になり、3 母線では負の値です。テストは両方の場合を確かめています。
- **Q 切替後の配分**: baseMVA の比のまま(変更なし)。
- **pss-retrofit / local_LQR の保存値の読み出し**: この変更では扱いません(別の作業)。

## 未解決の点

1. **`pss-retrofit` と `local_LQR` の get_equilibrium は機器に保存された平衡点を読みます**(`observed_component().rv_Xequilibrium`、`a_Component.rv_Xequilibrium`)。観測している uc はそのステップの機器の x で置き換えますが、Retrofit の状態 hat_x は平衡点の値のままで、ステップ k の機器の x と一致しません。別の作業で扱います。→ `fix/controller-equilibrium-point` で、get_equilibrium の 4 番目の引数 x(その点の機器の状態)から返すようにしました(`notes/controller-equilibrium-point.md`)。
2. 既知のバグ CPF-1(`iv_CPFX` が残る)と CPF-2、CPF-3 は範囲外のため直していません(`notes/dev-pages-code-findings.md`)。UseInternalState=false の実行では `iv_CPFX` を読まないので、CPF-1 の影響は受けません。
3. テスト番号は F94 を使いました(F85、F88 は空いていましたが、他の作業で予約されている可能性があるため避けました)。
4. `ResultCPF.m` の help の r_marginP と u の記述は S3 が更新します(このブランチでは ResultCPF.m を変えていません)。
