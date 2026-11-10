# 運転点の求解(initialize の Xconst / Uconst)と Solver への改名

`initialize` に加える Method="Xconst" / "Uconst"(機器の状態または入力を固定した平衡点の求解)と、
全解析でアルゴリズムの選択を Name-Value `Solver` に統一する改名の仕様。

- 決定: 2026-11-10、メンテナー(下の「決定」)。
- 基準コミット: `84e0a421`(`refactor/design-alignment`、手順 A・B のマージ後)。「現状」はこのコミットのコード。
- 状態: 仕様の段階。コードは未変更。実装は別のセッションで行い、その指示書がこのノートを引用する。
- 区別: **決定**(メンテナーの決定)、**現状**(コードで確認済み)、**測定**(MATLAB R2026a で確認)、**提案**(このノートの推奨。未承認)、**未決**(末尾の一覧)。
- 関連: [powerflow-options.md](powerflow-options.md)(`MethodBase`、ウォームスタート、改訂カウンタ。要判断 2 はこのノートの 1 節で解消)。

## 1. 決定事項

**決定**

- `initialize` の Name-Value `Method` は「何を解くか」: `"powerflow"` / `"OPF"` / `"Xconst"` / `"Uconst"` / `"equilibrium"`。
- アルゴリズムの選択はすべての解析で Name-Value `Solver`。
  - `calculate_powerflow` の `Method="newton"` などは `Solver="newton"` に改名。GUILDA.setting の JSON キーも `Method` → `Solver`。
  - `optimize_powerflow` / `simulate` の `Solver` はそのまま。OPF の `Method` は定式化(`"AC OPF"` / `"DC OPF"`。現状は `"ELD"` もある)のまま。
- Xconst: 機器本体の状態 x(`rv_Xequilibrium`)を固定し、u・V・I を解く。
- Uconst: 入力 u(`rv_Uequilibrium`)を固定し、x・V・I を解く。
  - 電力収支のずれは `l_isSlack` 母線の発電機の Pm を自由変数にして吸収。
  - その母線の位相角を基準にする(回転不変性の除去)。
- 対象は機器本体(`Component`)のみ。制御器は方程式に入れず、平衡点が決まった後で制御器に set_equilibrium する(現在の `Component.set_equilibrium` と同じ流れ)。
- 想定 Solver: `"newton"` / `"levenberg-marquardt"` / `"fsolve"`(`MethodBase` 系)。`"gradient"` / `"dynamic"` は対象外。

**この決定で解消する既存の要判断**

- powerflow-options.md 要判断 2(`initialize(Method="powerflow")` で潮流計算の手法を選ぶ手段がない):
  改名後は `net.initialize(Solver="levenberg-marquardt")` がそのまま `calculate_powerflow` に渡る(`take_method` は `Method` だけを取り除く)。
  `Method="OPF"` では同じ `Solver` が `optimize_powerflow` の `Solver`(`"fmincon"` など)になる。

## 2. 機器モデル(現状)

方程式の形はすべて共通(`@Component/Component.m`)。

- 状態方程式 M·dx/dt = `fcn_dx(t, x, V, I, u, param, omega0)`、電流 `fcn_I(...)`(複素数を返す)、出力 `fcn_Y(...)`。
- V = [Vre; Vim]、I = [Ire; Iim](機器が母線へ注入する向き)。`f_*` はパラメータと周波数を束縛したハンドル `@(t,x,V,I,u)`(`set_odefcn`)。
- 平衡点 `get_equilibrium(obj, c_V, c_I, r_P, r_Q)` は母線電圧と注入電流から [x, u] を返す(閉じた式。反復なし)。
  `Component.set_equilibrium` が呼び、`c_Iequilibrium` / `rv_Xequilibrium` / `rv_Uequilibrium` を書き、局所制御器の `get_equilibrium(c_V, u)` と `initialize(true)` を呼ぶ。
