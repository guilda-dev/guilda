# 入力を固定した平衡点(initialize の FixedInput)と Solver / Method の名前の整理

`initialize` に加える Method="FixedInput"(機器の入力 u を固定した平衡点の求解)、利用者による `rv_Uequilibrium` の編集、
全解析でアルゴリズムの選択を Name-Value `Solver` に統一する改名、線形化の `Algorithm` から `Method` への改名の仕様。

- 決定: 2026-11-10、メンテナー(1 節。未決 1〜5 の決定も同日)。
- 基準コミット: `84e0a421`(`refactor/design-alignment`、手順 A・B のマージ後)。「現状」はこのコミットのコード。
- 状態: `feature/fixed-input` で実装(2026-11-10)。記録は末尾の「実装」節。
- 区別: **決定**(メンテナーの決定)、**現状**(コードで確認済み)、**測定**(MATLAB R2026a で確認)、**提案**(このノートの推奨。未承認)、**未決**(末尾の一覧)。
- 関連: [powerflow-options.md](powerflow-options.md)(`MethodBase`、ウォームスタート、改訂カウンタ。要判断 2 はこのノートの 1 節で解消)。
- 経緯: 初版(`8b9bc319`、`notes/operating-point.md`)は Method="Xconst" / "Uconst" の案。Xconst は廃止(7 節)、Uconst は FixedInput に改名。

## 1. 決定事項

**決定**

- `initialize` の Name-Value `Method` は「何を解くか」: `"powerflow"` / `"OPF"` / `"FixedInput"` / `"equilibrium"`。
- アルゴリズムの選択はすべての解析で Name-Value `Solver`。
  - `calculate_powerflow` の `Method="newton"` などは `Solver="newton"` に改名。GUILDA.setting の JSON キーも `Method` → `Solver`。
  - `optimize_powerflow` / `simulate` の `Solver` はそのまま。OPF の `Method` は定式化(`"AC OPF"` / `"DC OPF"` / `"ELD"`)のまま。
  - ユーザー設定ファイルの `Method` キーは変換しない(`v3_user_config` は変えない。リリース版の設定に `Method` キーはない)。
- 線形化の `Algorithm`(`"Kron"` / `"Feedback"` / `"DAE"`)は `Method` に改名(何を作るか。数値の反復法ではない)。影響箇所は 6 節。
- FixedInput: 機器本体の入力 u(`rv_Uequilibrium`)を固定し、状態 x・母線電圧 V・注入電流 I を解く。
  - 電力収支のずれは、`l_isSlack` 母線の 1 台目の発電機の Pm だけを自由変数にして吸収。その母線に発電機がなければエラー。
  - 基準は `l_isSlack` 母線の電圧位相角 θ = 0 に固定(スラック母線の `Varg` の設定は使わない)。
  - スラック母線の自動選択と島の扱いは `calculate_powerflow` と同じ。島が複数ならエラー。
  - 起動時に `rv_Uequilibrium` がセットされていない機器があればエラー。
- 対象は機器本体(`Component`)のみ。制御器は方程式に入れず、平衡点が決まった後で制御器に set_equilibrium する(現在の `Component.set_equilibrium` と同じ流れ)。
- 想定 Solver: `"newton"` / `"levenberg-marquardt"` / `"fsolve"`(`MethodBase` 系)。`"gradient"` / `"dynamic"` は対象外。
- 設定: `Tolerance`・`MaxIteration` は GUILDA.setting の PowerFlowCalculation を流用。`Solver` は流用せず、既定 `"newton"`。
- `rv_Uequilibrium` は利用者が編集可能。編集は `log_edit` に記録され stale になり、解析前のチェックの対象。`rv_Xequilibrium` は利用者が編集できないまま。
  - `rv_Uequilibrium` は `SetAccess=protected` のまま(`Dependent` と内部プロパティの案は不採用)。利用者の編集は新しい公開メソッドで行い、そこで検証と `log_edit` を行う(5 節。名前の提案は `set_input`)。
  - 内部の書き込み(`set_equilibrium`、FixedInput の書き戻し)は従来どおりプロパティへ直接。
- 初期値: x を保持していない機器は、内部の潮流計算と `get_equilibrium` で初期値を作る(モデルには書き込まない)。`WarmStart=false` は保持値があっても常にこの初期値。
- 書き戻し: 解いた x・u をそのまま書く。`Bus.set_equilibrium` / `Component.set_equilibrium` に x・u を渡す新しい引数を加え、`get_equilibrium` を飛ばす。
- 再初期化: FixedInput の後に Method なしの `initialize()`(自動初期化を含む)が走ったら、潮流計算で解き直す。
  ただし stale の原因に利用者の `rv_Uequilibrium` の編集が含まれる場合は、解析前のチェックで自動初期化せずエラーで止め、`initialize(Method="FixedInput")` の実行を促す。
  - u の編集後に明示の `Method="powerflow"` / `"OPF"` で `initialize` したときは求解し、編集した u を潮流解(OPF 解)の値で上書きする。INFO で知らせ、`sct_stale.input` を空にする。
- 線形化の旧名 `Algorithm` は `v3_linearize_args` で `Method` に変換し、`GUILDA:Deprecated:*` を警告(v3 の `get_sys(NonUnit, Algorithm)`、`odeLinearizer` の公開 API のため)。
- 負荷の `obj.Z`(`load.impedance`)/ `obj.PQ_st`(`load.power`)は廃止(u と重複し、参照は `get_equilibrium` の中だけ)。
- Xconst(状態 x を固定して u を解く)は廃止(理由は 7 節)。

**この決定で解消する既存の要判断**

- powerflow-options.md 要判断 2(`initialize(Method="powerflow")` で潮流計算の手法を選ぶ手段がない):
  改名後は `net.initialize(Solver="levenberg-marquardt")` がそのまま `calculate_powerflow` に渡る(`take_method` は `Method` だけを取り除く)。
  `Method="OPF"` では同じ `Solver` が `optimize_powerflow` の `Solver`(`"fmincon"` など)になる。

## 2. 機器モデル(現状)

方程式の形はすべて共通(`@Component/Component.m`)。

