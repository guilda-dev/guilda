classdef SolverCPF < auxiliary
% Solver of the continuation power flow (CPF).
%
% Starting from the equilibrium found by net.initialize, it scales the loads of LoadBus by
% (1 + lambda) and traces the power flow solution with a predictor-corrector method past
% the maximum loading point (the nose of the PV curve). net.solver_CPF holds one. The
% settings are the ContinuationPowerFlow section of GUILDA.setting
% (GUILDA.config("ContinuationPowerFlow")); the solver keeps only the condition of its
% network, LoadBus (kept between runs). Name-Value options of
% net.calculate_continuation_powerflow override both for that call only; neither the
% solver nor the settings file is changed: the call passes its options as they are, and
% the settings without an option (CorrectorMaxIteration, CorrectorStepSize, Increment) are
% read from GUILDA.config where solve uses them. Results are returned as a ResultCPF.
%
% - The power the components of the `LoadBus` buses draw is multiplied by (1 + lambda).
% - `StepSize` multiplies the tangent at the first step and the secant from the previous
%   step afterwards. The trace stops before `MaxIteration` when lambda falls below 0 after
%   the nose.
% - With `UseInternalState` true, the generator powers follow their state equations
%   (getCompPQ) and all loads are scaled; when false, the components inject their
%   equilibrium powers. True stops with GUILDA:build_layout:MissingGetCompPQ if a component
%   has no getCompPQ.
% - `Limits` applies the operating limits (tab_parameter.operation) along the path; Inf
%   and NaN limits are none. "Q": a PV bus whose generators (the components with Q = NaN
%   in powerflow) leave the sum of their Qmin/Qmax becomes a PQ bus with Q fixed at that
%   bound (never back to PV; not with UseInternalState, not the slack bus). "V": the trace
%   stops where the voltage of a bus reaches Vmin or Vmax. "S": it stops where the larger
%   |S| of the two ends of a branch reaches Smax. The switches are in
%   ResultCPF.tab_switch, the stop in ResultCPF.tab_stop; nothing is written to the model.
% - The Newton-Raphson corrector takes CorrectorMaxIteration and CorrectorStepSize, and
%   the predictor and the corrector the numerical Jacobian step Increment, from the
%   ContinuationPowerFlow section of GUILDA.setting.
% - Each Name-Value option of net.calculate_continuation_powerflow is also the key of the
%   setting (LoadBus: the property).
% - `PlotFcn` (live display): "pvcurve" draws |V| of every bus against lambda and extends
%   the lines at each step (one reused figure); a function handle is called at the
%   starting point ("init"), each step ("iter") and the end ("done") as
%   stop = f(x, optimValues, state), x the complex bus voltages, optimValues.iteration
%   (step), .lambda and .correctorIterations; a true stop ends the path there.
%   result.plot_pvcurve() draws the PV curves after the analysis.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% net.solver_CPF.LoadBus = ["B009","B014"];       % condition of this network, kept between runs
% result = net.calculate_continuation_powerflow();
% result = net.calculate_continuation_powerflow(StepSize=0.1, Verbose=true);   % this call only
% result = net.calculate_continuation_powerflow(Limits="all");   % Q limits, stop at V / S limits
% ```
%
% See also ResultCPF, PowerNetwork.calculate_continuation_powerflow

    properties (Access=public) % Conditions
        LoadBus (1,:) string = strings(1,0)                              % Tags of the buses whose loads are scaled by (1 + lambda); must not be empty when solving.
    end

    methods
        function obj = SolverCPF(varargin)
        % Create a CPF solver with no LoadBus (the settings are read at each run).
        %
        % A network creates its own (net.solver_CPF); net.reset_solver() replaces it with a
        % new one. Any argument (the v3 form SolverCPF(net, Name, Value)) stops with
        % GUILDA:v3_cpf_constructor:ContinuationPowerFlowConstructor.
            arguments (Input, Repeating)
                varargin  % Arguments of the removed v3 form (any of them stops with an error).
            end
            arguments (Output)
                obj  % CPF solver with an empty LoadBus.
            end
            v3_cpf_constructor(varargin);       % COMPAT(v3)
        end

        [result,flag,output] = solve(obj, net, sct_options)
    end
end