- ヤコビアン `f_JacobiDx` / `f_JacobiI` / `f_JacobiY` は常に存在(`Jacobi_dx` などの解析式があればそれ、なければ `@Component/private/Jacobi_*_num.m` の `tools.fd_jacobian`、刻み 1e-5)。
  出力は `[Axx,Bxv,Bxi,Bxu]` / `[Cix,Div,Dii,Diu]`(電流は [Ire; Iim] に対する微分)。

| モデル(キー) | x(nx) | u(nu) | `get_equilibrium` | 方程式の要点 |
|---|---|---|---|---|
| `generator.classical`(`gen-classical`) | δ, ω(2) | Pmech, Vfield(2) | δ = ∠V + atan(P/(Q+V²/Xq))、ω = 0、Pm = P、Vfd = Id·Xd + Vq | dδ = 2πf0·ω、dω = −Dω − Pout + Pm。I は δ、V、Vfd で決まる |
| `generator.one_axis`(`gen-1axis`) | δ, ω, Eq(3) | Pmech, Vfield(2) | δ は atan2、Eq = −(Xd−Xd')Id + Vfd | dEq = −Eq − (Xd−Xd')Id + Vfd |
| `generator.two_axis`(`gen-2axis`) | δ, ω, Eq, Ed(4) | Pmech, Vfield(2) | Ed = (Xq−Xq')Iq | dEd = −Ed + (Xq−Xq')Iq(u を含まない) |
| `generator.park`(`gen-park`) | δ, ω, Eq, Ed, ψq, ψd(6) | Pmech, Vfield(2) | 4×4 の線形方程式 `SE\(...)` | Ed、ψq、ψd の式は u を含まない |
| `generator.droop`(`gen-droop`) | δ(1) | Pmech, Vfield(2) | classical と同じ式(ω なし) | dδ = −Pout + Pm |
| `load.impedance`(`load-impedance`) | なし | R, X(2) | Z = −V/I(`obj.Z` にも保存) | I = −V/Z |
| `load.power`(`load-power`) | なし | Pload, Qload(2) | u = [P; Q](`obj.PQ_st` にも保存) | I = conj((P + jQ)/V) |

- classical / park / two_axis / droop の δ は `atan`(`atan2` でない)。Q + V²/Xq < 0(大きな進相運転)では δ が π ずれる。one_axis だけ `atan2`。
- `+ConstSource/@power`: v1 のインタフェース(`get_dx_constraint`、`get_linear_matrix`)。`key` や `sv_x` などの定数がなく、母線に追加できない(`<@Deprecated>`)。対象外。
- `+load/history/`: 旧インタフェース(`obj.parameter`、`obj.tag`)。キーマップに登録されず、追加できない。対象外。
- `未+GFM`、`未+farm`: 旧インタフェース(`obj.parameter`、`obj.Tag`)。`未` で始まるフォルダはパッケージにならず、パス上にない。対象外。
  移植するときは `Component` の契約(`fcn_dx`、`fcn_I`、`get_equilibrium`)に従えば、Xconst / Uconst は追加の作業なしで扱える(方程式を `f_dx` / `f_I` からしか組み立てないため)。
- 無限大母線: GUILDA に無限大母線の機器はない。`controller.local_LQR` の設計モデルが内部で使うだけ(`V0`)。
  潮流計算のスラック母線は母線の設定(V、Varg)で、機器ではない。Xconst / Uconst ではスラック母線の V の設定は使わない(3 節)。

## 3. 方程式と可解性

### 未知数と方程式

機器 k(母線 b(k))ごとに nx_k + 2 本、母線ごとに 2 本。

- 機器の式: `f_dx(0, x_k, V_b, I_k, u_k) = 0`(nx_k 本)、`[Re; Im] f_I(0, x_k, V_b, I_k, u_k) − I_k = 0`(2 本)。
- 母線の KCL: Y·V − Σ_k I_k = 0(実部・虚部の 2 本。機器のない母線は Σ = 0)。
- Y は `net.get_admittance_matrix`(ブランチと母線のシャント)。