- 状態方程式 M·dx/dt = `fcn_dx(t, x, V, I, u, param, omega0)`、電流 `fcn_I(...)`(複素数を返す)、出力 `fcn_Y(...)`。
- V = [Vre; Vim]、I = [Ire; Iim](機器が母線へ注入する向き)。`f_*` はパラメータと周波数を束縛したハンドル `@(t,x,V,I,u)`(`set_odefcn`)。
- 平衡点 `get_equilibrium(obj, c_V, c_I, r_P, r_Q)` は母線電圧と注入電流から [x, u] を返す(閉じた式。反復なし)。
  `Component.set_equilibrium` が呼び、`c_Iequilibrium` / `rv_Xequilibrium` / `rv_Uequilibrium` を書き、ローカル制御器の `get_equilibrium(c_V, u)` と `initialize(true)` を呼ぶ。
- ヤコビアン `f_JacobiDx` / `f_JacobiI` / `f_JacobiY` は常に存在(`Jacobi_dx` などの解析式があればそれ、なければ `@Component/private/Jacobi_*_num.m` の `tools.fd_jacobian`、刻み 1e-5)。
  出力は `[Axx,Bxv,Bxi,Bxu]` / `[Cix,Div,Dii,Diu]`(電流は [Ire; Iim] に対する微分)。

| モデル(キー) | x(nx) | u(nu) | `get_equilibrium` | 方程式の要点 |
|---|---|---|---|---|
| `generator.classical`(`gen-classical`) | δ, ω(2) | Pmech, Vfield(2) | δ = ∠V + atan(P/(Q+V²/Xq))、ω = 0、Pm = P、Vfd = Id·Xd + Vq | dδ = 2πf0·ω、dω = −Dω − Pout + Pm。I は δ、V、Vfd で決まる |
| `generator.one_axis`(`gen-1axis`) | δ, ω, Eq(3) | Pmech, Vfield(2) | δ は atan2、Eq = −(Xd−Xd')Id + Vfd | dEq = −Eq − (Xd−Xd')Id + Vfd |
| `generator.two_axis`(`gen-2axis`) | δ, ω, Eq, Ed(4) | Pmech, Vfield(2) | Ed = (Xq−Xq')Iq | dEd = −Ed + (Xq−Xq')Iq(u を含まない) |
| `generator.park`(`gen-park`) | δ, ω, Eq, Ed, ψq, ψd(6) | Pmech, Vfield(2) | 4×4 の線形方程式 `SE\(...)` | Ed、ψq、ψd の式は u を含まない |
| `generator.droop`(`gen-droop`) | δ(1) | Pmech, Vfield(2) | classical と同じ式(ω なし) | dδ = −Pout + Pm |
| `load.impedance`(`load-impedance`) | なし | R, X(2) | Z = −V/I(現状は `obj.Z` にも保存。廃止) | I = −V/Z |
| `load.power`(`load-power`) | なし | Pload, Qload(2) | u = [P; Q](現状は `obj.PQ_st` にも保存。廃止) | I = conj((P + jQ)/V) |

- 発電機はすべて `sv_u(1) = "Pmech"`。FixedInput で自由にする Pm はこの入力(「発電機」は `component.generator.abstract` のサブクラス)。
- classical / park / two_axis / droop の δ は `atan`(`atan2` でない)。Q + V²/Xq < 0(大きな進相運転)では δ が π ずれる。one_axis だけ `atan2`。解いた x をそのまま書き戻す理由の一つ(5 節)。
- `+ConstSource/@power`: v1 のインタフェース(`get_dx_constraint`、`get_linear_matrix`)。`key` や `sv_x` などの定数がなく、母線に追加できない(`<@Deprecated>`)。対象外。
- `+load/history/`: 旧インタフェース(`obj.parameter`、`obj.tag`)。キーマップに登録されず、追加できない。対象外。
- `未+GFM`、`未+farm`: 旧インタフェース(`obj.parameter`、`obj.Tag`)。`未` で始まるフォルダはパッケージにならず、パス上にない。対象外。
  移植するときは `Component` の契約(`fcn_dx`、`fcn_I`、`get_equilibrium`)に従えば、FixedInput は追加の作業なしで扱える(方程式を `f_dx` / `f_I` からしか組み立てないため)。
- 無限大母線: GUILDA に無限大母線の機器はない。`controller.local_LQR` の設計モデルが内部で使うだけ(`V0`)。
  潮流計算のスラック母線は母線の設定(V、Varg)で、機器ではない。FixedInput ではスラック母線の V、Varg の設定を使わない。

## 3. 方程式と可解性

### 未知数と方程式

機器 k(母線 b(k))ごとに nx_k + 2 本、母線ごとに 2 本、基準角の 1 本。

- 機器の式: `f_dx(0, x_k, V_b, I_k, u_k) = 0`(nx_k 本)、`[Re; Im] f_I(0, x_k, V_b, I_k, u_k) − I_k = 0`(2 本)。
- 母線の KCL: Y·V − Σ_k I_k = 0(実部・虚部の 2 本。機器のない母線は Σ = 0)。Y は `net.get_admittance_matrix`(ブランチと母線のシャント)。
- 基準角: Im(V_slack) = 0(θ = 0)。
- 未知数: Σ(nx_k + 2) + 2·n_bus + 1(スラック母線の 1 台目の発電機の Pm)。方程式も同数。
- 基準角の式が要る理由: 系は回転不変(全 δ と全母線電圧を同じ角度だけ回しても解のまま)で、ないとヤコビアンが 1 だけ階数落ちする。
- 自由な Pm が要る理由: 全 Pm を固定すると、損失を含む電力収支が一般に合わず、ω = 0 の平衡点がない。

**測定**(`84e0a421`、各系統を `initialize()` した平衡点で、上の方程式の中心差分ヤコビアンの階数。基準角は潮流解の位相を使用)

| 系統(機器) | 式 / 未知数 / 階数 |
|---|---|
| IEEE9bus(one_axis 3、impedance 3) | 40 / 40 / 40 |
| IEEE68bus(one_axis 16、impedance 35) | 287 / 287 / 287 |
| IEEJ_EAST10 既定のケース(park 10、impedance 12) | 199 / 199 / 199 |
| IEEE14bus(park 5、load-power 12) | 93 / 93 / 93 |

