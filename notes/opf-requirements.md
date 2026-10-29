# OPF requirements

Requirements for optimal power flow (OPF) in GUILDA v4, as decided by the
user on 2026-10-29. Undecided design details are listed at the end as open
questions.

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
- Rejected:
  - run-time arguments to `optimize_powerflow` that describe extra terms;
  - asking users to edit the returned `optimproblem` by hand.

  Both scale badly: mid and large systems have too many variables to name
  at the call site.

## Solvers

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

- **Signature of the `set_opffcn` handles.** What does a handle receive and
  return? Candidates: the object's own optimization variables (struct of
  `optimvar` / `optimexpr`) and its parameters, returning cost terms and a
  struct of constraints. Whether a handle may see other objects' variables
  (e.g. neighbor bus voltages) is not decided.
- **Combination with defaults.** Does a user handle replace the default
  cost/constraints of that object, add to them, or choose per term?
- **Multi-period variables in handles.** Is a handle called once per period
  with that period's variables, or once with variables that carry a time
  dimension (needed for ramp limits and storage energy balance)? How a
  timetable column is mapped to a handle argument is not decided.
- **Backends that cannot express a problem.** When a user term is nonlinear
  and the backend is linear/quadratic only (CPLEX/Gurobi via `prob2struct`,
  or MATPOWER's fixed `mpc` model): error, warning with fallback to the
  Toolbox, or silent fallback?
- **Network-wide terms.** Which variables a `PowerNetwork`-level handle can
  reference, and how it names them (by component tag, bus index, class).
- **Duals and sensitivities API.** How nodal prices, line-limit shadow
  prices and Hessians are exposed on `OPFResult` (names, units, sign
  convention per unit of load).
- **Default cost of loads.** Every component, loads included, gets
  `HP = fP = 1` by default. Should a load's default cost be zero, and should
  a price-responsive load be a load with free P (bounds) and its own cost?
- **DC susceptance.** DC OPF uses `b = Im(Y_ij)`; MATPOWER uses `1/X`. Keep,
  switch, or make it an option (it matters for a MATPOWER backend).
- **Warm start for `initialize`.** Whether `initialize` may use an OPF
  point, and what happens when the OPF does not converge.