| | 固定 | 未知数 | 方程式 |
|---|---|---|---|
| Xconst | x | Σ(nu_k + 2) + 2·n_bus | Σ(nx_k + 2) + 2·n_bus |
| Uconst | u(スラック母線の発電機の Pm を除く) | Σ(nx_k + 2) + 2·n_bus + 1(Pm) | Σ(nx_k + 2) + 2·n_bus + 1(基準角) |

- Uconst の基準角の式: Im(V_slack·e^(−jθ)) = 0。θ はスラック母線の `tab_parameter.powerflow.Varg`。
- Uconst は回転不変(全 δ と全母線電圧を同じ角度だけ回しても解のまま)なので、基準角の式がないとヤコビアンが 1 だけ階数落ちする。
- Uconst で全 Pm を固定すると、損失を含む電力収支が一般に合わず、ω = 0 の平衡点がない。Pm を 1 つ自由にして吸収する(決定)。
- Xconst では δ を固定するので回転不変性はなく、基準角の式も自由な Pm も要らない(スラック母線の `l_isSlack`、V、Varg は使わない)。

### 測定(`84e0a421`、各系統を `initialize()` した平衡点で、上の方程式の中心差分ヤコビアンの階数)

| 系統(機器) | Uconst 式 / 未知数 / 階数 | Xconst 式 / 未知数 / 階数 | Xconst・負荷の u を固定 |
|---|---|---|---|
| IEEE9bus(one_axis 3、impedance 3) | 40 / 40 / 40 | 39 / 42 / 36 | 39 / 36 / 36 |
| IEEE68bus(one_axis 16、impedance 35) | 287 / 287 / 287 | 286 / 340 / 270 | 286 / 270 / 270 |
| IEEJ_EAST10 既定のケース(park 10、impedance 12) | 199 / 199 / 199 | 198 / 182 / 174 | 198 / 158 / 158 |
| IEEE14bus(park 5、load-power 12) | 93 / 93 / 93 | 92 / 96 / 82 | 92 / 72 / 72 |

- Uconst: 4 系統とも正方でフルランク。平衡点から 1e-2 の乱数で崩した点から最小ノルムのニュートン法で、元の平衡点へ戻った(差 1e-9 以下)。局所的に一意。
- Xconst: 4 系統とも階数落ち(不足と過剰が同時に起こる)。内訳は次の表。
- 測定のスクリプトはリポジトリの外(セッションの作業用フォルダ)で、コミットしていない。

### Xconst のモデルごとの過不足

δ の式 dδ = 2πf0·ω は ω だけの式で、ω = 0 なら恒等式(情報なし)、ω ≠ 0 なら解なし。

| モデル | 実質の状態方程式 | 未知の u | 過不足(機器ごと) |
|---|---|---|---|
| classical | 1(dω で Pm) | 2 | 不足 1(Vfd が決まらない) |
| droop | 1(dδ で Pm) | 2 | 不足 1(Vfd が決まらない) |
| one_axis | 2(dω で Pm、dEq で Vfd) | 2 | 正方 |
| two_axis | 3(+ dEd: u を含まない) | 2 | 過剰 1 |
| park | 5(+ dEd、dψq、dψd: u を含まない) | 2 | 過剰 3 |
| load.impedance / load.power | 0 | 2 | 不足 2(u が何の式にも入らない) |

- 測定の表と一致: IEEE9 / IEEE68 は負荷の u を固定すると列フルランク、式の余り(式 − 階数)は発電機数(δ の恒等式)。EAST10 の余り 40 = park 10 台 × (恒等式 1 + 過剰 3)。
- 過剰の式は x を固定すると V・I への制約になる。保持している平衡点そのものの x なら解があるが、系統や負荷を変えた後では一般に解がない。
- したがって Xconst は「負荷(nx = 0 の機器)の u を固定」しないと決まらず、park / two_axis では x が整合している場合しか解けない(未決 1、2)。

### 特殊な系統