- 4 系統とも正方でフルランク。平衡点から 1e-2 の乱数で崩した点から最小ノルムのニュートン法で、元の平衡点へ戻った(差 1e-9 以下)。局所的に一意。
- 測定のスクリプトはリポジトリの外(セッションの作業用フォルダ)で、コミットしていない。

### 特殊な系統

**決定**(1 節)と**提案**(エラーの検査の時期)

| 場合 | 扱い |
|---|---|
| スラック母線がない | `calculate_powerflow` と同じ自動選択(`tools.slack_bus_index`、INFO `GUILDA:PowerNetwork:SlackSelected`)。失敗時は `initialize` の潮流計算と同じく解除 |
| スラック母線に発電機がない(負荷だけ) | 求解前にエラー |
| スラック母線に発電機が複数 | 1 台目(`a_Component` の順で最初の発電機)の Pm だけを自由に。他の発電機の Pm は固定 |
| 機器のない母線 | KCL だけ(I = 0)。V は未知数のまま |
| 発電機のない系統 | スラック母線に発電機がないので上と同じエラー |
| 島が複数 | 求解前にエラー(`initialize.m` の `network_islands` の一覧を使う) |
| ブランチも機器もない母線 | V が決まらない(潮流計算の孤立母線と同じ)。求解前にエラー |
| `rv_Uequilibrium` がセットされていない機器 | 起動時にエラー(5 節の「セットされていない」の判定) |

- 現状の `calculate_powerflow` は島を求解前に検査しない(島にスラックがなければ特異で flag -2。`initialize` が `InitializePowerflowIsland` で島を示して止まる)。FixedInput は自由な Pm と基準角が 1 組しかないので、求解前に止める。

## 4. 解法

**提案**

- 方程式は 3 節の F(z) = 0。z の並び: 機器ごとに [x_k; I_k]、続いて母線ごとに [Vre; Vim]、最後に Pm。
  直交座標の V は潮流計算の newton と同じ(`@SolverPF/private/power_equation.m`)。
- Method クラス(`MethodBase` 系)に `Fcn` = F、`Jac`、`InitVal` = z0、`ConvTol` = `Tolerance`、`MaxIter`、`Display` を渡して 1 回解く(`SolverPF` の `run_method` と同じ形)。
  - `"newton"`: `MethodNewtonRaphson`(`J \ F`、特異なら `lsqminnorm`)。
  - `"levenberg-marquardt"`: `MethodLevenbergMarquardt`。
  - `"fsolve"`: `MethodFsolve`(方程式は正方なので既定のアルゴリズムで解ける)。
  - `"gradient"` / `"dynamic"`: 求解前にエラー(潮流計算専用の方程式形式のため)。
  - `MaxIteration` 0(自動)の値は潮流計算と同じ(newton 50、LM 100、fsolve 400)。
- ヤコビアン: ブロック疎行列として組み立てる。
  - 機器 k の行: `f_JacobiDx` の [Axx, Bxv, Bxi]、`f_JacobiI` の [Cix, Div, Dii − 単位行列]。x と I の列、母線 b(k) の V の列。
  - KCL の行: [Re; Im] に分けた Y と、機器の I の列の −1。
  - Pm の列: スラック発電機の dx の行の `Bxu` の Pmech 列(と `Diu` の Pmech 列)。基準角の行: V_slack の虚部の列に 1。
  - `MethodBase.Jac` を空にすると `tools.fd_jacobian`(刻み `Increment`)で全体を数値微分できるが、2·(未知数) 回の F の評価が要る(IEEE68 で 287 未知数)。テストでの比較用にとどめる。
- 収束判定: max|F| ≤ `Tolerance`(`MethodBase` の共通の判定)。
  F は単位の異なる行(dx、電流、KCL)の混在。dδ の行は 2πf0 倍なので ω の許容誤差は実質 `Tolerance`/(2πf0)。
- 初期値(**決定**、`WarmStart=true`): 保持している平衡点。x = `rv_Xequilibrium`、I = `c_Iequilibrium`、V = 母線の `c_Vequilibrium`、Pm は `rv_Uequilibrium` の値。
  - powerflow が stale でも使う(典型的な用途は「系統や u を編集した後、u を保ったまま新しい平衡点を求める」で、編集前の点がよい初期値になる)。
  - x を保持していない機器(一度も initialize していない、追加した直後)は、内部の潮流計算と `get_equilibrium` で初期値を作る。
    潮流計算は `calculate_powerflow` と同じ設定(`Solver` は PowerFlowCalculation のもの)。結果は初期値にだけ使い、母線にも機器にも書き込まない。
    `get_equilibrium` は x、u を返すだけの関数になる(負荷の `obj.Z` / `obj.PQ_st` の廃止で副作用がなくなる)。
  - V、I も、x を保持していない機器のある母線は潮流解の値から始める(提案)。
- `WarmStart=false`(**決定**): 保持値があっても、すべての機器と母線で上の潮流計算と `get_equilibrium` の初期値を使う。内部の潮流計算もフラットスタート(提案)。
- 受け付ける Name-Value: `Method`、`Solver`、`Tolerance`、`MaxIteration`、`Verbose`、`WarmStart`。他の名前は `GUILDA:resolve_options:UnknownName`。
- 置き場所: `@PowerNetwork/private/` の関数(新しい Solver クラスや `net.solver_*` を増やさない)。
  ウォームスタートの解は機器の平衡点そのものなので、Solver オブジェクトに解を保持する必要がない。
  方程式の組み立てに `SolverODE` の `getODEFunction` / `getODEJacobian` を流用する案もあるが、シナリオ・制御器・オフセットを含むため、専用の関数を推奨。

## 5. `rv_Uequilibrium` の編集、書き戻し、stale

### 現状

