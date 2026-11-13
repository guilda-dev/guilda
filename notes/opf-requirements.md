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
- 問題の構築: 潮流計算と同じ方式（2026-11-12）。`calculate_optimal_powerflow` と
  `build_opf_problem` が `net.get_opf_condition(Display=false)` で母線・機器・ブランチの
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
  `@PowerNetwork/private/opf_setting.m`。`opf_data.m` は削除。
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
- 変更した問題の求解: `[prob, x0] = net.build_opf_problem(...)` の `prob` を変更し、
  `net.calculate_optimal_powerflow(Problem=prob, InitialPoint=x0)` で求解（呼び出しのみの
  オプション、保存しない）。結果の表は通常どおり。
- OPF のオプションと operation / OPF の編集は平衡点を古くしない。
- 負荷の既定のコストは 0。価格応答する負荷は P の上下限と `Cost` を明示。
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