| 場合 | Xconst | Uconst |
|---|---|---|
| スラック母線がない | 不要 | `calculate_powerflow` と同じ選び方(`tools.slack_bus_index`、INFO `GUILDA:PowerNetwork:SlackSelected`)を提案(未決 4) |
| スラック母線に発電機がない(負荷だけ) | 不要 | Pm がないので解けない。求解前にエラー(提案) |
| スラック母線に発電機が複数 | 不要 | 自由にする Pm は 1 台(未決 5) |
| 機器のない母線 | KCL だけ(I = 0)。V は未知数のまま | 同左 |
| 負荷だけの系統 | 電源がなく V = 0 以外の解がない(ヤコビアン特異)。求解前にエラー(提案) | 発電機がないのでエラー |
| 島が複数 | 島ごとに δ を固定した発電機があれば決まる | 島ごとに基準角と自由な Pm が要る。2 つ目以降の島は特異。求解前にエラー(`network_islands` の一覧を使う。未決 4) |
| ブランチも機器もない母線 | V が決まらない(潮流計算の孤立母線と同じ)。エラー | 同左 |
| ω ≠ 0 の x を固定(Xconst) | δ の式が解なし。求解前に検査してエラー(提案) | 対象外(ω は未知数) |

## 4. 解法

**提案**

- 方程式は 3 節の F(z) = 0。z の並び: 機器ごとに [x_k または u_k; I_k]、続いて母線ごとに [Vre; Vim]、Uconst ではその後に Pm。
  直交座標の V は潮流計算の newton と同じ(`@SolverPF/private/power_equation.m`)。
