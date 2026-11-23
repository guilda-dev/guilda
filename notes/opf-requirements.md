# OPF requirements

Requirements for optimal power flow (OPF) in GUILDA v4, as decided by the
maintainer on 2026-10-29 and 2026-10-30. Undecided design details are listed at
the end as open questions.

## Uses

- Setting the equilibrium: `initialize` can start from an OPF operating
  point.
- Economic-operation studies.
- Research analysis: duals and nodal prices, sensitivities, Hessians.
- Teaching.

## Problem types and scope

- ELD (economic load dispatch), DC OPF and AC OPF.
- Multi-period OPF, deferred as a possible future extension (not
  scheduled). If added: time series are passed at call time, e.g. as a
  timetable keyed by component tag. Models stay single-snapshot: a
  component describes one operating point, not a time series.
- Out of scope: unit commitment (UC) and security-constrained OPF (SCOPF).
  The CSV columns `OPFcost_startup` / `OPFcost_shutdown` are reserved and not
  used by any problem type.

## Defaults and customization

（2026-11-07 にメンテナーが「案B」として決定。2026-10-30 のオブジェクトごとの
`set_opffcn` は未リリースのまま置き換え）

- 既定: 問題の種類ごとに標準の目的関数・制約・アルゴリズム。
- 問題の構築: 潮流計算と同じ方式（2026-11-12）。`build_opf_problem` が
  `net.get_opf_condition(Display=false)` で母線・機器・ブランチの
  `tab_parameter`（operation / OPF / powerflow / dynamics）から 3 つの表（行名はタグ）、
  `base`（baseMVA、Hz）、解決済みの `ReferenceBus`（`"auto"` → 母線タグ）を集める。
  `SolverOPF.build_problem` / `solve` はこの表とオプションだけを受け取り、系統や
  Bus / Component / Branch のオブジェクトを読まない。問題のキャッシュはなく
  （`PowerNetwork.n_revOPF` も削除）、`net.solver_OPF` はウォームスタートの母線電圧と
  母線タグだけを持つ。`ResultOPF` は `struct(net, false)` と解から作り、系統のハンドルを
  持たない。問題の Description に系統の木（`disp_tree`）は入れない。
- OPF の条件の表示（2026-11-13 に利用者が要望。それまでの「公開の get_opf_condition は
  作らない」を取り消し）: `Bus.get_opf_condition(Display=true)` → `[tab_bus, tab_component]`
  （母線の 1 行とその機器の行。負荷の上下限が両方 Inf なら潮流設定の P/Q に固定した値）、
  `Branch.get_opf_condition(Display=true)` → ブランチの 1 行（From, To, Y, X, tap, phase,
  Pmax, Qmax, Vargmax, Imax, Smax）、`PowerNetwork.get_opf_condition(Display=true)` →
  構造体（`Bus`, `Component`, `Branch`）。ネットワークの表は母線・ブランチの結果を
  積み重ねたもの（`calculate_powerflow` が `Bus.get_pf_condition` を積み重ねるのと同じ）で、
  OPF が使う表そのもの。`Display=true` は見出し Bus / Component / Branch の下に表を表示し、
  表示では `Y` の列を除く（返す表には残す）。出力なしで呼ぶと表示だけ。内部の呼び出し
  （`calculate_optimal_powerflow`、`build_opf_problem`、ネットワークからの Bus / Branch）は
  常に `Display=false`。基準値と `ReferenceBus` の `"auto"` の解決は
  `build_opf_problem` の本体だけに書く（2026-11-14 の分担の整理で、
  `calculate_optimal_powerflow` との重複をなくした）。`opf_data.m`・`opf_setting.m` は削除。
  `calculate_optimal_powerflow.m` にローカル関数はなく、arguments の検証関数
  （`mustBeHandleOrEmpty`、`mustBePositiveIntegerOrNaN`、`mustBePositiveOrNaN`）は
  `@PowerNetwork/private/` に置く。
- OPF 全体のローカル関数の見直し（2026-11-13、利用者の指示「不要に関数を定義しない」）:
  1 か所からしか呼ばれないローカル関数は呼び出し位置に展開した（`get_opf_condition` の
  `empty_tables`・`show`・`group`・`dc_parameters`、`build_problem` の `add_reference`・
  `describe`・`initial_voltage`、`solve` の `format_bus`・`format_branch`・`check_problem`、
  `optimoption` の `check_solver`）。Bus / Branch で重複していた `group` は、公開プロパティ
  `tab_parameter` を直接読むことで不要になった。残したのは、複数箇所から呼ぶもの
  （`apply.m` の `call`、`build_component.m` の `cost_term`。`build_branch.m` の `current` は 2026-11-14 に `branch_flow.m` へ置き換えた）、
  arguments の検証関数（`@PowerNetwork/private/mustBe*`）、独立した長い診断処理の
  `build_opf_problem` の `validate`。非公開ファイル `build_bus`・`build_component`・
  `build_branch`・`apply`・`variables` はローカル関数ではないので今回は分けたまま
  （2026-11-14 に、2 か所から呼ぶ `start_point` と `branch_flow` を追加）。
  Bus / Component / Branch に OPF のメソッドや状態は持たせない。
  - 理由: OPF を使う解析はほかにない。動特性（`f_dx` など）は `simulate` と `get_sys`
    が再利用するため、キャッシュしたハンドルをクラスに保持するのとは事情が異なる。
  - 型による分岐は負荷（`component.load.abstract`）の固定だけ。
- ユーザー定義の項: `net.calculate_optimal_powerflow` / `net.build_opf_problem` の
  Name-Value オプション（ネットワーク全体に適用。PyPSA の `extra_functionality`、
  PowerModels の build-then-modify に相当）。呼び出しだけのオプションで、保存しない
  （2026-11-12。既定は `Cost=[]`、`Constraint=[]`、`DefaultCost=true`、`ReferenceBus="auto"`）。
  オプションはすべて `arguments` ブロックで検証し、未知の名前・不正な値は MATLAB のエラー。
  v3 の形式（6 出力、`"methods"`）と `Export` は廃止（結果は `res.export()` で書く）。
  - `Cost = @(v, p) <スカラーの式>`: 目的関数 `GenCost` に加算。
  - `Constraint = @(v, p) struct(<名前>, <制約>, ...)`: `prob.Constraints.<名前>` と
    して追加。名前が双対変数のラベル（`result.lambda.Constraints.<名前>`）。既存の名前は
    エラー。
  - `v`: タグで全変数を参照（`v.Component.(tag).P/.Q`、`v.Bus.(tag).Varg/.V`、
    `v.Branch.(tag).Pfrom` など）。`p`: `p.Method` と `p.base`。
  - `DefaultCost=false`: 全機器の `tab_parameter.OPF` のコストを除外。
  - `ReferenceBus`: `"auto"`（`tools.slack_bus_index` の母線、なければ最初の母線）、
    母線のタグ、`"none"`（位相角を固定しない）。
  - 単一時点のハンドルはスカラー。多期間 OPF は別のメソッド。
- オブジェクトごとの既定の制約の解除: フラグではなく `tab_parameter.operation` の値を
  ±Inf にする（ブランチの制約値は NaN も制約なし）。上下限がともに無限大の負荷は
  潮流計算の P / Q に固定のまま。母線の需給式は常に残る。
- `operation` グループは OPF 専用ではなく運転制約（2026-11-08 にメンテナーが確認）。
  機器の Pmin/Pmax/Qmin/Qmax、母線の Vmin/Vmax、ブランチの Smax/Imax/Pmax/Qmax/Vargmax
  は、いまは OPF が制約として使うが、今後は時間応答シミュレーションと連続潮流計算でも
  使う予定。OPF 専用は `OPF` グループ（P0、Q0、コスト係数、startup/shutdown）のみ。
  - コメントと開発者ページの説明は「OPF の制約」ではなく「運転制約」と記述（OPF の
    ページでは OPF が制約として使うと記述してよい）。
  - 未決: シミュレーションと連続潮流計算での使い方（制約違反の検出・警告・停止、
    リミッターとして動特性に入れるか、連続潮流計算の終了条件にするか）。