- `@Component/Component.m`: `rv_Xequilibrium` / `rv_Uequilibrium` / `c_Iequilibrium` は `properties(SetAccess=protected)`、既定 `zeros(0,1)`(`c_Iequilibrium` は `[]`)。
- `Component.set_equilibrium(obj, c_V, c_I, r_P, r_Q)` は `Access={?Bus}`。必ず `get_equilibrium` を呼んで 3 つを書き、`sct_stale.equilibrium` を空にし、ローカル制御器の `get_equilibrium(c_V, u)` と `initialize(true)` を呼ぶ。
- 編集の記録: `LayerPackage.log_edit(obj, log, tag)` が編集した層から最上位まで `handle_edit(a_owner, tag, message)` を呼ぶ。
  - パラメータ表は `Parameter.set.tab_parameter` が列ごとに `log_edit("edit <名前>: <旧> -> <新>", <グループ>)`。母線の `set.l_isSlack` は `"Slack"`。
  - `Component.handle_edit`: `"dynamics"` で equilibrium と odefcn、`"Topology"` で equilibrium が stale。
  - `PowerNetwork.handle_edit`: タグと層の種類で `n_revY` / `n_revPF` / `n_revTopology` と `sct_stale.powerflow` を更新。機器の層では `"powerflow"` だけが対象。
- 解析前のチェック: 自動の初期化はなく、stale なら止まる。
  - `SolverODE.initialize_index`: `net.sct_stale.powerflow`、`odefcn` と各モデルの `equilibrium`、`odefcn` を集めて `GUILDA:SolverODE:Stale`(「Run net.initialize() first.」)。
  - `SolverLIN.solve`(`GUILDA:SolverLIN:Stale`)、`SolverCPF.solve`(`GUILDA:SolverCPF:Stale`)、各層の `get_sys`(`GUILDA:Component:Stale` など)も同様。
- `Component.initialize`: 平衡点が stale なら、保持した V と I から `get_equilibrium` で再計算(u は上書きされる)。

### 編集を stale にする仕組み(決定: 公開メソッド。詳細は提案)

- アクセス(**決定**): `rv_Uequilibrium` は `properties(SetAccess=protected)` のまま。利用者は新しい公開メソッドで編集する。
  内部の書き込み(`Component.set_equilibrium`、FixedInput の書き戻し)は従来どおりプロパティへ直接書き、記録しない。読み出しの費用は変わらない。
- メソッド名(提案): `set_input`。
  - API Design のルール 6 で `set_` はモデルを変えてよい動詞。名前は snake_case の動詞_名詞(naming-conventions、api-design ルール 1)。
  - 既存の `Component.set_equilibrium`(平衡点全体を書く。`Access={?Bus}`)と区別し、入力だけを書くことを名前で示す。
  - 注意: `LocalController` に保護メソッド `set_inputs(obj, sv_name)`(入力名の展開のフック)がある。クラスと役割が違うが、名前が近い。
    紛らわしさを避けるなら `set_input_equilibrium` も候補(メンテナーの確認待ち。指示書で確定)。
- 呼び出しの形(提案): `comp.set_input(rv_u)`。`rv_u` は `sv_u` の順の全要素。
  一部だけ変える場合は `u = comp.rv_Uequilibrium; u(1) = 0.8; comp.set_input(u);`。
  返り値なし(ルール 3 の `[result, flag, output]` は解析のメソッドの規則で、編集のメソッドは `add_*` などと同じく返さない)。
  `Component.m` の `methods` ブロックに宣言、本体は `@Component/set_input.m`(method-files の規則)。`arguments` の (Input) / (Output) ブロック付き。
- 検証(`set_input` の中、提案):
  - double、実数、有限(`mustBeNumeric`、`mustBeReal`、`mustBeFinite`)。列ベクトルに整形。
  - 要素数 = `numel(sv_u)`。違えば `GUILDA:Component:InputSize`(案)。
  - 機器が母線に接続されていない(`a_Bus` が空)ときはエラー(stale を記録する上位の層がない)。
  - 保持値と同じ値なら何もしない(`set.l_isSlack` と同じ)。
- 記録: `log_edit("edit rv_Uequilibrium: <旧> -> <新>", "input")`。新しいタグ `"input"`(`tools.value_text` で値の文字列)。
- `Component.handle_edit`: `"input"` で `sct_stale.equilibrium` に追加(機器の `get_sys` などが止まる)。odefcn は stale にしない(ハンドルは u を束縛しない)。
- `PowerNetwork.handle_edit`: 機器の `"input"` で新しいフィールド `net.sct_stale.input` に追加。`sct_stale.powerflow` には入れない。
  - 改訂カウンタは増やさない(アドミタンス行列も潮流方程式も変わらない。`solver_PF` のキャッシュとウォームスタートはそのまま)。
  - `sct_stale` の既定のフィールドに `input`(空)を加える(コンストラクタ)。
- 解析前のチェック: `SolverODE.initialize_index`、`SolverLIN.solve`、`SolverCPF.solve` などが集めるメッセージに `net.sct_stale.input` を加える。
  `input` が空でなければ、`initialize(Method="FixedInput")` を促す別のメッセージ ID(例 `GUILDA:SolverODE:InputEdited`)で止める。
  自動の初期化を導入するときも、`input` が空でなければ初期化せずに同じエラーにする(1 節の決定)。
- 「セットされていない」の判定(FixedInput の起動時): 要素数が `numel(sv_u)` でない(一度も平衡点を持たない機器は `zeros(0,1)`)。NaN などは `set_input` の検証で入らない。

### 書き戻し(決定と提案)

- `take_method` の `sr_method` に `"FixedInput"` を追加。指定時は常に求解(`"OPF"` と同じ)。
- 書き戻しは `write_powerflow` と同じ経路で、解いた x と u(自由にした Pm を含む)をそのまま書く。
  - `Bus.set_equilibrium` に機器ごとの [x, u] を渡す新しい引数(例 Name-Value `c_XU`、機器ごとの `{x, u}`)。
  - `Component.set_equilibrium` に x、u を渡す新しい引数(例 `rv_X`、`rv_U`)。与えたときは `get_equilibrium` を飛ばし、プロパティへ直接書く。
  - 制御器は従来どおり `get_equilibrium(c_V, u)` と `initialize(true)`。u が固定なので、AVR・調速機などは参照値(Vref、Pref など)を変えて同じ u を出す。
  - 負荷の `obj.Z` / `obj.PQ_st` は廃止(1 節)。`get_equilibrium` を飛ばしても古い値が残らない。
    影響箇所: `_GUILDAobject/+component/+load/@impedance/impedance.m`(プロパティ `Z`)、`@impedance/get_equilibrium.m`、`+load/@power/power.m`(`PQ_st`)、`@power/get_equilibrium.m`(ヘルプ 5、7 行も)。
    `+ConstSource/@power` と `+load/history/` の同名のプロパティは旧インタフェースで対象外。