- Method クラス(`MethodBase` 系)に `Fcn` = F、`Jac`、`InitVal` = z0、`ConvTol` = `Tolerance`、`MaxIter`、`Display` を渡して 1 回解く(`SolverPF` の `run_method` と同じ形)。
  - `"newton"`: `MethodNewtonRaphson`。ステップは `J \ F`、特異なら `lsqminnorm`(現状のコード)。長方形の J では `\` が最小二乗のステップになる。
  - `"levenberg-marquardt"`: `MethodLevenbergMarquardt`。(JᵀJ + μI) を解くので長方形の J も扱える。
  - `"fsolve"`: `MethodFsolve`。fsolve の既定 trust-region-dogleg は方程式数 = 未知数が前提。長方形では fsolve が別のアルゴリズムに切り替えるかは未確認。
  - `"gradient"` / `"dynamic"`: 対象外。求解前にエラー(潮流計算専用の方程式形式のため)。
- ヤコビアン: ブロック疎行列として組み立てる。
  - 機器 k の行: `f_JacobiDx` の [Axx (Xconst では使わない), Bxv, Bxi, Bxu]、`f_JacobiI` の [Cix, Div, Dii − I, Diu]。Xconst は u と I の列、Uconst は x と I の列。
  - KCL の行: [Re; Im] に分けた Y と、機器の I の列の −1。
  - Uconst の Pm の列: スラック発電機の dx の行の Bxu の Pmech 列、基準角の行: V_slack の列。
  - `MethodBase.Jac` を空にすると `tools.fd_jacobian`(刻み `Increment`)で全体を数値微分できるが、2·(未知数) 回の F の評価が要る(IEEE68 で 287 未知数)。テストでの比較用にとどめる。
- 収束判定: max|F| ≤ `Tolerance`(`MethodBase` の共通の判定)。
  F は単位の異なる行(dx、電流、KCL)の混在。dδ の行は 2πf0 倍なので ω の許容誤差は実質 `Tolerance`/(2πf0)。
- 初期値(ウォームスタート): 保持している平衡点。x = `rv_Xequilibrium`、u = `rv_Uequilibrium`、I = `c_Iequilibrium`、V = 母線の `c_Vequilibrium`。
  - powerflow が stale でも使う(典型的な用途は「系統を編集した後、x または u を保ったまま新しい平衡点を求める」で、編集前の点がよい初期値になる)。
  - 保持していない機器(一度も initialize していない、追加した直後など)がある場合の扱いは未決 3。
- 設定の既定値: `Tolerance`、`MaxIteration` は GUILDA.setting の PowerFlowCalculation セクション、`Solver` の既定は `"newton"`(未決 6)。
- 受け付ける Name-Value: `Method`、`Solver`、`Tolerance`、`MaxIteration`、`Verbose`、`WarmStart`(と未決 7 の固定値の指定)。他の名前は `GUILDA:resolve_options:UnknownName`。
- 置き場所: `@PowerNetwork/private/` の関数(新しい Solver クラスや `net.solver_*` を増やさない)。
  ウォームスタートの解は機器の平衡点そのものなので、Solver オブジェクトに解を保持する必要がない。
  方程式の組み立てに `SolverODE` の `getODEFunction` / `getODEJacobian` を流用する案もあるが、シナリオ・制御器・オフセットを含むため、専用の関数を推奨。

## 5. 書き戻しと stale の扱い

**現状**(`@PowerNetwork/initialize.m`)

- `take_method` が `Method` を取り除き、残りを解析に渡す。`l_solve` = (Method が `"equilibrium"` 以外) かつ (Method の指定あり、または `sct_stale.powerflow` が空でない)。
- 求解後 `write_powerflow` が各母線の `Bus.set_equilibrium(V, I, P, Q, "rm_PQ", c_PQ)` を呼ぶ(OPF では機器ごとの P、Q を `rm_PQ` で渡す)。
  `Bus.set_equilibrium` は母線の `c_Vequilibrium` を書き、機器ごとに I = conj((P + jQ)/V) を作って `Component.set_equilibrium` を呼ぶ。
- その後、全母線・ブランチの `initialize`、全グローバル制御器の `initialize(true)`、KCL の確認(1e-6)、モデル残差の警告、`sct_stale.powerflow` / `odefcn` を空にする。途中で失敗すると `sct_stale.powerflow` にメッセージを足して再送出。
- `rv_Xequilibrium` / `rv_Uequilibrium` / `c_Iequilibrium` は `SetAccess=protected`。`Component.set_equilibrium` は `Access={?Bus}` で、必ず `get_equilibrium` を呼ぶ。
- 改訂カウンタ `n_revY` / `n_revPF` / `n_revTopology` は編集で増える(`@PowerNetwork/handle_edit.m`)。求解では増えない。`SolverPF` のキャッシュとウォームスタートはこれと照合する。
- `Component.handle_edit`: dynamics の編集で equilibrium と odefcn、Topology(制御器の追加など)で equilibrium が stale。`Component.initialize` は stale な平衡点を「保持した V と I」から `get_equilibrium` で再計算する。

**提案**

- `take_method` の `sr_method` に `"Xconst"`、`"Uconst"` を追加。指定時は常に求解(`"OPF"` と同じ)。
- 書き戻しは `write_powerflow` と同じ経路で、解いた x、u をそのまま書く。
  - `get_equilibrium` で再計算すると、Uconst では同じ点になるはずだが、δ の `atan` の分岐(2 節)と許容誤差の分だけ解とずれる。Xconst では固定した x が書き換わる。
  - そのため `Bus.set_equilibrium` に機器ごとの [x, u] を渡す引数、`Component.set_equilibrium` に `get_equilibrium` を飛ばす引数が要る(新しい引数。未決 8)。
  - 制御器は従来どおり `get_equilibrium(c_V, u)` と `initialize(true)`。Uconst では u が固定なので、AVR・調速機などは参照値(Vref、Pref など)を変えて同じ u を出す。
  - 負荷の `obj.Z` / `obj.PQ_st`(`get_equilibrium` の副作用。参照は説明用だけ)は、飛ばすと古いまま。書き戻しで更新するか、プロパティを廃止するかは実装で決める(参照箇所は `get_equilibrium` だけ)。
- KCL の確認、モデル残差の警告、`sct_stale` の消去は現状のまま(Xconst / Uconst も同じ確認を通る)。
- 改訂カウンタは変えない(求解は編集ではない)。`solver_PF` のウォームスタート(最後の潮流解)も変えない。
- 後の `initialize()`(Method なし): powerflow が stale でなければ Xconst / Uconst の点を保つ。stale なら潮流計算で解き直す(OPF の点と同じ扱い。未決 9)。
- dynamics の編集後の `initialize()`: 現状どおり保持した V、I から `get_equilibrium` で再計算(固定した x / u は保たれない。未決 9)。
- 返り値: `ResultPF`(`calculate_from_equilibrium` と同じ作り、`s_solver` = `"Xconst"` / `"Uconst"`、`options` = struct(Method, Solver, Tolerance))、flag、output(Method クラスの output)。失敗は他の Method と同じくエラーで止め、平衡点と stale の状態を変えない。
- 新しいメッセージ ID の案: `GUILDA:PowerNetwork:InitializeOperatingPointFailed`(未収束、残差)、`InitializeSolver`(gradient / dynamic)、`InitializeNoSlackGenerator`、`InitializeOmegaNotZero`、`InitializeNoFixedValue`(固定値がない機器)。名前は実装の指示書で確定。

## 6. Solver への改名の影響箇所

`git grep -nw Method`(`84e0a421`)から、潮流計算のアルゴリズムの選択に当たるものを抜き出した。
OPF の `Method`(定式化)、`initialize` の `Method`、Method クラスの名前(`MethodBase` など)は変えない。

### コード

| 箇所 | 内容 |
|---|---|
| `@GUILDA/config/DefaultPowerFlowCalculation.json` 2 行 | キー `Method` → `Solver`(Description も) |
| `_GUILDAsystem/_auxiliary/@SolverPF/SolverPF.m` 9〜12、54、63 行 | ヘルプの表と例、`OptionMap` の `"Method", "Method"` → `"Solver", "Solver"` |
| `_GUILDAsystem/_auxiliary/@SolverPF/get_options.m` 22 行 | `sct_options.Method` |
| `_GUILDAsystem/_auxiliary/@SolverPF/private/validate_options.m` 4 行 | `opt.Method` の `mustBeMember` |
| `_GUILDAsystem/_auxiliary/@SolverPF/solve.m` 7、133、146、152、169、190 行 | `sct.Method`、`output.algorithm`、fsolve の `Feature='Method="fsolve" of the power flow'` |
| `_GUILDAsystem/@PowerNetwork/calculate_powerflow.m` 18、30 行 | ヘルプの Name-Value と例 |
| `_GUILDAsystem/@PowerNetwork/initialize.m` 26〜44、69 行 | ヘルプ(「定式化は initialize のオプションではない」の記述を `Solver` が渡ると書き換え)。`take_method` に Xconst / Uconst |
| `_GUILDAsystem/_auxiliary/@ResultPF/Plot.m` 23〜24 行 | 題名の `options.Method` → `options.Solver`(`"equilibrium"` の結果は `options.Method` のまま。両方を見る) |
| `_GUILDAsystem/_auxiliary/@MethodGradient/MethodGradient.m` 10 行、`@MethodNewtonRaphson/MethodNewtonRaphson.m` 4 行 | ヘルプの `Method="gradient"` / `Method="newton"` |
| `_GUILDAsystem/_VersionSupport/v3_powerflow_args.m` 6〜7、65 行 | 位置引数の mode → `Solver=mode` |
| `_GUILDAsystem/_auxiliary/SystemTools/GUILDA/en/Deprecated.xml` 6 行 | `CalculatePowerflowMode` の文 `Method="{0}"` → `Solver="{0}"` |
| `_GUILDAsystem/_auxiliary/SystemTools/GUILDA/en/PowerNetwork.xml` 20 行 | `InitializeMethod`(一覧は `sr_method` から作るので文は変更不要。新しいメッセージを追加) |
| `@GUILDA/config/ListToolbox.json` 5 行 | `Method=\"fsolve\"` → `Solver=\"fsolve\"` |
| `_GUILDAsystem/_VersionSupport/v3_user_config.m` 5〜27 行 | ユーザー設定のキー `Method` → `Solver` の変換を足すか(未決 10) |
| `_GUILDAsystem/+tools/resolve_options.m` 9 行 | ヘルプの例(Method、Solver の両方を挙げている。意味の説明を合わせる) |