- 3 つの要素の分担（2026-11-14、利用者が「build_opf_problem と calculate_optimal_powerflow の
  分担の境界が薄い」と指摘し、build_opf_problem を残して境界を明確にする案を承認）:
  - `build_opf_problem`: 問題を作るだけ。データ（`get_opf_condition` の 3 つの表、`base`、
    解決後の `ReferenceBus`）を集め、`SolverOPF.build_problem` で `prob` とフラットスタートの
    `x0` を作る。省略できる 3 番目の出力 `sct_data`（`Bus`、`Component`、`Branch`、`base`、
    `ReferenceBus`）を利用者の承認で追加した。出力 0〜2 個の動作は従来どおり。
  - `calculate_optimal_powerflow`: 本体は 3 段。(1) `build_opf_problem` で問題を作る
    （`Problem` を指定したときは `Cost`・`Constraint` を入れずに作り、`x0` と `sct_data` だけを
    使って、問題は指定されたものに置き換える）。`InitialPoint` は `x0` を置き換える。
    (2) `SolverOPF.solve` で解く。(3) `ResultOPF` を作る。`res.options` の `base` と
    `ReferenceBus` は `sct_data` から入れる。
  - `SolverOPF.solve(prob, x0, tab_bus, tab_component, tab_branch, sct_options)`: 作られた
    問題を解くだけで、問題を作り直さない。表は結果の表の行に使う。`Problem` の検査
    （`ProblemMismatch`）は、結果の表が読む変数（母線・機器。2026-11-14 まではブランチ端も）とそのサイズを表から
    確かめる形にした（エラー ID と文言は従来どおり。`msg` は ID のクラスからしか呼べないため
    solve に置く）。
  - ウォームスタートは solve で反映する。`build_problem` はソルバーの状態を読まず、`x0` は
    常にフラットスタート。非公開関数 `start_point`（初期値を母線電圧から設定。
    2026-11-14 の AC OPF の定式化の変更で母線の値だけになった）を `build_problem`（フラットスタート）と `solve`（保持した "AC OPF" の電圧）の
    2 か所から呼ぶ。`InitialPoint` を指定したときは、従来どおりウォームスタートしない
    （calculate が solve に `WarmStart=false` を渡す）。
- AC OPF の定式化（2026-11-14、利用者の指摘「一般的な AC OPF の定式には有効電力・無効電力・
  電圧の位相と振幅しか出てこない。電流をスラック変数として持つ定式は採らない」）:
  - 変数は母線の V と Varg、機器の P と Q だけ（DC OPF は Varg と P、ELD は P）。ブランチ端の
    変数（P、Q、Ireal、Iimag）と定義式 defP_、defQ_、defIre_、defIim_ は削除した。
  - ブランチ端の潮流は非公開関数 `branch_flow` が母線電圧の式で作る（AC: I = −Y·V、
    S = V·conj(I)。2x2 のブランチ Y にタップ・位相・充電容量を含む。DC: MATPOWER の
    b·(θj − θi + phase)）。`build_branch`（最適化の式）と `solve`（解の数値から結果の表）の
    2 か所から呼ぶ。
  - 母線の電力収支 balancedP_<bus>、balancedQ_<bus>: 機器の注入の和 = シャントとブランチ端の
    P_i(V, δ)、Q_i(V, δ)（Y 行列による式と同じ）。
  - ブランチの制約は 5 種類とも残し、式で直接書く: Pmax_<端>（[P; −P] ≤ Pmax。以前は端の変数の
    上下限）、Qmax_<端>（同じ形、AC）、Imax_<端>、Smax_<端>（二乗の形、AC）、VargMax1_/2_<ブランチ>。
    制約値が NaN か Inf ならその制約は作らない。
  - 結果の tab_cub のブランチ端の行と tab_branch は、解の V と δ から計算する。ResultOPF の公開の
    形は変わらない。Cost / Constraint の v.Branch（Pfrom など）は同じ名前で、変数ではなく式になった。
  - lambda の変化: lambda.Constraints から defIre_*、defIim_*、defP_*、defQ_* がなくなり、
    Pmax_*、Qmax_*（2 要素）が加わる。lambda.Variables からブランチ端 <branch>_<bus> がなくなる
    （以前の Pmax・Qmax の乗数はそこの Lower/Upper にあった）。
  - x0 と WarmStart は母線の値だけ（start_point）。変更前との比較（IEEE14 の AC・DC・ELD、
    Smax・Imax・Vargmax・Pmax・Qmax が効くケース、WarmStart、1 母線）では、目的関数値・V・δ・
    機器の P、Q の差は最大 1.5e-4（AC で Pmax が効くケースの目的関数値、相対 2e-8）。
- 変更した問題の求解: `[prob, x0] = net.build_opf_problem(...)` の `prob` を変更し、
  `net.calculate_optimal_powerflow(Problem=prob, InitialPoint=x0)` で求解（呼び出しのみの
  オプション、保存しない）。結果の表は通常どおり。
- OPF のオプションと operation / OPF の編集は平衡点を古くしない。
- 負荷の既定のコストは 0。価格応答する負荷は P の上下限と `Cost` を明示。
- 定数の費用 `c`（2026-11-18 決定・実装）: `tab_parameter.OPF` の列 `c`（既定 0、負荷も 0）、
  `add_component` の Name-Value `OPFcost_c`。機器のコストは `HP·P² + fP·P + HQ·Q² + fQ·Q + c`。
  `DefaultCost=true` のとき ELD・DC OPF・AC OPF の `GenCost` に入り、`false` では入らない。
  最適解は変わらず、`r_cost`（disp_summary、get_summary、sct_iteration.Fval）が Σc だけ増える。
  linprog・quadprog・fmincon とも、問題ベースの fval（fmincon の OutputFcn の fval も）は定数を
  含むことを確かめた（R2026a）。
  - MATPOWER: `import_matpower` は gencost の c0 を換算せずに `c` に読む（Q の行の c0 も `c` に
    足す）。警告 `GUILDA:import_matpower:ConstantCost` は廃止。`tools.network_to_mpc` は `c` を
    P の行の c0 に書く（Q の行の c0 は 0）。負荷の `c` は MATPOWER に書かない。
  - CSV: `opf.csv` の列 `OPFcost_c` はほかの列と同じく必須（ユーザーの判断「必須にして省く」）。
    同梱の系統の opf.csv 30 個には列（値 0）を書き足した。
  - 安定度制約のスラックの重みは c を除いて決める（ユーザーの判断）: r_w = 1000·max(1,
    |最初の OPF の費用 − Σc|)。Σc は DefaultCost=true のときの全機器の c の合計
    （sct_data.Component.c から求める。false なら 0）。c を含めたままだと、IEEE14
    （MinDampingRatio 0.048）で全機器 c = 1000 または 1e4 にしたとき、2 回目の OPF が
    「ソルバーが途中で停止」して flag 0 になった（c = 0 では 4 回で 0.04813）。c を除くと
    c = 1000・1e4 とも c = 0 と同じ結果（4 回、0.04813、c を除いた費用 8566.69）になる。
- DC OPF のブランチのサセプタンスは MATPOWER と同じ `1/(X·tap)`。

## Solvers

- A backend that cannot express a problem stops with an error that lists
  the usable `Solver` names (no silent fallback).

- Default: the MATLAB Optimization Toolbox (`fmincon`, `quadprog`,
  `linprog` through `solve` on the `optimproblem`).
- Later, a `Solver` option switches to external engines:
  - CPLEX and Gurobi, via `prob2struct`;
  - MATPOWER, via conversion of the network to an `mpc` case struct.
- Motivation: lab members doing market research hand-write a script per
  scenario today. GUILDA should build the problem once and hand it to the
  engine they use.

## Priority and verification

- Correctness and verification come first.
- Required: small analytic cases with hand-derivable solutions (balance,
  congestion prices, KKT conditions, duals vs. finite-difference
  sensitivities).
- Optional: comparison with MATPOWER on standard cases. The test reports
  SKIP when MATPOWER (`runopf`) is not on the path.

## Roadmap

1. Correctness of ELD, DC OPF and AC OPF. Done.
2. Customization (`Cost` / `Constraint` / `DefaultCost` / `ReferenceBus` /
   `Problem`), load cost 0, DC susceptance `1/(X·tap)`,
   backend check (`GUILDA:SolverOPF:UnsupportedSolver`). Done.
3. External solver backends. Open.
4. Multi-period OPF. Deferred (possible future extension).