- 書き戻しの後: 現状のまま、全母線・ブランチの `initialize`、全グローバル制御器の `initialize(true)`、KCL の確認、モデル残差の警告。最後に `sct_stale.powerflow`、`odefcn`、`input` を空にする。
- 改訂カウンタは変えない(求解は編集ではない)。`solver_PF` のウォームスタート(最後の潮流解)も変えない。
- 返り値: `ResultPF`(`calculate_from_equilibrium` と同じ作り、`s_solver` = `"FixedInput"`、`options` = struct(Method, Solver, Tolerance))、flag、output(Method クラスの output)。
  失敗は他の Method と同じくエラーで止め、平衡点と stale の状態を変えない(自動で選んだスラック母線は解除)。

### 再初期化(決定と提案)

- Method なしの `initialize()`:
  - `sct_stale.input` が空で powerflow が stale でなければ、FixedInput の点を保つ(現状の `l_solve` の規則)。
  - `sct_stale.input` が空で powerflow が stale なら、潮流計算で解き直す(1 節の決定。OPF の点と同じ扱い)。
  - `sct_stale.input` が空でなければエラー(例 `GUILDA:PowerNetwork:InitializeInputEdited`)で止め、`initialize(Method="FixedInput")` を促す(利用者の u が `get_equilibrium` の再計算で消えるため)。
- 明示の `initialize(Method="powerflow")` / `"OPF"`(**決定**): `sct_stale.input` が空でなくても求解し、編集した u を潮流解(OPF 解)の値で上書き。
  上書きした機器を INFO(例 `GUILDA:PowerNetwork:InputOverwritten`)で知らせ、`sct_stale.input` を空にする。
- dynamics の編集後の Method なしの `initialize()`: 現状どおり保持した V、I から `get_equilibrium` で再計算(FixedInput で求めた点の u は保たれない)。
- 新しいメッセージ ID の案: `GUILDA:PowerNetwork:InitializeFixedInputFailed`(未収束、残差)、`InitializeFixedInputSolver`(gradient / dynamic)、`InitializeNoSlackGenerator`、`InitializeInputNotSet`、`InitializeInputEdited`、`InputOverwritten`(INFO)、`GUILDA:Component:InputSize`、各 Solver の `InputEdited`。名前は実装の指示書で確定。

## 6. 改名の影響箇所

`git grep -nw Method` / `git grep -nw Algorithm`(`84e0a421`)から抜き出した。
OPF の `Method`(定式化)、`initialize` の `Method`、Method クラスの名前(`MethodBase` など)、
OPF の `Algorithm_linprog` などと `@SolverOPF/optimoption.m` 27〜28 行の `Algorithm`(optimoptions のアルゴリズム)は変えない。

### 潮流計算の Method → Solver: コード

| 箇所 | 内容 |
|---|---|
| `@GUILDA/config/DefaultPowerFlowCalculation.json` 2 行 | キー `Method` → `Solver`(Description も) |
| `_GUILDAsystem/_auxiliary/@SolverPF/SolverPF.m` 9〜12、54、63 行 | ヘルプの表と例、`OptionMap` の `"Method", "Method"` → `"Solver", "Solver"` |
| `_GUILDAsystem/_auxiliary/@SolverPF/get_options.m` 22 行 | `sct_options.Method` |
| `_GUILDAsystem/_auxiliary/@SolverPF/private/validate_options.m` 4 行 | `opt.Method` の `mustBeMember` |
| `_GUILDAsystem/_auxiliary/@SolverPF/solve.m` 7、133、146、152、169、190 行 | `sct.Method`、`output.algorithm`、fsolve の `Feature='Method="fsolve" of the power flow'` |
| `_GUILDAsystem/@PowerNetwork/calculate_powerflow.m` 18、30 行 | ヘルプの Name-Value と例 |
| `_GUILDAsystem/@PowerNetwork/initialize.m` 26〜44、69 行 | ヘルプ(「定式化は initialize のオプションではない」を `Solver` の受け渡しに書き換え)。`take_method` に FixedInput |
| `_GUILDAsystem/_auxiliary/@ResultPF/Plot.m` 23〜24 行 | 題名の `options.Method` → `options.Solver`(`"equilibrium"` / `"FixedInput"` の結果は `options.Method` も持つ。両方を見る) |
| `_GUILDAsystem/_auxiliary/@MethodGradient/MethodGradient.m` 10 行、`@MethodNewtonRaphson/MethodNewtonRaphson.m` 4 行 | ヘルプの `Method="gradient"` / `Method="newton"` |
| `_GUILDAsystem/_VersionSupport/v3_powerflow_args.m` 6〜7、65 行 | 位置引数の mode → `Solver=mode` |
| `_GUILDAsystem/_auxiliary/SystemTools/GUILDA/en/Deprecated.xml` 6 行 | `CalculatePowerflowMode` の文 `Method="{0}"` → `Solver="{0}"` |
| `_GUILDAsystem/_auxiliary/SystemTools/GUILDA/en/PowerNetwork.xml` 20 行 | `InitializeMethod`(一覧は `sr_method` から作るので文は変更不要。新しいメッセージを追加) |
| `@GUILDA/config/ListToolbox.json` 5 行 | `Method=\"fsolve\"` → `Solver=\"fsolve\"` |
| `_GUILDAsystem/+tools/resolve_options.m` 9 行 | ヘルプの例(Method、Solver の両方を挙げている。意味の説明を合わせる) |

- `ResultPF.options` のフィールド名も `Method` → `Solver` になる(`get_options` の構造体をそのまま持つため)。
- `_GUILDAsystem/resources/functionSignatures.json` に `calculate_powerflow` の項目はない(変更不要)。
- `_GUILDAsystem/_VersionSupport/v3_user_config.m` は変えない(1 節)。
- 連続潮流計算(`SolverCPF`)はアルゴリズムの選択肢を持たない(修正子は NR 固定)。

### 潮流計算の Method → Solver: テスト(`+DebugScript`)