- `ResultPF.options` のフィールド名も `Method` → `Solver` になる(`get_options` の構造体をそのまま持つため)。
- `_GUILDAsystem/resources/functionSignatures.json` に `calculate_powerflow` の項目はない(変更不要)。
- 連続潮流計算(`SolverCPF`)はアルゴリズムの選択肢を持たない(修正子は NR 固定)。線形化(`SolverLIN`)の `Algorithm`(`"Kron"` / `"Feedback"` / `"DAE"`)は縮約の方法(未決 11)。

### テスト(`+DebugScript`)

| ファイル | 行 |
|---|---|
| `test_F2_powerflow.m` | 211、224、225、234、243、283、290、292、294、307、415、436、510、514、556、577、580、588、589、604(`Method=` と `res.options.Method`、`GUILDA.config("PowerFlowCalculation","Method")`、v3 の位置引数の確認) |
| `test_F9_environment.m` | 45〜46(`v3_user_config` の変換の期待値) |
| `+helper/user_config.m` | 4〜5(コメントの例) |
| `test_F3_initialize.m` | 285 の `Method="algebraic"` はエラーの確認で変更不要。Xconst / Uconst のテストを追加 |

- `test_F4_opf.m`、`test_F8_utilities.m`、`test_I90`、`test_I92` の `Method` は OPF または initialize のもので変更不要(F4 999 行のコメント「既定の newton」も変更不要)。
- `test_F5_cpf.m` 110 行、`test_F10_api_foundation.m` 82 行は未知の名前の確認で変更不要。

