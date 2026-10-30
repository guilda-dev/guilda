function c_old = v3_optimize_powerflow(result, flag, output)
% Convert an OPFResult into the old output tuple of optimize_powerflow.
%
% Old (v3) outputs of PowerNetwork.optimize_powerflow, made from the v4 outputs:
%   [powerflow_bus, powerflow_cub, flag, output, lambda, OPFprob]
% optimize_powerflow returns them through legacy_output when called with 6 outputs
% (GUILDA:Deprecated:OptimizePowerflowTuple).
%
% Name-Value options:
%
% - `result` — Result of optimize_powerflow.
% - `flag` — exitflag of solve.
% - `output` — Solver details.
%
% See also legacy_output, PowerNetwork.optimize_powerflow
    arguments (Output)
        c_old   % {powerflow_bus, powerflow_cub, flag, output, lambda, OPFprob}.
    end
    c_old = {result.tab_bus, result.tab_cub, flag, output, result.lambda, result.OPFprob};
end