| ファイル | 行 |
|---|---|
| `test_F2_powerflow.m` | 211、224、225、234、243、283、290、292、294、307、415、436、510、514、556、577、580、588、589、604(`Method=` と `res.options.Method`、`GUILDA.config("PowerFlowCalculation","Method")`、v3 の位置引数の確認) |
| `test_F9_environment.m` | 45〜46(`v3_user_config` の期待値)。`Method` キーは変換しないので期待値は変わらない。ただし `Method` は設定にないキーになるので、テストの意図(v4 のキーはそのまま通す)を `Solver` で書き直すかは実装で判断 |
| `+helper/user_config.m` | 4〜5(コメントの例) |
| `test_F3_initialize.m` | 285 の `Method="algebraic"` はエラーの確認で変更不要。FixedInput のテストを追加 |

- `test_F4_opf.m`、`test_F8_utilities.m` 439・551、`test_I90`、`test_I92` の `Method` は OPF または initialize のもので変更不要(F4 999 行のコメント「既定の newton」も変更不要)。
- `test_F5_cpf.m` 110 行、`test_F10_api_foundation.m` 82 行(`struct("Method", "Algorithm")` は OptionMap の名前の検査)は未知の名前の確認で変更不要。

### 線形化の Algorithm → Method: コード

| 箇所 | 内容 |
|---|---|
| `_GUILDAsystem/_auxiliary/@SolverLIN/SolverLIN.m` 9、20、29、31、37、48、58 行 | プロパティ `Algorithm`(既定 `"Feedback"`)、`OptionMap` の `"Algorithm", "Algorithm"`、ヘルプと例(`net.solver_LIN.Algorithm = "Kron"`) |
| `_GUILDAsystem/_auxiliary/@SolverLIN/get_options.m` 10、13、18 行 | 設定の構造体 |
| `_GUILDAsystem/_auxiliary/@SolverLIN/private/validate_options.m` 4 行 | `mustBeMember` |
| `_GUILDAsystem/@PowerNetwork/linearize.m` 6、7、22、36 行 | ヘルプの Name-Value と例 |
| `_GUILDAsystem/@PowerNetwork/get_sys.m` 5、6、8、13、25、35、37、74、77 行 | ヘルプ、`Algorithm` の受け渡し |
| `_GUILDAsystem/@PowerNetwork/PowerNetwork.m` 105 行 | `solver_LIN` のコメント(stored defaults: Algorithm) |
| `_GUILDAsystem/_auxiliary/@ResultLIN/get_ss.m` 1、53、72、95、96、98、107、160、161、286、324、330 行 | 位置引数 `get_ss(obj, Algorithm, opt)`、`default_algorithm`、`options.Algorithm` |
| `_GUILDAsystem/_auxiliary/@ResultLIN/ResultLIN.m` 21、23、31、47、67、110、113、121、123、135 行 | ヘルプとプロパティの説明 |
| `_GUILDAsystem/_auxiliary/@ResultLIN/Plot.m` 5、11、22、39、49、51、52 行 | 引数と題名 |
| `_GUILDAsystem/_auxiliary/SystemTools/GUILDA/en/ResultLIN.xml` 5、7、9、10 行 | メッセージ(`SingularAvv`、`StateNotInModel` など)の文中の Algorithm |
| `_GUILDAsystem/_VersionSupport/v3_linearizer_constructor.m` 5 行、`SystemTools/GUILDA/en/v3_linearizer_constructor.xml` 4 行 | v3 の `odeLinearizer(net, NonUnit, Algorithm=...)` の説明 |
| `_GUILDAsystem/_VersionSupport/v3_linearize_args.m`(`SolverLIN.get_options` 15 行から呼ばれる) | 旧名 `Algorithm` → `Method` の変換と警告を追加(1 節)。現状は `NonUnit` だけを扱う |
| `_GUILDAsystem/_VersionSupport/Deprecated.m`、`SystemTools/GUILDA/en/Deprecated.xml` | 新しい ID(例 `GUILDA:Deprecated:LinearizeAlgorithm`)と文 |
| `@PowerNetwork/get_sys.m` | `get_sys` は `linearize` の Name-Value を受け渡すので、`Algorithm=` も同じフックを通るか確認 |

- `ResultLIN.options` のフィールド名も `Algorithm` → `Method` になる。
- `get_ss` の位置引数は名前だけの変更(呼び出し `res.get_ss("Kron")` は変わらない)。

### 線形化の Algorithm → Method: テスト(`+DebugScript`)

| ファイル | 行 |
|---|---|
| `test_F7_linearization.m` | 78 か所(`get_sys("Algorithm", ...)`、`linearize("Algorithm", ...)` など) |
| `test_F8_utilities.m` | 380、554、651、681 |
| `+helper/linearize_v3.m` | 1、9、21 |
| 旧名 `Algorithm` の互換 | `Algorithm=` が警告つきで `Method=` と同じ結果になるテストを追加(`test_F7_linearization.m` か v3 互換のテスト) |
| `Task_linearization.m` | 13、17 |
| `test_I58_input_under_local_controller.m` | 92 |
| `test_F3_edit_handling.m` | 470 |
| `test_F30_governor.m` | 462 |

### 文書(`_GUILDAdoc`、`notes`)

| 箇所 | 内容 |
|---|---|
| `developer/api-design.html` 53、79 行 | 呼び出しの図の `Method="newton"` → `Solver="newton"` |
| `developer/api-design.html` 229〜232 行(ルール 7 の表) | `Method` = 何を解くか・作るか(initialize、OPF、線形化)、`Solver` = アルゴリズム(数値ソルバー)と定義を書き分け |
| `developer/api-design.html` 252、262、302 行 | `calculate_powerflow` の Name-Value、`initialize` の Method の一覧、`linearize` / `get_sys` の `Algorithm` |
| `developer/feature-power-flow.html` 86〜97、350、442、455、634、639、707、760、791 行 | オプションの表、`sct_options` の説明、手法の追加手順(JSON の `options`) |
| `developer/feature-initialize.html` 62、86〜111 行 | Method の表に FixedInput、「解析の定式化は initialize のオプションではない」を `Solver` の受け渡しに、`rv_Uequilibrium` の編集 |
| `developer/feature-linearization.html` 68、86、181、249、436、447、449、496、527、529、549、620 行 | `Algorithm` → `Method` |
| `developer/class-design.html` 354〜355 行と編集の表 | initialize の説明(Method の一覧)、`rv_Uequilibrium` の編集と stale タグ `input` |
| `index.html` 356〜360 行 | 機能表の `Method="newton"` など |
| `database/list_UpdateLog.js` 240、252 行 | 過去の項目。新しい項目を足し、過去の項目には現在の名前を補う(2026-11-04 の ID の扱いと同じ) |
| `notes/v4-migration.md` 379〜384、848〜855、1218 行(潮流計算)、44、711〜720、788〜789 行(線形化) | 移行表と Toolbox の説明 |
| `notes/status.md` | 状況の記録 |