### 文書(`_GUILDAdoc`、`notes`)

| 箇所 | 内容 |
|---|---|
| `developer/api-design.html` 53、79 行 | 呼び出しの図の `Method="newton"` → `Solver="newton"` |
| `developer/api-design.html` 229〜232 行(ルール 7 の表) | `Method` = 何を解くか・定式化、`Solver` = アルゴリズム(数値ソルバー)と定義を書き分け |
| `developer/api-design.html` 252、262 行 | `calculate_powerflow` の Name-Value、`initialize` の Method の一覧 |
| `developer/feature-power-flow.html` 86〜97、350、442、455、634、639、707、760、791 行 | オプションの表、`sct_options` の説明、手法の追加手順(JSON の `options`) |
| `developer/feature-initialize.html` 62、86〜111 行 | Method の表に Xconst / Uconst、「解析の定式化は initialize のオプションではない」を `Solver` の受け渡しに |
| `index.html` 356〜360 行 | 機能表の `Method="newton"` など |
| `database/list_UpdateLog.js` 240、252 行 | 過去の項目。新しい項目を足し、過去の項目には現在の名前を補う(2026-11-04 の ID の扱いと同じ) |
| `developer/class-design.html` 354〜355 行 | initialize の説明(Method の一覧) |
| `notes/v4-migration.md` 379〜384、848〜855、1218 行 | 潮流計算の移行表と Toolbox の説明 |
| `notes/status.md` | 状況の記録 |

- `developer/naming-conventions.html` 255 行(例: Method、Tolerance、MaxIteration)は名前の書き方の例なので変更不要。
- 調査の記録のノート(`get-sys-workflow.md` など)は基準コミットの記録なので本文を変えない(powerflow-options.md 9 節と同じ方針)。

## 7. 未決

