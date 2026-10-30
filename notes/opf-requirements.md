# OPF requirements

Requirements for optimal power flow (OPF) in GUILDA v4, as decided by the
user on 2026-10-29 and 2026-10-30. Undecided design details are listed at
the end as open questions.

## Uses

- Setting the equilibrium: `initialize` can start from an OPF operating
  point.
- Economic-operation studies.
- Research analysis: duals and nodal prices, sensitivities, Hessians.
- Teaching.

## Problem types and scope

- ELD (economic load dispatch), DC OPF and AC OPF.
- Multi-period OPF. Time series are passed at call time, e.g. as a
  timetable keyed by component tag. Models stay single-snapshot: a
  component describes one operating point, not a time series.
- Out of scope: unit commitment (UC) and security-constrained OPF (SCOPF).
  The CSV columns `OPFcost_startup` / `OPFcost_shutdown` are reserved and not
  used by any problem type.

## Defaults and customization

- Defaults use the standard objective, constraints and algorithms for each
  problem type.
- Users customize per object through a `set_opffcn` method, by analogy with
  `set_odefcn`. It stores user function handles on a Component, Bus or
  Branch; each object then adds its own terms to the problem.
- Network-wide terms (e.g. a reserve requirement over many generators) go
  through the same method name on `PowerNetwork`.
- Handles (decided 2026-10-30):
  - `obj.set_opffcn("Cost", fcnCost, "Constraint", fcnCon)`, one handle per
    term. `fcnCost = @(v, p) <scalar expression>`;
    `fcnCon = @(v, p) struct(<name>, <constraint>, ...)`.
  - `v` is the object's own optimization variables, `p` its parameters.
    An object-level handle sees only its own variables.
  - `Cost` replaces the default cost of that object. Constraints are added
    to the defaults; their names become the dual labels.
    `"DefaultConstraint", false` removes the object's default operating
    limits (the model equations stay). `reset_opffcn()` restores the
    defaults.
  - A `PowerNetwork`-level handle receives the variables of every object,
    addressed by tag: `v.Component.(tag).P`, `v.Bus.(tag).V`,
    `v.Branch.(tag).Pfrom`.
  - Single-snapshot handles stay scalar; multi-period OPF is a separate
    method.
  - `set_opffcn` is an OPF edit: logged in the edit log, it does not make
    the equilibrium stale.
- Default cost of loads is 0. A price-responsive load is a load with P
  bounds and its own cost, set explicitly.
- DC OPF uses the MATPOWER branch susceptance `1/X` (with the tap ratio as
  MATPOWER does).
- Rejected:
  - run-time arguments to `optimize_powerflow` that describe extra terms;
  - asking users to edit the returned `optimproblem` by hand.

  Both scale badly: mid and large systems have too many variables to name
  at the call site.

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

1. Correctness of ELD, DC OPF and AC OPF.
2. `set_opffcn` customization.
3. External solver backends.
4. Multi-period OPF.

## Open questions

- **Multi-period variables in handles.** Is a handle called once per period
  with that period's variables, or once with variables that carry a time
  dimension (needed for ramp limits and storage energy balance)? How a
  timetable column is mapped to a handle argument is not decided.
- **Duals and sensitivities API.** How nodal prices, line-limit shadow
  prices and Hessians are exposed on `OPFResult` (names, units, sign
  convention per unit of load).
- **Warm start for `initialize`.** Whether `initialize` may use an OPF
  point, and what happens when the OPF does not converge.