- `developer/naming-conventions.html` 255 行(例: Method、Tolerance、MaxIteration)は名前の書き方の例なので変更不要。
- 調査の記録のノート(`get-sys-workflow.md`、`get-sys-improvements.md`、`get-sys-linearization.md`、`simulate-improvements.md` など)は基準コミットの記録なので本文を変えない(powerflow-options.md 9 節と同じ方針)。

## 7. Xconst の廃止の理由

Xconst(x を固定して u・V・I を解く)の方程式は、機器ごとに未知数 nu + 2、方程式 nx + 2。
δ の式 dδ = 2πf0·ω は ω だけの式で、ω = 0 なら恒等式、ω ≠ 0 なら解なし。

| モデル | 実質の状態方程式 | 過不足(機器ごと) |
|---|---|---|
| classical / droop | 1 | 不足 1(Vfd が決まらない) |
| one_axis | 2 | 正方 |
| two_axis | 3 | 過剰 1(dEd は u を含まない) |
| park | 5 | 過剰 3(dEd、dψq、dψd) |
| 負荷(nx = 0) | 0 | 不足 2(u が何の式にも入らない) |

- **測定**(同じ 4 系統。式 / 未知数 / 階数): IEEE9 39 / 42 / 36、IEEE68 286 / 340 / 270、EAST10 198 / 182 / 174、IEEE14 92 / 96 / 82。負荷の u を固定しても park の系統は 40(= 10 台 × (恒等式 1 + 過剰 3))本の式が余った。
- 不足と過剰が同時に起こり、one_axis と負荷の u の固定の組み合わせ以外では一意に決まらない。park / two_axis では、保持している平衡点と整合する x でしか解けない。

## 8. 未決

なし。

決定済み(2026-11-10、番号は前版の未決): 1 x を保持していない機器の初期値と `WarmStart=false`(1 節、4 節)、2 u 編集後の明示の `Method="powerflow"` / `"OPF"`(1 節、5 節)、
3 線形化の旧名 `Algorithm` の互換(1 節、6 節)、4 `rv_Uequilibrium` の編集は公開メソッド(1 節、5 節)、5 負荷の `obj.Z` / `obj.PQ_st` の廃止(1 節、5 節)。

指示書で確定する名前: `set_input`(または `set_input_equilibrium`)、5 節のメッセージ ID、`Bus.set_equilibrium` / `Component.set_equilibrium` の新しい引数名、`Deprecated` の新しい ID。

## 実装(`feature/fixed-input`、2026-11-10)

**現状**(実装後のコード)

- 改名: 潮流計算の `Method` → `Solver`(JSON キー、`SolverPF.OptionMap`、`get_options`、`validate_options`、`solve`、`ResultPF.options`、`Plot` の題名、
  `v3_powerflow_args`、`Deprecated.xml`、`ListToolbox.json`、ヘルプ、テスト)。`v3_user_config` は変えていない。
  線形化の `Algorithm` → `Method`(`SolverLIN` のプロパティと `OptionMap`、`ResultLIN.get_ss` / `Plot` の引数、`ResultLIN.options`、メッセージ)。
  旧名 `Algorithm=` は `v3_linearize_args` が `Method` に変換し `GUILDA:Deprecated:LinearizeAlgorithm` を警告(1 セッション 1 回)。
- 負荷の `Z` / `PQ_st` を削除。`get_equilibrium` は x、u を返すだけ。
- `Component.set_input(rv_u)`(`@Component/set_input.m`): 実数・有限・要素数 `numel(sv_u)`(`GUILDA:Component:InputSize`)、
  母線への接続(`GUILDA:Component:InputNotConnected`)を検査し、同じ値なら何もしない。
  `log_edit("edit rv_Uequilibrium: <旧> -> <新>", "input")`。
- stale: `Component.handle_edit` は `"input"` で equilibrium、`PowerNetwork.handle_edit` は機器の `"input"` で `sct_stale.input`(新しいフィールド、初期値は空)。改訂カウンタは不変。
- 解析前のチェック: `SolverODE.initialize_index`、`SolverLIN.solve`、`SolverCPF.solve`(`check_network`)、`Bus` / `Component` / `GlobalController` / `LocalController` の `get_sys`、
  `LocalController.validate` が、他の stale より先に `sct_stale.input` を見て `GUILDA:<クラス>:InputEdited` で止まる
  (`msg` は呼び出し元のクラスの ID しか使えないため、クラスごとに ID を持つ)。
- `initialize`: `sct_stale.input` が空でないとき、Method なしと `"equilibrium"` は `GUILDA:PowerNetwork:InputEdited`。
  `"powerflow"` / `"OPF"` は求解して INFO `GUILDA:PowerNetwork:InputOverwritten`。成功時に `sct_stale.input` を空にする。
- FixedInput: `@PowerNetwork/private/solve_fixed_input.m`(方程式、ブロック疎のヤコビアン、初期値、オプション)。
  `initialize.m` の `solve_fixed`(スラック母線の自動選択と失敗時の解除、島の検査、未収束のエラー)と `write_fixed_input`(書き戻し)。
  - 書き戻し: `Bus.set_equilibrium(..., "rm_PQ", rm_PQ, "c_XU", c_XU)`、`Component.set_equilibrium(..., "c_XU", {x, u})`。`c_XU` があれば `get_equilibrium` を呼ばない。
  - 結果: `ResultPF`(`s_solver` = `"FixedInput"`、`options` = Method、Solver、Tolerance、MaxIteration、WarmStart。ブランチの潮流なし)。
  - エラー ID: `InitializeFixedInputFailed`、`InitializeFixedInputSolver`、`InitializeFixedInputIsland`、`InitializeNoSlackGenerator`、`InitializeInputNotSet`(すべて `GUILDA:PowerNetwork:`)。
  - 初期値: `WarmStart=true` で全機器が平衡点を持てば保持値(スラック母線の位相が 0 になるよう全体を回転)。
    それ以外は `calculate_powerflow(WarmStart=...)`(書き込まない)の母線電圧と、機器ごとの P、Q(設定値、Q = NaN の機器に残りを等分、スラック母線の残りの P は 1 台目の発電機)からの `get_equilibrium`。
    4 節の「x のない機器の母線だけ潮流解から」は簡単のため採らず、1 台でも欠ければ全体を潮流解から始める。