| # | 問い | 選択肢 | 推奨 |
|---|---|---|---|
| 1 | Xconst で固定する範囲 | A: 全状態を固定し、過剰な式は最小二乗で解いて残差 ≤ `Tolerance` のときだけ成功。B: 固定する状態を Name-Value で選ぶ(例 δ と Eq)、残りは未知数。C: モデルごとに「u と同数」の状態を自動で選ぶ | A を既定にし、B を後で追加。ただし park / two_axis では A は保持した平衡点と整合する x でしか解けず、用途が狭い(3 節)。Xconst の想定する用途(何を固定して何を変えたいか)をメンテナーに確認したい |
| 2 | Xconst での負荷(nx = 0 の機器)と classical / droop の Vfd | A: nx = 0 の機器の u は固定(Uconst と同じ扱い)、classical / droop はエラー。B: 決まらない u を最小ノルムで決める | A。B は解が一意でなく、結果が初期値に依存する |
| 3 | 平衡点を保持していない機器(初回、追加直後) | A: エラー(先に `initialize()`)。B: 潮流計算と `get_equilibrium` で初期値を作る(書き込まない) | 初期値は B。ただし固定する値(Xconst の x、Uconst の u)がない機器はエラー(未決 7 で指定した場合を除く) |
| 4 | Uconst のスラック母線の自動選択と島 | A: `calculate_powerflow` と同じ自動選択、島が複数ならエラー。B: 島ごとに自動選択 | A。潮流計算も島ごとのスラックを持たない |
| 5 | スラック母線に発電機が複数ある Uconst | A: 1 台(`Bus.set_equilibrium` の残りを取る機器と同じ規則: Q = NaN の最初、なければ 1 番目)の Pm を自由に。B: ΔP を baseMVA の比で配分(未知数 1) | A(既存の規則と同じ) |
| 6 | Xconst / Uconst の設定の既定値 | A: PowerFlowCalculation の `Tolerance` / `MaxIteration`、`Solver` は `"newton"` 固定。B: GUILDA.setting に新しいセクション(例 Initialize) | A。PowerFlowCalculation の `Solver` が gradient / dynamic のことがあるので、`Solver` だけは既定を持たない |
| 7 | 固定する値の与え方(`rv_Xequilibrium` / `rv_Uequilibrium` は `SetAccess=protected`) | A: 保持している値だけ。B: Name-Value(例 `Fixed`)で機器のタグごとの値を与え、与えない機器は保持値。C: プロパティを書き込み可能にして stale を記録 | B。A だけでは「Pm と Vfd を指定して運転点を求める」用途に使えない。C は平衡点を利用者が直接壊せる |
| 8 | 解いた x、u の書き戻し | A: `Bus.set_equilibrium` / `Component.set_equilibrium` に [x, u] を渡す引数を追加(`get_equilibrium` を飛ばす)。B: `get_equilibrium` で再計算して書く | A。新しい引数は指示書で許可が要る |
| 9 | Xconst / Uconst の後の再初期化 | A: 現状どおり(powerflow が stale なら潮流計算、dynamics の編集は V、I から再計算)。B: 最後の Method を記録して同じ Method で解き直す | A(OPF と同じ)。B は状態が増え、利用者に見えにくい |
| 10 | ユーザー設定ファイルの `Method` キー | A: `v3_user_config` で `Method` → `Solver` に変換。B: 変換しない(v4 は未リリースで、リリース版の設定に `Method` はない) | A(1 行で済み、開発版の設定ファイルを壊さない)。v3 の互換ではないのでフックの名前と `COMPAT(v3)` の扱いを確認したい |
| 11 | 線形化の `Algorithm` | A: そのまま(アルゴリズムではなく縮約の方法)。B: `Solver` に改名。C: `Method` に改名(何を作るか) | A。「数値の反復法の選択 = Solver」と定義すれば対象外 |
| 12 | fsolve で方程式数 ≠ 未知数(Xconst の過剰決定) | A: Xconst で長方形なら fsolve をエラー。B: fsolve の `Algorithm` を levenberg-marquardt に切り替える | 未確認(fsolve の挙動を実装で測る)。暫定は A |