Progress details: [status.md](status.md#opf).

## Open questions

- **Multi-period variables in handles** (only if multi-period OPF is
  taken up). Is a handle called once per period
  with that period's variables, or once with variables that carry a time
  dimension (needed for ramp limits and storage energy balance)? How a
  timetable column is mapped to a handle argument is not decided.
- **Duals and sensitivities API.** How nodal prices, line-limit shadow
  prices and Hessians are exposed on `OPFResult` (names, units, sign
  convention per unit of load).
- **Warm start for `initialize`.** `net.initialize(Method="OPF")` sets the
  equilibrium from an AC OPF point, and a failed OPF stops with
  `GUILDA:PowerNetwork:InitializeOPFFailed` without changing the network
  (decided and implemented). Open: whether the OPF itself should start from
  a power-flow or an earlier OPF point (a power-flow start did not reduce
  iterations, see status.md).

## 中身が見える OPF（2026-11-14）

利用者の要望「OPF の中身はよくわからないが、実行すると結果が得られる」状態に付加価値をつける。
追加した公開メンバーは次のとおり（ほかは追加しない）。

- `SolverOPF.disp_formulation(Method=..., Problem=...)`: Method ごとの一般形（目的関数、制約と
  その名前）を表示する。Problem（`build_opf_problem` の prob など）を渡すと、式ごとに制約の件数
  （上下限は有限の上下限を持つ変数の数）と、ほかの名前の制約の件数を並べる。出力 1 つで文字列を返す。
- `ResultOPF.disp_summary()`: 費用、総発電量、総損失、効いている制約の件数（うちブランチの制約）、
  LMP の範囲。ResultPF.disp_summary と同じ形（出力 1 つで文字列）。
- `ResultOPF.get_summary()`（2026-11-18）: disp_summary が表示する数値を構造体で返す。disp_summary は
  その結果を表示するだけになる。
- `ResultOPF.disp_binding(Kind=["Bound","Branch","Other"])`: 効いている制約の一覧（制約名、
  対象のタグ、値、制限値、乗数）。値が制限値の 1e-4·max(1, |制限値|) 以内なら効いているとみなす。
  ブランチの制約は物理量（端の P・Q・|I|・|S|、From − To の位相差）と、sct_network のブランチの
  operation の制限値で表す。固定値の変数（負荷の P など）と等式は載せない。非線形の制約は
  一般のクラス（OptimizationConstraint）になるので、GUILDA の名前で種類を決め、ほかは
  `expand2str` の "==" で等式を除く。表は private の `binding_table`（disp_binding と
  disp_summary の 2 か所から呼ぶ）が作る。
- `ResultOPF.get_lmp()`: 母線ごとの LMP（−lambda.balancedP、費用/pu）と内訳
  Energy（基準母線の価格）+ Congestion（残り）+ Loss（−Energy·∂Ploss/∂P_i）。AC の損失感度は
  sct_network の母線アドミタンス行列（ブランチの cm_Y とシャント）から作る潮流のヤコビアン
  （基準母線の位相角を固定、無効電力の注入を一定）で求める。内訳は基準母線の選び方で変わる。
  DC は損失分 0、ELD は全母線同じ値。
- `G = ResultOPF.plot_iteration(Parent=...)`: AC OPF の反復の過程。目的関数・制約違反量の最大値
  （対数）・発電機（P の上下限が異なる機器）の P・母線の |V| の 4 つのパネルの GraphChart 1 つ
  （2026-11-23 から。系統図はない。下の「チャート 1 つに」）。ELD・DC OPF は
  GUILDA:ResultOPF:NoIteration。
- 反復の記録: AC OPF（fmincon）では常に、`SolverOPF.solve` の入れ子関数 `record` を fmincon の
  OutputFcn にして、反復ごとに x、目的関数値、制約違反量を記録し、`ResultOPF.sct_iteration`
  （Iteration、Fval、ConstrViolation、X: 変数名ごとに列が反復）に持たせる。PlotFcn と両立し、
  結果は記録しないときとビット単位で同じ（IEEE14 の各ケースで確認）。新しいオプションはない。
- `ResultOPF.sct_network`: ResultPF と同じスナップショット（struct(net, false)）を持たせた
  （利用者が案 A を承認。ResultBase の説明も更新）。
- 実装済み（2026-11-15、GraphNetDiagram の要素ごとの大きさ・太さが入ったあと）:
  - `plot_lmp`: 母線の色 = LMP（BusColorData、ColorMode "user"、カラーバーは最低〜最高価格）。
    ラベルは LabelMode "value" で LMP の値も示す（下の「値のラベル」）。
    disp_binding と同じ判定（binding_table）で効いているブランチを `select` する。ELD・DC・AC で使える。
    戻り値は GraphNetDiagram（plot_diagram と同じ。フェーズ 2a で結果クラスの plot_* が Graph を返す形に
    そろえるとき、ほかと合わせて見直す）。
  - plot_iteration の系統図: tiledlayout を 2×3 にし、3 列目に系統図（axes の Tag "Network"）を置く。
    (a) 母線の |V| を色（色の範囲は V の下限〜上限）、機器の |P| を大きさ、ブランチの |P|（両端の
    平均）を太さで描く。ブランチの潮流はスナップショットの cm_Y から S = V·conj(cm_Y·V)（get_lmp と
    同じ母線の対応 `private/branch_ends.m`）。(b) その反復で変数の上下限、またはブランチの
    operation の制限（|P|、|Q|、|I|、|S|、相差角）を 1e-6 より超えている要素を `select` する。
    反復の切り替えは set_time とベクトルの代入（IEEE14 で 1 回 0.03〜0.05 s）。引数は増やしていない。
  - GraphNetDiagram で足りなかった点（題の上書き、カラーバーの見出し）は、GraphNetDiagram の
    `TitleFormat`・`ColorbarLabel`（2026-11-16 にマージ）で解消した。plot_iteration は
    TitleFormat="" で set_time に題を書かせず、題「violations: n」を反復ごとに書く。カラーバーの
    見出しは ColorbarLabel（plot_lmp は "LMP [cost/pu]"、plot_iteration は "|V| [pu]"）。

- フェーズ 2a（2026-11-16、ユーザー承認）: 結果の plot_* が Graph オブジェクトを返す形に移した。
  - `plot_dispatch` は GraphChart を 1 つ返す（棒の系列: AC は P と Q をまとめた棒（凡例 P、Q）、|V|、
    角度 [deg]。DC は P と角度、ELD は P。棒の要素は機器・母線のタグで、P と Q の棒は同じタグ。題は
    図全体の s_title）。見た目は以前と同じ。
  - `plot_lmp` は今のまま GraphNetDiagram。
  - `[G_chart, G_net] = plot_iteration(...)`: G_chart は 4 パネルの GraphChart（線のタグ "Fval"、
    "ConstrViolation"、発電機、母線。時刻のパネルで、カーソルが表示中の反復）、G_net は系統図。
    両方の時刻を反復番号（sct_iteration.Iteration）にして `G_chart.link(G_net)` で連動させる。
    反復の切り替えは G_chart の再生バー 1 本で行う（2026-11-20 ユーザー決定。下の「再生バー」）。
    G_chart.set_time（link で G_net も動く）と、G_net の色・大きさ・太さのベクトルの代入と選択で反復を
    切り替える。図は左右 2 つの uipanel（左は GraphChart の Parent、右はその中に作った axes を
    GraphNetDiagram の Parent にする）。Name-Value は Parent だけで変わらない。
  - 移行直後に変わった見た目（4 つのグラフが縦 1 列、対数軸の目盛りの数字が減る）は、GraphChart の
    格子（`rv_grid = [2 2]`）で移行前の並びに戻した（2026-11-16）。今の反復の線は GraphChart の
    カーソル（灰色、Tag "TimeCursor"）。
  - 時刻の更新は G_chart の `TimeChangedFcn` に集めた: 題「OPF iteration k (i of n)」（tiledlayout の題）、
    系統図の色・大きさ・太さ・違反の印・題「violations: n」。link で G_net.set_time からも
    呼ばれるので、利用者が set_time を直接呼んでもその反復になる。Parent はコンテナ（figure、uifigure、
    uipanel、uitab。uigridlayout には uipanel を 1 つ挟む）。
  - 再生バー（2026-11-20、ユーザー決定）: 以前の自前の uicontrol（再生ボタン Tag "Play"、スライダー
    Tag "Iteration"）と、そのためのコールバック（move_weak）を削除し、Graph の再生バー 1 本にまとめた。
    反復が 2 つ以上あると、G_chart の 4 パネルの下に再生バー（Play/Pause、スライダー、表示中の時刻、
    速さ）が付く。スライダーと Play（`G_chart.play()`、`G_chart.pause()`、`animate` も同じ）は set_time を
    呼ぶだけで、link により系統図も同じ反復に動く。G_net は右のパネルの axes に描くので、バーは付かない。
    → 2026-11-22 に変更（`feature/ode-side-chart-bar-rule`、OPF の取りまとめの了承）: バーは描く内容が
    時刻で変わる図だけに付く規則（Graph の Q4）になり、カーソルが動くだけの G_chart にはバーがない。
    G_net を `axes(uipanel(...))` ではなく uipanel（容器）に描くようにし、バーは G_net の下の 1 本だけ。
    そのスライダーと Play（`G_net.play()`、`G_chart.play()` も同じ）が link で G_chart のカーソルと題も
    動かす。link と TimeChangedFcn は変えていない。結果の GUI の自動再生は G_net を再生する。
    2 つのパネルは図の高さいっぱい（以前は下の 8% を uicontrol に空けていた）。TimeChangedFcn は弱い
    参照で G_net をたどるので、savefig で警告が出ず、出力を受け取らなくても動く。
    バーの時刻の文字は Graph 側の表記（"t = 18 s"）で、反復番号を秒として表示する。
  - 値のラベル（2026-11-23、ユーザー依頼「LMP をプロットしているときはラベルに LMP を表示」）:
    GraphNetDiagram の値の読み出し（1c229bba。ColorMode "user" で LabelMode "value" のラベルと
    データチップに「<ColorbarLabel>=<値>」の行が付く）を使い、plot_lmp を LabelMode "value" にした。
    新しい公開メンバーはない。
    - `plot_lmp`: c_opt に "LabelMode", "value" を入れ、namedargs2cell(opt) より前に置く（利用者が
      渡した LabelMode が優先。`LabelMode="bus"` でタグだけに戻せる）。母線のラベルは
      タグ、∠V、|V|、「LMP [cost/pu]=<値>」の 4 行。機器のラベルはタグ、P、Q。
    - 確認（IEEE14、DC OPF・AC OPF）: 値は get_lmp と一致。%.4g なので IEEE14 の LMP（約 3900）は
      整数に丸めて表示される（3901.6 → 3902）。全画面の図では読めるが、B009・B010・B011 付近で
      母線のラベルと機器のラベル（P、Q）が一部重なる。方式は変えていない（取りまとめに報告）。
    - plot_iteration はこのブランチでは変えていない（次の項目）。
  - チャート 1 つに（2026-11-23、ユーザー決定の案 A、`refactor/opf-iteration-chart`）:
    plot_iteration は系統図をやめ、`G = plot_iteration(Parent=...)` で GraphChart 1 つを返す。
    - 理由（調査、IEEE14・IEEE14 で EL001 の Pmax=1・IEEE39・IEEE68 の AC OPF）: 系統図の「違反」は
      変数の上下限とブランチの制限だけを数えるが、fmincon（interior-point）は上下限の内側を保つので
      ほぼ常に 0 だった（線の制限を効かせた例で反復 7・13 に EL001 が 1 件だけ）。チャートの最大違反は
      電力のつり合い（balancedP/Q）の違反で、系統図には出ない。|V| の色、P の大きさ・太さは
      チャートと最終の解（disp_binding、disp_summary）以上の情報をほぼ持たなかった。
    - 今の形: 4 パネル（2×2）は時刻のパネルで、時刻は反復番号。set_time でカーソルが動き、
      TimeChangedFcn で題「OPF iteration k (i of n)」を書く（最後の反復から）。カーソルが動くだけ
      なので再生バーはなく、結果の GUI でも自動再生しない。Parent の容器にそのまま描く。
    - 線は tab_element の Tag で特定する。データチップの 1 行目に線の名前（タグ。発電機・母線）が
      出る（Graph 側の feature/chart-datatip-tag、358c6e6d でマージ。2026-11-24 に IEEE14 で確認）。
      凡例は出さない（IEEE68 では 68 本）。
    - 削除: G_net とその計算（diagram_state・branch_ends の呼び出し、違反の判定、大きさ・太さ、
      弱い参照、show_iteration、link）。private の diagram_state（plot_lmp）と branch_ends（get_lmp）は
      まだ使う。新しい公開メンバーはない。
  - 確認で気づいたこと（GraphNetDiagram 側）: getframe や exportapp で図を取り込むと、系統図の母線の
    立体から軸いっぱいの線が出る（変更していない net.plot_diagram でも同じ。exportgraphics では出ない）。

## 安定度制約付き OPF（仕様 2026-11-14・11-15、実装済み 2026-11-16）

GUILDA ならではの付加価値として、同じ系統モデルの動特性（発電機・制御器、get_sys）を使った
小信号安定度（固有値）の制約を OPF に組み込む。過渡安定度は今回は実装しない（最後の節に一言だけ書く）。
2026-11-15 にユーザーの回答（Q1 は系統を書き換えない方式、Q5・Q6・Q9 は指定できるようにする、
ほかは推奨どおり）を受けて改訂した。

### 決まっていること

1. 入口: `calculate_optimal_powerflow` の Name-Value オプションに平たく並べる。新しいメソッドは作らない。
   オプションの一覧は「オプション」の節。既定値は GUILDA.setting の OptimalPowerFlow セクション
   （Default*.json に Valid 条件付きで定義し、option-handling の方針どおり arguments の既定値に
   `GUILDA.config("OptimalPowerFlow", ...)`）。MinDampingRatio と MaxRealPart の既定値は NaN（制約なし）。
   両方 NaN なら今の OPF と同じ動作（結果はビット単位で同じであることを確かめる）。
2. 基準: ζ_min ≥ MinDampingRatio と max Re(λ) ≤ MaxRealPart の両方、またはどちらか一方。
3. 対象: AC OPF だけ。DC OPF・ELD で MinDampingRatio か MaxRealPart を指定したらエラー。
4. 流れ（外側の反復）: OPF を解く → その解から運転点のベクトルを作り get_sys で固有値を求める →
   基準を満たさなければ、危険なモードの固有値の感度から線形化した制約を加えて OPF を解き直す →
   基準を満たすか StabilityMaxIteration に達するまで繰り返す。
5. 感度: 発電機の P・V を少し動かした運転点を作り直し、差分で求める。あとで解析的な感度に
   差し替えられる構成にする。
6. 系統を書き換えない（Q1、2026-11-15 決定）: copy、計算後に元に戻す方式、export・import は使わない。
   運転点は OPF の解から各 Component の `get_equilibrium` で求め、`net.get_sys(rv_point, Type="ODE")`
   で線形化する。差分の運転点も、ネットワークから集めた表を書き換えて SolverPF で解く
   （「運転点の作り方」の節）。
7. 減衰比の制限はすべての振動モードにかける（Q2）。制御器のモードも除かない。
8. 決定変数は発電機の P と発電機母線の V の両方（Q3）。
9. 切断面は最新の線形化で置き換える（Q4）。過去の切断面は積み重ねない。信頼領域と組み合わせる。
10. 結果の公開プロパティは `ResultOPF.sct_stability` の 1 つ（Q7。tab_iteration と tab_mode）。
11. 利用者が変えた問題（Problem）にも切断面を加えて許す（Q8）。母線と機器の変数は必ずある。
12. StabilityMaxIteration に達したときの flag は 0（Q10。MATLAB の「反復の上限」と同じ意味）。
13. 過渡安定度は今回は実装しない。
14. ローカル制御器の平衡点（Q11、2026-11-15 決定）: 抽象メソッドを `[rv_X, rv_U] = get_equilibrium(obj, V, u)`
    （値を返す）に変え、書き込みは Component.set_equilibrium 側に移す。組み込みの制御器 9 個と stub を
    直し、制御器の作り方の説明も新しい契約に合わせる。local_LQR のゲイン K は前の initialize で設計した
    ものを使い、get_equilibrium の中では設計し直さない（設計し直すのは今と同じ initialize のとき）。
    グローバル制御器の get_equilibrium は、保存された機器の平衡点に頼らないことを契約の説明に書く。
15. 2 要素のオプション（Q12、決定）: GUILDA.setting の "double" 型に `"Size"` を足して 2 要素を許す
    （check_setting と設定画面）。既存の設定はスカラーのまま変わらない。オプションは StabilityStep・
    StabilityMargin・StabilityBand の 3 つ（2 要素）。
16. 制御器の入力の平衡点（Q13、決定）: get_sys のベクトルの point に、変数マップの uc の行を続けて渡せる
    ようにする（x、Vre、Vim、u、uc。今の長さも受け付ける）。線形化の担当で実装し、このブランチでは
    get_sys・SolverLIN に触れない。
17. 差分の潮流計算の初期値（Q14、決定）: SolverPF.solve の sct_options に初期電圧の欄を足し、OPF の解の
    電圧から始める。潮流計算の担当で実装し、このブランチでは SolverPF に触れない。
18. component.ConstSource.power（Q15、決定）: get_linear_matrix は P・Q を入力 u から取り、get_equilibrium は
    PQ_st に書き込まない（引数も契約どおり c_V、c_I、r_P、r_Q にする）。

### オプション（Q5・Q6・Q9・Q12、決定）

安定度のオプションはすべて `Stability` で始めるか、基準の名前（MinDampingRatio・MaxRealPart）にする。
数を抑えるため、P と V、または減衰比と実部の組になるものは 2 要素のベクトルにまとめる。

| 名前 | 既定値 | Valid（Default*.json） | 意味 |
|---|---|---|---|
| `MinDampingRatio` | NaN | `isnan(v) \|\| v >= 0 && v < 1` | 振動モードの減衰比 ζ の下限。NaN は制限なし。 |
| `MaxRealPart` | NaN | `isnan(v) \|\| isfinite(v)` | ゼロ以外の固有値の実部の上限 [1/s]。NaN は制限なし。 |
| `StabilityMaxIteration` | 10 | `v >= 1 && mod(v,1) == 0` | 外側の反復の最大回数（Q6）。 |
| `StabilityStep` | [0.1 0.02] | `numel(v) == 2 && all(v > 0)` | 信頼領域の初期幅 [ΔP ΔV] [pu]（Q5）。Inf の要素はその種類の変数に信頼領域を付けない。[Inf Inf] で信頼領域を使わない。 |
| `StabilityMargin` | [0.005 0.005] | `numel(v) == 2 && all(v >= 0 & isfinite(v))` | 線形化の誤差を見込む余裕 [ζ, Re λ [1/s]]（Q9）。切断面は MinDampingRatio + margin(1)、MaxRealPart − margin(2) を目標にする。 |
| `StabilityBand` | [0.02 0.05] | `numel(v) == 2 && all(v >= 0 & isfinite(v))` | 危険域の幅 [ζ, Re λ [1/s]]（Q9）。ζ < MinDampingRatio + band(1)、または Re λ > MaxRealPart − band(2) のモードを危険なモードとし、切断面を作る。 |

- 信頼領域の幅の更新は内部の規則: 基準の違反量（ζ と Re λ の不足分の大きい方）が前の反復より
  悪化したら幅を半分にし、改善したら据え置く。幅の下限は初期幅の 1/64（それ以下になったら
  「信頼領域が縮みきった」として打ち切り、flag 0、message に書く）。
- 差分の刻み（h_P = 1e-3 pu、h_V = 1e-4 pu）、ゼロ固有値の判定（1e-6）、MAC のしきい値（0.8）は
  内部定数のまま（オプションにしない）。
- 2 要素のオプションは、Default*.json の定義に `"Size": [1, 2]` を書き、check_setting が大きさを
  確かめ、GUILDA.setting の画面が `[0.1 0.02]` の形の文字を読む（決定 15）。
- res.options には上の 6 つがそのまま入る。DefaultOptimalPowerFlow.json の version を上げる。

### 定式化

決定変数 u は OPF の変数のうち、運転点を決める発電機の設定値とする。

- `P_g`: 発電機（`component.generator.abstract`）のうち P の上下限が異なるもの。ただし基準母線
  （ReferenceBus、潮流計算ではスラック）の発電機の P は潮流計算で決まるので除く。
- `V_i`: 発電機のある母線（PV・スラック）の電圧の大きさ。
- 負荷（PQ）は今の OPF と同じく潮流設定の P・Q に固定（上下限が無限の負荷）。上下限を持つ負荷
  （価格応答する負荷）は、最初の版では感度の対象にしない（P は OPF の変数のまま）。

外側の反復 k の OPF は、通常の AC OPF に安定度の切断面（線形化した制約）を加えた問題:

```
min  Σ C_g(P_g, Q_g)
s.t. 通常の AC OPF の制約（電力収支、上下限、ブランチの制約）
     ζ_m(u_k) + ∇ζ_m(u_k)·(u − u_k) ≥ MinDampingRatio + StabilityMargin(1)   危険なモード m ごと   StabilityDamping_<m>
     Re λ_m(u_k) + ∇Re λ_m(u_k)·(u − u_k) ≤ MaxRealPart − StabilityMargin(2)  危険なモード m ごと   StabilityRealPart_<m>
     |u − u_k| ≤ Δ_k                                                          信頼領域（要素ごと）   StabilityStep_<変数>
```

- 切断面は u の 1 次式（OPF の機器の P と母線の V の変数に対する線形制約）なので、fmincon の問題の
  非線形性は増えない。
- Δ_k の初期値は StabilityStep（P の要素に ΔP、V の要素に ΔV）。Inf の要素の制約は作らない。
- 制約名は `Stability` で始め、`build_opf_problem` が作る名前と重ならないようにする。

### 固有値の扱い

- 線形モデル: 運転点のベクトルでの `get_sys(rv_point, Type="ODE")`（母線電圧を消去した ODE。
  Linearization の設定にかかわらず内部では ODE に固定）の `eig(A, E)` の有限な固有値。
- ゼロ固有値: |λ| ≤ 1e-6·max(1, max|λ|) を除く。基準角のモード（全発電機の位相角が一緒に動く）
  がこれに当たる（IEEE14・39・68 で 1 個ずつ、下の計測）。governor のない系統で周波数のモードが
  ゼロ付近に出る場合も同じ扱い。除いた数を記録し、系統の島の数と合わないときは INFO で知らせる。
- 振動モード: |Im λ| > 1e-6 のもの（共役の組は Im λ > 0 の 1 つで代表）。ζ = −Re λ / |λ|。
  MinDampingRatio はすべての振動モードに、MaxRealPart はゼロ固有値を除くすべての固有値にかける。
- 制御器のモード: 除かない（AVR・PSS・governor のモードも安定度の一部）。各モードの参加率
  （右・左固有ベクトルの積）を状態ごとに求め、変数マップ（`get_variable_map` の Owner）で
  所有者ごとに合計して、最も寄与の大きい所有者（発電機・制御器のタグ）をモードに付ける。
- 計算の場所（2026-11-18）: 固有値・減衰比・周波数・参加率・所有者の計算は `tools.linear_modes`
  にあり、`ResultLIN.get_mode` と共有する。`@PowerNetwork/private/stability_modes` は get_sys を呼んで
  その結果からゼロ固有値を除くだけ。`sct_stability.tab_mode` は解の点の `get_sys` の `get_mode` から
  ゼロ固有値を除いたものと同じ（F74）。移す前と後で、IEEE14（MinDampingRatio=0.048）・IEEE9
  （MinDampingRatio=0.9、満たせない）・IEEE39（MaxRealPart=-0.03）の `sct_stability` と費用は
  isequaln で一致した。
- 危険なモード: StabilityBand の幅に入ったモード。基準を破るモードだけでなく、その近くのモードも
  切断面に入れて、反復ごとに別のモードが入れ替わって振動するのを防ぐ。
- モードの追跡: 差分のときと外側の反復の間で、固有値の並びは変わる。右固有ベクトルの MAC
  （|v_aᴴ v_b|² / (|v_a|²|v_b|²)）が最大で、かつ 0.8 以上の固有値を同じモードとみなす（状態の並びは
  同じ系統なので変わらない）。対応が取れないとき（モードの交差など）は、その変数の差分を
  半分の刻みでやり直し、それでも取れなければそのモードの切断面を作らない（INFO）。

### 運転点の作り方（系統を書き換えない方式）

運転点は get_sys の point（`net.get_variable_map()` の先頭の行の順のベクトル: x、Vre、Vim、u）として
組み立て、`net.get_sys(rv_point, Type="ODE")` で線形化する。ネットワーク・母線・機器・制御器の
プロパティには書き込まない。

1. OPF の解の点: 母線の電圧 `res.tab_bus.Vphasor`、機器の P・Q `res.tab_cub{tag, ["P","Q"]}`、
   機器の電流 I = conj((P + jQ)/V)。
2. 差分の点（設定値を少し動かした点）: `net.get_pf_condition(Display=false)` の表 Bus と Y を
   取り出し、表の設定値を書き換えて潮流を解く。
   - スラック母線: Varg と V に OPF の解。PV 母線: V に OPF の解の |V|、P に機器の P の和
     （動かす発電機は +h）。PQ 母線は表のまま（負荷は固定）。
   - `SolverPF().solve(cm_Y, tab, sct_options)` で解く。ネットワークの `solver_PF` は使わない
     （ウォームスタートの解を書き換えるため）。sct_options は GUILDA.config の PowerFlowCalculation の
     値で、WarmStart = false、PlotFcn = "none"、Verbose = false。
   - 初期値: 平坦な初期値（角 0、大きさ 1）からは発散することがある（IEEE68 の既定の OPF の解は
     発電機母線の V が上限の 1.5 pu で、平坦な初期値から発散した）。OPF の解の電圧から始める
     手段が必要。SolverPF に初期電圧の欄を足す（決定 17）。
   - 母線の P・Q を機器に分けるのは `tools.distribute_power(bus, P, Q, rule)`（読むだけの関数。
     ネットワークのスナップショット `struct(net, false)` の母線も受け付ける）。動かした発電機の
     P は、スナップショットの機器の powerflow の P を書き換えて渡す（スナップショットは構造体なので
     ネットワークは変わらない）。
3. 機器の x と u: `comp.get_equilibrium(c_V, c_I, r_P, r_Q)`（出力で返す。書き込まない。(c) を参照）。
4. ローカル制御器の x と入力の平衡点: `[rv_X, rv_U] = con.get_equilibrium(V, u)`（決定 14 で値を返す
   形にした。入れ子の制御器は呼び出し側が順にたどる）。
5. グローバル制御器の x: `gc.get_equilibrium()`（出力で返す）。
6. 母線の Vre・Vim は運転点の電圧。行の対応は `get_variable_map` の Kind・Owner・Bus で取る
   （変数マップは外側の反復の最初に 1 回だけ作る）。

前提: ネットワークは一度 `initialize()` されていて、その後に動特性や入力が編集されていないこと。
get_sys はベクトルの point でも stale の印 odefcn と input を確かめる（下の (b)）。満たさないときは
get_sys の GUILDA:PowerSystemModel:Stale または InputEdited のエラーをそのまま返す（新しいエラー ID は
作らない）。安定度の計算のために initialize は呼ばない。

#### 実現の見通し（コードを読んで確かめた結果、2026-11-15）

(a) 制御器の平衡点を書き換えなしに求められるか

- グローバル制御器: できる。`GlobalController.get_equilibrium(obj)` は `[x, u]` を返し、書き込みは
  `GlobalController.initialize` が行う。組み込みの `broadcast_PI_AGC` は 0 を返すだけ。ただし抽象
  メソッドの説明は「機器の平衡点が設定された後に呼ぶので、それを読んでよい」としている。保存された
  機器の平衡点を読むグローバル制御器は、書き換えない方式では前の initialize の点を読んでしまう。
  組み込みのものにはないが、契約の説明を「機器の平衡点を読むときは引数で受け取る」に変えるか、
  制限として書く必要がある（決定 14 で契約の説明に書く）。
- ローカル制御器（AVR・PSS・governor・local_LQR）: 今はできない。抽象メソッド
  `get_equilibrium(obj, V, u)` は出力を持たず、どの実装も `obj.rv_Xequilibrium` と
  `obj.rv_Uequilibrium` に書き込み、入れ子の制御器（AVR の下の PSS）を呼ぶ。get_* だけで済む
  手段はない。足りないもの:
  - 平衡点を出力で返す形（例 `[rv_X, rv_U] = get_equilibrium(obj, V, u)`。入れ子の制御器の分は
    呼び出し側が集める）。書き込みは `Component.set_equilibrium` 側に移す。変更するファイルは
    LocalController.m、Component/set_equilibrium.m と、avr（abstract、AVR_DC1、AVR_ST1）、
    pss（abstract、PSS1）、governor（IEEJ_LPT1、IEEJ_LPT3、IEEJ_LPT4）、local_LQR の
    get_equilibrium、テストの stub。公開メンバーは増えないが、利用者が作った制御器の契約が変わる。
  - local_LQR は get_equilibrium の中でゲイン K を設計し直し（`design_gain`、`obj.K` に書き込む）、
    ハンドルを作り直す。書き換えない方式では K は前の initialize で設計したもののまま（運転点を
    変えても制御器の設計は変わらない、という解釈）になる。initialize(Method="OPF") のあとの
    get_sys とは固有値が一致しない。
  - IEEJ_EAST10 で確かめたところ、既定の AC OPF の解では governor（IEEJ_LPT1）の get_equilibrium が
    「サーボの位置 1.172 pu が上限 1.05 pu を超える」で止まった。OPF は制御器の平衡点の制限
    （サーボの位置、AVR の界磁電圧の範囲）を知らないので、運転点が作れないことがある。このときは
    GUILDA:PowerNetwork:StabilityPointFailed（案）で、元のメッセージを添えて止める。
- 機器（発電機・負荷）: できる（(c)）。

(b) get_sys をベクトルの point で使うときの問題

- stale の検査: point が [] でないとき、get_sys が確かめるのは odefcn（動特性の編集）と input
  （入力の編集）だけで、powerflow と equilibrium の印は見ない。OPF の点はネットワークの平衡点と
  違ってよいので、これは都合がよい。ただし initialize を一度もしていないネットワークは odefcn が
  stale なので止まる（上の前提）。
- 入力の元が無い制御器の入力: get_sys は、接続の元が "equilibrium" の入力（AVR の Vref、governor の
  Pref・Plimit、local_LQR の x0 など）に、保存された `con.rv_Uequilibrium` を使う。ベクトルの point
  には制御器の入力の行（uc）がないので、OPF の点での基準値を渡せない。
  - 線形な制御器では問題にならない: 基準値は状態方程式に足されるだけで、Jacobian に入らない。
    IEEE68（AVR_ST1 と PSS 32 台）で、前の潮流計算の点の基準値のまま線形化した固有値と、OPF の点の
    基準値で線形化した固有値は完全に一致した（下の (d)）。
  - 非線形な制御器では問題になる: IEEJ_LPT1 のサーボの速度は `lvg(Pref − x(1), Plimit)` と
    `servo_rate(gate − x(2), ...)` で決まり、Pref が古いと gate − x(2) が 0 にならず、速度の制限や
    低値選択の側が変わって Jacobian が変わりうる。AVR_ST1 の出力の制限 `max(min(x(2), Vap_max), Vap_min)`
    は状態だけで決まるので問題ない。
  - 足りないもの: point で制御器の入力の平衡点を渡す手段。get_sys の point に uc の行を足す（決定 16）。
- 線形化の行列: get_sys は point の x、V、u だけで各ブロックの Jacobian を評価する
  （`get_linear_matrix(x, V, u)`、関数ハンドルはパラメータから作られている）。アドミタンス行列は
  モデルのもの。これは OPF の点でも同じなので問題ない。get_sys 自体はネットワークに書き込まない
  （(d) で前後のプロパティを比べて確かめた）。

(c) get_equilibrium が本当に副作用なしか

- 機器: 組み込みの発電機（classical、one_axis、two_axis、park、droop）と負荷（load.power、
  load.impedance）の get_equilibrium は、パラメータを読んで出力を返すだけで、プロパティに書き込まない。
  IEEE14・IEEE68 で、全機器の get_equilibrium を呼ぶ前後で、機器・制御器・母線の（ハンドル以外の）
  プロパティが変わらないことを確かめた。
- 例外: `component.ConstSource.power` の get_equilibrium は `obj.PQ_st` に書き込み、その
  get_linear_matrix は `PQ_st` を使う。書き換えない方式では前の initialize の値で線形化してしまう。
  また引数が (obj, Veq, Ieq) の 3 つで、Component の契約（c_V、c_I、r_P、r_Q の 4 つで呼ぶ）と
  合っていない。get_linear_matrix が P・Q を入力 u（= [P; Q]）から取るように直す（決定 18）。
- `Component.validate` の説明に「get_equilibrium に値を保存するモデル（例: 負荷）」とあるが、今の
  負荷は保存していない（古い説明。ConstSource.power だけが当たる）。
- ローカル制御器: 書き込む（(a)）。グローバル制御器: 書き込まない。

(d) IEEE14（と制御器のある IEEE68）で確かめた結果（作業用のスクリプト、コミットしない）

- 方法: 潮流計算で initialize したネットワークで AC OPF を解き、上の手順で運転点のベクトルを作って
  `get_sys(rv_point, Type="ODE")` の固有値を求める。別のネットワークで `initialize(Method="OPF")` のあと
  `get_sys(Type="ODE")` の固有値を求めて比べる。ローカル制御器の x は、ネットワークを書き換えない
  ように 3 つ目のネットワークで get_equilibrium を呼んで読んだ（決定 14 の実装前の代わり）。
- IEEE14（制御器なし、変数 92、固有値 30）: 運転点のベクトルは initialize(OPF) の平衡点と完全に
  一致（差 0）。固有値の差 0。ζ_min 0.044718、max Re −0.182760。
- IEEE68（AVR_ST1・PSS 32 台、変数 382、固有値 112）: 運転点のベクトルの差 0、固有値の差 0
  （制御器の入力の基準値が古い場合も 0）。ζ_min 0.084656、max Re −0.006117。
- 差分の点（IEEE14・IEEE68、PV 母線の発電機 1 台の P を +1e-3）: 表を書き換えて SolverPF で解いた点の
  固有値と、別のネットワークの設定値を書き換えて initialize() した点の固有値の差は、IEEE14 で 1.3e-12、
  IEEE68 で 2.5e-11（max|λ| は 54、81）。ネットワークのスナップショットは前後で同じ。
  IEEE68 では平坦な初期値の潮流計算が発散したので、元の設定値の潮流解をウォームスタートにした
  （決定 17）。
- 1 点の評価時間（未整理のスクリプト）: IEEE14 0.39 s、IEEE68 0.74 s。設定値を変えて initialize する
  方法（0.29 s、0.45 s）より少し遅いが、潮流計算を 2 回解いていることと、変数マップを毎回作っている
  ことによる。変数マップを 1 回にし、OPF の解から潮流計算を始めれば、initialize の方法と同程度に
  なる見込み。

### 感度（差分）

- ∂ζ_m/∂u_j ≈ (ζ_m(u + h_j e_j) − ζ_m(u)) / h_j。前進差分、刻み h_P = 1e-3 pu、h_V = 1e-4 pu（内部定数）。
- 1 回の評価: 上の「差分の点」の手順で運転点のベクトルを作り → get_sys → eig → モードの追跡。
- 外側の反復 1 回あたりの評価は 1 + n_u 回（n_u = 感度をとる P の数 + V の数）。
- 解析的な感度への差し替え: 感度は private 関数 1 つ（例 `stability_gradient`: ネットワーク、
  u_k、危険なモード → 勾配）にまとめ、外側の反復はこの関数の出力（ζ、Re λ、勾配の行列）だけを
  使う。固有値の感度 ∂λ/∂u = wᴴ (∂A/∂u) v / (wᴴ E v) の ∂A/∂u を差分で作る形（評価回数は同じ）や、
  get_sys の Jacobian の解析的な微分に後で置き換えられる。

### 結果と flag

- 公開メンバーの追加: `ResultOPF.sct_stability`（1 つ、決定）。
  - `tab_iteration`: 外側の反復ごとに 1 行。Iteration、Cost（目的関数値）、MinDampingRatio
    （その点の ζ_min）、MaxRealPart（その点の max Re λ）、CriticalMode（危険なモードの名前の
    string 配列。例 "B002SG1 0.82 Hz"）、Step（その回の信頼領域の幅 [ΔP ΔV]）、Flag（その回の OPF の
    終了フラグ）。
  - `tab_mode`: 最後の運転点のモードの表。Eigenvalue、Frequency [Hz]、DampingRatio、Owner
    （参加率が最大の所有者）。
  - MinDampingRatio と MaxRealPart が両方 NaN のときは空の構造体（今と同じ）。
- 表示: `disp_summary` に 1 行（最小減衰比、最大実部、外側の反復の回数）を加える（新しい公開
  メソッドは作らない）。
- flag と output.message:
  - 基準を満たした: 最後の OPF の flag（正）。message は最後の OPF の message に「安定度の基準を
    満たした（外側の反復 n 回、ζ_min = …、max Re = …）」を足す。
  - StabilityMaxIteration に達した、または信頼領域が縮みきった: flag = 0、l_success は false。
    message に未達の値と最後の危険なモードを書く。結果の表は最後の OPF の解。
  - 切断面を加えた OPF が解けない（実行不可能、fmincon の反復上限など）: 2026-11-20 に変更。
    1 回目の OPF（切断面なし）が解けないときは、その OPF の flag と message（外側の反復の回数を
    添える）で、結果はその回の出力（OPF の失敗と同じ扱い）。2 回目以降は、止まった OPF の最後の点を
    返さない（潮流の釣り合いを満たさず、費用が最適値より小さく見えることがある）。結果は 1 つ前の
    外側の反復の解、flag = 0、tab_iteration の最後に止まった OPF の行（Cost・MinDampingRatio・
    MaxRealPart は NaN、Flag はその終了フラグ）、警告 GUILDA:PowerNetwork:StabilityOPFFailed。
  - CriticalMode の並び（2026-11-20）: MinDampingRatio に近いモードを ζ の小さい順、次に
    MaxRealPart だけに近いモードを Re λ の大きい順（以前は eig の順）。
  - 運転点が作れない（差分の潮流計算が収束しない、制御器の get_equilibrium が止まる）: エラー
    （GUILDA:PowerNetwork:StabilityPointFailed、案）。元のメッセージを添える。
  - DC OPF・ELD での指定: エラー（GUILDA:PowerNetwork:StabilityNeedsACOPF、案）。

### 計算時間（R2026a、2026-11-14 に計測）

| 系統 | 母線 | 発電機 | 状態数 | get_sys(ODE) 1 回 | eig | 差分 1 回（設定値の変更 + initialize + get_sys + eig） | AC OPF 1 回 |
|---|---|---|---|---|---|---|---|
| IEEE14bus | 14 | 5 | 30 | 0.14 s | 0.2 ms | 0.44 s | 5.9 s |
| IEEE39Bus | 39 | 10 | 40 | 0.17 s | 0.3 ms | 0.37 s | 14.6 s |
| IEEE68bus | 68 | 16 | 144 | 0.31 s | 3.7 ms | 0.79 s | 18.1 s |

- 差分 1 回の時間は initialize を使う方法で測った。書き換えない方式（潮流計算 + get_equilibrium +
  get_sys + eig）も同程度の見込み（上の (d)）。
- 外側の反復 1 回 ≈ AC OPF 1 回 + (1 + n_u) × 差分 1 回。n_u は IEEE14 で 9（P 4 + V 5）、IEEE39 で 19、
  IEEE68 で 31 として、IEEE14 ≈ 5.9 + 10 × 0.44 ≈ 10 s、IEEE39 ≈ 14.6 + 20 × 0.37 ≈ 22 s、
  IEEE68 ≈ 18.1 + 32 × 0.79 ≈ 43 s。3〜5 回の外側の反復で、IEEE14 は 30〜50 s、IEEE68 は 2〜4 分。
- 計測時の固有値: ゼロ固有値は各 1 個。IEEE14 は ζ_min 0.043・max Re −0.18、IEEE39 は ζ_min 0.040・
  max Re +0.30（正の実固有値。発電機の Eq' の flux decay モード。「実装」の節）、IEEE68 は ζ_min 0.089・
  max Re −0.005（潮流計算の点。OPF の点では (d) の値）。
- 時間の大半は fmincon。外側の反復 2 回目以降は、前の OPF の解を初期点にした WarmStart で OPF を
  短くできる。

### 検証の計画

1. NaN（既定）で今の結果とビット単位で同じ（保存した結果との比較）。
2. 運転点のベクトル: OPF の解から作った点と、initialize(Method="OPF") のあとの平衡点・固有値が一致する
   （IEEE14、IEEE68、governor のある系統）。
3. IEEE14 で MinDampingRatio を今の ζ_min（0.045）より少し上（例 0.05）にする。最後の点で
   ζ_min ≥ 0.05 − 1e-3、費用は制約なしより大きく、外側の反復の費用は単調に増える。
4. 減衰の悪いケースを作る: 発電機の制動係数 D（`tab_parameter.dynamics`）を小さくする、高ゲインの
   AVR を付ける、負荷を増やす。重負荷の母線に近い発電機の出力を下げると ζ が上がる、などの
   向きを確かめる。
5. 感度の検証: 差分の刻みを半分にしても勾配が 1e-2（相対）以内で一致する。小さな系統（3 母線・
   発電機 2 台）で、発電機の P を格子状に動かした総当たりの最適解と、安定度制約付き OPF の解を比べる。
6. MaxRealPart: IEEE39 の正の実固有値か、AVR のゲインで不安定にしたケースで、max Re ≤ 指定値に
   なること。
7. 達しない場合: 満たせない基準（例 MinDampingRatio = 0.9）で flag = 0、message、tab_iteration の行数
   = StabilityMaxIteration。
8. オプション: StabilityStep = [Inf Inf] で信頼領域の制約がないこと、StabilityMargin・StabilityBand の
   値で切断面の目標と危険なモードの数が変わること、不正な値（負、要素数の違い）がエラーになること。
9. 系統を書き換えないこと: 実行前後でネットワークのスナップショット（平衡点、stale の印、
   solver_PF・solver_OPF のウォームスタート）が同じ。
10. DC OPF・ELD での指定がエラーになること。

### 過渡安定度（今回は実装しない）

実装の対象外。将来は、事故のシナリオ（Scenario）を simulate で評価し、相差角の最大値に上限をかける形で、
同じ外側の反復・切断面・結果の表を使える。ただし simulate は平衡点をネットワークから読むので、
系統を書き換えない方式との両立は、そのときに改めて検討する。

### 実装（2026-11-16）

- 場所: `calculate_optimal_powerflow` の手順 2 の分岐（両方 NaN なら今の 1 行の solve のまま）と、
  `@PowerNetwork/private/` の `stability_point`（運転点のベクトル）、`stability_modes`（固有値・減衰比・
  参加率の所有者。2026-11-18 に計算を `tools.linear_modes` へ移し、get_sys を呼ぶだけになった）、`stability_gradient`（差分の感度。解析的な感度に差し替える場所）。検証関数
  `mustBeDampingRatioOrNaN`、`mustBeFiniteOrNaN` も private。
- 公開メンバー: 承認どおり。Name-Value 6 つ（DefaultOptimalPowerFlow.json の version を 2 に上げ、
  Valid と Size 付きで定義）、`ResultOPF.sct_stability`、エラー ID 2 つ、`disp_summary` の 1 行。
- 制御器の入力 uc: 平衡点では、制御器の入力の値は get_equilibrium が返す入力の平衡点そのもの
  （観測する入力も含む）なので、その値を point の uc の行に入れる。local_LQR は、機器の状態を
  保存された値から読む（get_equilibrium が V と u しか受け取らないため）。ただし local_LQR の式は
  入力について線形なので、Jacobian は変わらない。
- 仕様からの変更（実装中にわかったこと）:
  - 切断面にスラック s ≥ 0 を付け、目的関数に r_w·Σs（r_w = 1000·max(1, |最初の OPF の費用 − Σc|)、
    ζ または 1/s の 1 単位あたり）を足した。IEEE14 では、危険なモード 4 つの切断面と潮流の制約
    （発電機母線の V が上限 1.06）が同時には満たせず、硬い切断面の OPF が毎回「実行不可能」に
    なった。到達できる幅で目標を抑える案や、満たせる割合を別の問題で求める案も試したが、前者は
    実行不可能が残り、後者は割合を最大にする問題が退化して fmincon が 650〜1000 反復かかった。
    スラック付きなら 1 回の solve で必ず解があり、満たせるところまで進む。result.r_cost と
    tab_iteration.Cost はペナルティを除いた費用（OPFprob の目的関数と sct_iteration.Fval は含む）。
  - 制約名は、モードごとの `StabilityDamping_<m>` ではなく、配列 `StabilityDamping`・
    `StabilityRealPart`（要素がモード）にした（スラックの変数 `StabilitySlack` と並べるため）。
    信頼領域は `StabilityStep_<変数>`（2 要素）。
  - INFO 2 つ（2026-11-16 にユーザーが追加を決定）: ゼロ固有値の数が島の数と違うとき
    `GUILDA:PowerNetwork:StabilityZeroEigenvalues`（1 回の呼び出しで 1 回。制動も速度の制御もない
    発電機では周波数のモードもゼロになる）、差分の点で危険なモードを追跡できず、その反復の切断面から
    外したとき `GUILDA:PowerNetwork:StabilityModeNotTracked`（所有者・周波数・固有値を並べる。同じ
    発電機 3 台が負荷母線を囲む系統で、重なった電気機械モードで起きることをテストで確認）。show_msg を
    使うので、GUILDA.setting の Message.ShowInfo で消せる。
  - スラックの判断（2026-11-16 ユーザーが承認）: 切断面のスラック s ≥ 0 と目的関数の r_w·Σs、
    result.r_cost と tab_iteration.Cost にペナルティを含めないこと、制約名を配列にしたこと。
  - 費用は外側の反復で単調に増えるとは限らない（切断面を置き換えるので、前の反復の点より安い点に
    戻れる。下の IEEE14 の 0.05 では単調、旧版の試行では 8325 → 8276 のように下がる例があった）。
- 計算時間（R2026a）: 運転点 1 点（潮流計算 + get_equilibrium + get_sys + eig）は IEEE14 で約 0.3 秒。
  IEEE14・MinDampingRatio=0.048 は外側の反復 4 回で 15 秒、0.05 は 10 回で 43 秒、IEEE39・
  MaxRealPart=-0.05 は 10 回で 67 秒。
- 結果（外側の反復ごと。Cost はペナルティを除く費用）:

  IEEE14、MinDampingRatio = 0.048（flag 1）

  | 反復 | Cost | ζ_min | max Re |
  |---|---|---|---|
  | 1 | 8081.5 | 0.04472 | −0.1828 |
  | 2 | 8212.4 | 0.04541 | −0.1874 |
  | 3 | 8372.2 | 0.04670 | −0.1882 |
  | 4 | 8566.7 | 0.04813 | −0.1888 |

  IEEE14、MinDampingRatio = 0.05（flag 0、10 回で未達）: ζ_min は 0.0447 → 0.0484（4 回目）→ 0.0494
  （8 回目）で頭打ち（費用 8081 → 10326）。9 回目に違反が増えて信頼領域を半分にし、10 回目は 0.0489。
  発電機母線の V が上限にあり、この系統の運転点の範囲では 0.05 に届かないとみられる。検証の計画の
  「0.05 − 1e-3 以上」は 8 回目で満たすが、基準そのものは満たさない。テストは 0.048 で行う。

  減衰の悪いケース: IEEE14 の発電機の D を 1/10（制約なしの ζ_min 0.0312）、MinDampingRatio = 0.033
  → 3 回で満たす（0.0312 → 0.0325 → 0.0338、費用 8081 → 8192 → 8309）。0.035 では 10 回で 0.0349。

  IEEE39、MaxRealPart = −0.05: max Re −0.0212 → −0.0455（10 回、費用 435.8 → 455.8、単調）。
  −0.03 なら数回で満たす（テスト）。IEEE14 の MaxRealPart = −0.2 は届かない（−0.183 → −0.185）。

- 差分の刻みの検証: IEEE14 の最初の反復の危険なモードで、刻みを半分にした勾配との相対差は
  減衰比 0.0023、実部 0.0035（IEEE39 の実部 0.0009、IEEE14 の MaxRealPart のケース 0.0083）。
- 運転点の検証: IEEE9（AVR・PSS）の制約なしの解の点の ζ_min は、initialize(Method="OPF") のあとの
  get_sys の ζ_min と 1e-6 以内で一致（テスト）。MinDampingRatio・MaxRealPart が NaN のときの結果は、
  変更前のコードと isequaln（IEEE14・IEEE9 の ELD・DC・AC、反復の記録を含む）。
- IEEE39 の正の実固有値（潮流計算の点で +0.298）: 参加率の大きい状態は発電機の d 軸過渡内部電圧
  Eq'（B038SG1 0.21、B033SG1 0.13、B034SG1 0.11、B036SG1 0.09 …）。IEEE39 の既定には AVR がなく
  界磁電圧が一定なので、界磁磁束の減衰（flux decay）の非振動の不安定モード。OPF の点では
  −0.021（B030SG1）で安定になる。

### IEEJ_EAST30 で MaxRealPart が −0.0086 から動かない理由（調査、2026-11-20）

NEDO の資料（IEEJ_EAST30 peak、2xxx は P²+10P、3xxx は P²+40P、P は Prate の 20〜100 %、
V 0.95〜1.05 pu）で、安定度制約付き OPF の MaxRealPart が −0.0086 1/s で止まる件。

- 原因は水力の調速機 gov-LPT4（B3012〜B3016、B3018〜B3020 の CG2、8 台）の Pgov・Pdr の実固有値。
  AC OPF の解の点で、実部が最大の非ゼロ固有値は振動モード（B2001SG1 0.222 Hz、+0.0157）で、
  それを左へ動かすと、次に大きいのは −0.00857 の実固有値 7 個（参加率は Pgov 0.3〜0.7、Pdr 約 0.1）。
- その値は 2 次のブロック T_g Ṗgov = −(droop/100)Pgov − (K_t/T_t)(Pgov − Pdr)、
  T_t Ṗdr = Pgov − Pdr の固有値 −0.008568 と −0.09727（droop 4 %、T_g 4 s、K_t 0.6、T_t 12 s）に
  一致する（−0.0972 の 2 個も同じ）。パラメータだけで決まり、設定値 u（P、V）では動かない。
- 切り離される理由: この 8 台は PLM = 0 で、平衡点では low value gate の入力 Pref + Pgov と
  Plimit が等しい（折れ点の上）。lvg は r_e ≤ Plimit で Pgov 側を通すが、等号は丸めで決まり、
  7 台は Plimit 側（l_ref = false）になって Psv が Pgov に依存しない。Pgov・Pdr は ω で駆動されるだけで
  出力に戻らないので、そのモードは系統から見えず、固有値はブロックの値のまま。残る 1 台は Pgov 側
  （l_ref = true）で系統とつながり、−0.0105 のモード（Pgov の参加率が複数台に分かれる）になると
  推測している（どの 1 台が l_ref = true かは未確認）。
- コードの扱い: 実固有値は ζ が NaN で MinDampingRatio の対象外、MaxRealPart はゼロ固有値
  （|λ| ≤ 1e-6·max(1, max|λ|)、この例では 1 個）以外のすべての固有値にかかる。制御器のモードも
  除かない（仕様どおり）。このモードは勾配が 0 なので、−0.0086 より厳しい MaxRealPart は
  切断面のスラックで止まり、満たせない。
- 判断: OPF のバグではなく仕様の限界（設定値で動かせないモードも制限にかける）と、PLM = 0 で
  折れ点の上にある LVG の線形化（丸めで分岐が決まる）。コードは変えていない。考えられる対応
  （未決、要相談）: 勾配がほぼ 0 のモードを制約から外して message で知らせる、MaxRealPart を
  振動モードだけにするオプション、lvg の等号の扱いを決める（モデル側）。

### 未決事項

なし（Q1〜Q15 は 2026-11-15 までにすべて決定し、本体は 2026-11-16 に実装した）。