- `Solver` の自動の `MaxIteration`(0)は newton 50、levenberg-marquardt 100、fsolve 400。newton の `StepSize` は PowerFlowCalculation の `NewtonStepSize`、fsolve の並列と評価回数も同じセクション。

**仕様との違い**

- ブランチ名: 指示は `feat/fixed-input` だったが、git-workflow の規約(種別 `feature`)に合わせて `feature/fixed-input`。
- `InputEdited` の ID はクラスごと(5 節の例は `SolverODE:InputEdited` だけ)。`Method="equilibrium"` も `InputEdited` で止める(求解しないので、編集した u が `get_equilibrium` の再計算で黙って消えるため)。
- `WarmStart=false` の内部の潮流計算は `WarmStart=false`(フラットスタート)、`true` で x のない機器があるときは `WarmStart=true`。

**測定**(MATLAB R2026a、`initialize()` の後、負荷の入力を `set_input` で変えて `initialize(Method="FixedInput")`。impedance は Z/k、power は PQ·k)

| 系統 | 入力そのまま | 負荷 ×0.95 | ×0.98 | ×0.99 | ×1.002 | ×1.005 | ×1.02 | ×1.05 |
|---|---|---|---|---|---|---|---|---|
| IEEE9bus(one_axis、impedance) | 0 反復 | 5 | 5 | 4 | 3 | 5 | 解なし | 解なし |
| IEEE68bus(one_axis、impedance) | 0 | 5 | – | – | – | 3 | 4 | 解なし |
| IEEJ_EAST10(park、impedance、調速機あり) | 0 | 調速機の上限で停止 | 調速機の上限で停止 | 5 | 4 | 解なし | 解なし | 解なし |
| IEEE14bus(park、load-power) | 0 | 3 | – | – | – | 2 | 3 | 3 |

- 反復は newton(`Tolerance` 1e-8)。1 回 0.03〜0.2 s。「入力そのまま」は母線電圧の差 0(IEEE9 / 68 / EAST10 / 14 とも)。
- 解いた点から外乱なしで 5 s のシミュレーション: 状態の変化は IEEE9 ×0.95 で 1.1e-9、IEEE68 ×0.95 で 2.5e-10、IEEE14 ×0.95 で 5.8e-9。
- levenberg-marquardt / fsolve は解ける場合に newton と同じ点(F3 のテストで 1e-5 以内)。LM は遅い(IEEE68 ×1.02 で 62 反復、×0.95 は 100 反復で未収束)。
  fsolve は以前、IEEE9 ×0.95 で exitflag 1 のまま最大不平衡 1.7e-7 で止まり flag -2 だった(`OptimalityTolerance` が fsolve の既定 1e-6 のため)。
  `FunctionTolerance` と `OptimalityTolerance` に `Tolerance^2` を渡すようにして解消(2026-11-10、powerflow-options.md の「Q3〜Q6 の実装」)。
  `Tolerance` 1e-6 / 1e-8 / 1e-10 とも flag 1、8〜9 反復、不平衡 1e-14 以下。F3 のテストは既定の `Tolerance` と 1e-10 で確認。
- 「解なし」: AVR があっても FixedInput では Vfield が固定され、励磁の制御が効かない。IEEE9 では負荷 ×1.005 付近でヤコビアンの最小特異値が 6e-3 まで下がり(×1.000 で 2.6e-2)、
  ×1.006 付近で平衡点が消える(静的な安定限界)。IEEJ_EAST10 も ×1.004 で解けない。発散ではなく平衡点がない。
- IEEJ_EAST10 では負荷を減らすとスラック発電機の Pm が増える(×0.99 で 5.63 → 5.89)。電圧が上がり定インピーダンス負荷の消費が増えるため(未検証の解釈)。
  ×0.98 以下では、解いた後の調速機(`IEEJ_LPT4`)の `get_equilibrium` がサーボ位置の上限でエラーになる。求解そのものは収束している。
- IEEE68 では負荷を増やすとスラックの Pm が減る(×1.02 で 33.80 → 33.40)。同じく電圧低下による負荷の減少。

**テスト**(`+DebugScript/test_F3_initialize.m`)

- 追加: `FixedInputWithTheHeldInputsKeepsTheEquilibrium`、`set_inputMakesTheInputsStaleUntilFixedInput`、`FixedInputSolvesTheEquilibriumWithTheEditedInputs`、
  `FixedInputGivesTheSamePointWithEverySolver`(large)、`FixedInputKeepsTheInputsUnderLocalControllers`、`PowerflowReplacesTheEditedInputs`、`FixedInputErrorsLeaveTheNetworkUnchanged`。
- F7 に `DeprecatedAlgorithmOptionIsMethod`。F22 の負荷の `Z` の確認は「`Z` プロパティがない」に変更。

**要判断**(実装では決めていない)

1. FixedInput は AVR の Vfield も固定するため、負荷を少し増やすだけで平衡点がなくなる系統がある(上の測定)。
   「制御器の参照値(Vref、Pref)を固定し、制御器を含めて解く」別の Method が要るかは用途次第。
2. 解いた後に制御器の `get_equilibrium` が上下限で失敗すると、従来の `initialize` と同じく `sct_stale.powerflow` に記録して止まり、平衡点は部分的に書き換わったまま(stale)。
   求解前に制御器の上下限を確かめるかは未決。
3. fsolve の `Tolerance` 1e-8 での早期停止 → 解決済み(2026-11-10、`OptimalityTolerance` = `Tolerance^2`)。
