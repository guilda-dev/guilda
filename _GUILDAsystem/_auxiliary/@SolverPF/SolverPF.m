classdef SolverPF < auxiliary
% Solver of the power flow calculation (net.calculate_powerflow).
%
% net.solver_PF holds one. It does only the numerics: solve takes the bus admittance
% matrix, the power flow conditions of the buses and the settings of the run, builds the
% power equations and runs the Method class. It never reads the network:
% net.calculate_powerflow selects the slack bus, assembles the inputs, notifies a failure
% (WhenFailed) and builds the output in the requested Format. It stores no numerical
% settings: the settings of each run are the PowerFlowCalculation section of
% GUILDA.setting (GUILDA.config("PowerFlowCalculation")), with the Name-Value options of
% the call applied to that call only (the arguments block of
% PowerNetwork.calculate_powerflow).
%
% - `Solver`: the algorithm that solves the power equations (see the table). Every
%   solver except "fsolve" runs on MATLAB alone; "fsolve" needs Optimization Toolbox.
%
%   | Solver                | Class (algorithm)                                       | MaxIteration NaN (auto)    |
%   |-----------------------|---------------------------------------------------------|----------------------------|
%   | "newton"              | MethodNewtonRaphson (analytic Jacobian)                 | 50                         |
%   | "gradient"            | MethodGradient (theta += alpha*dP, V += alpha*dQ./V)    | 1e6                        |
%   | "levenberg-marquardt" | MethodLevenbergMarquardt (analytic Jacobian)            | 100                        |
%   | "fsolve"              | MethodFsolve (fsolve, analytic Jacobian)                | 400                        |
%   | "dynamic"             | MethodDynamic (virtual bus dynamics, ode15s)            | not used                   |
%
% - `Tolerance` [pu]: every method converges when the largest P/Q mismatch is at most
%   Tolerance ("newton", "levenberg-marquardt" and "fsolve" also count the set |V| and
%   slack angle residuals). "fsolve" also passes Tolerance^2 as FunctionTolerance and OptimalityTolerance of fsolve and
%   checks the mismatch after fsolve stops. "dynamic" tightens its ODE tolerances with it.
% - `WarmStart`: true starts from the last converged solution, kept by the solver, when
%   it was solved for the same bus tags (in the same order); false, a different bus list
%   or no kept solution is the flat start: angle 0 and magnitude 1, with
%   the set V at PV and slack buses and the set angle at the slack bus. "gradient" and
%   "dynamic" always start the fixed values (slack angle and voltage, PV voltages) at
%   their set values.
% - The solver keeps only the last converged solution and its bus tags (the warm start).
%   The power equations are built at every call. net.reset_solver() discards the kept
%   solution.
% - Settings of one method, named <Solver><option>: NewtonStepSize (StepSize of
%   MethodNewtonRaphson), GradientStepSize (alpha of MethodGradient; NaN uses
%   0.5/(max|Y_ii|*Vmax^2), Vmax the largest set bus voltage or 1), FsolveUseParallel and
%   FsolveMaxFunctionEvaluations (fsolve; NaN keeps the fsolve default). NaN is the
%   automatic value of every setting that has one (MaxIteration too).
%   "gradient" converges linearly: it needs thousands of iterations on 10-bus networks.
% - For "newton", a singular Jacobian (an island without a slack bus) gives minimum norm
%   steps. A non-slack bus without branches has no determined voltage: every method
%   returns flag -2 without solving. "gradient" fixes the slack angle and voltage and the
%   PV voltages, and updates the angle only at PV buses.
% - `Verbose` (Display "iter" or "none" of the Method class): true prints one line per iteration for "newton", "gradient"
%   and "levenberg-marquardt" (the fsolve display for "fsolve"), and the final message.
% - Outputs of solve: the complex bus voltages, flag, output, the voltages at each
%   iteration (cm_Vhistory) and the iteration numbers or virtual times (rv_step).
% - flag: 1 converged, 0 MaxIteration reached (for "dynamic", its virtual time limit),
%   -1 stopped by PlotFcn, -2 diverged or no solution found; the Method classes set flag
%   and output (see MethodBase).
% - `PlotFcn` (live display, every Solver): "residual" draws one bar per power equation
%   (two per bus: P, or the angle at the slack bus; Q, or |V| at PV and slack buses) with
%   its |residual| at the iterate, on a log scale with Tolerance as a line, in one reused
%   figure updated during the iterations ("dynamic": along the virtual time). A function
%   handle is called at every iterate as stop = f(x, optimValues, state): x the complex
%   bus voltages, optimValues.iteration, .fval (residuals), .residual (largest |residual|)
%   and, for "dynamic", .time (virtual time); state "init", "iter" or "done". A true stop
%   ends the calculation with flag -1. "none" leaves the calculation as it is.
% - solve takes the Name-Value options of net.calculate_powerflow as they are (Solver,
%   Tolerance, MaxIteration, Verbose, WarmStart, PlotFcn). The settings without an option
%   (<Solver><option>) are read from GUILDA.config where they are used.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% res = net.calculate_powerflow();                                       % GUILDA.setting
% res = net.calculate_powerflow(Solver="dynamic", Verbose=true);         % this call only
% res = net.calculate_powerflow(WarmStart=false);                        % flat start
% % the solver alone: admittance matrix, conditions and settings assembled by the caller
% tab = tools.vcellfun(@(b) b.get_pf_condition, net.a_Bus);
% tab_Y = net.get_admittance_matrix;
% sct = struct("Solver","newton","Tolerance",1e-8,"MaxIteration",NaN,"Verbose",false, ...
%     "WarmStart",false,"PlotFcn","none");
% cv_V = net.solver_PF.solve(tab_Y{:,:}, tab, sct);
% ```
%
% See also ResultPF, PowerNetwork.calculate_powerflow, MethodNewtonRaphson, MethodGradient,
% MethodLevenbergMarquardt, MethodFsolve, MethodDynamic, MethodBase

    properties(Access=private) % Warm start
        cv_Vwarm (:,1) double = zeros(0,1)      % [pu] Last converged bus voltages; empty when none.
        sv_warmBus (:,1) string = strings(0,1)  % Bus tags of cv_Vwarm (row names of the tab_PFcondition it was solved for).
    end

    methods
        function obj = SolverPF()
        % Create a power flow solver.
        %
        % A network creates its own (net.solver_PF); net.reset_solver() replaces it with a
        % new one, which discards the warm start solution.
            arguments (Output)
                obj                        % Power flow solver.
            end
        end

        [cv_V, flag, output, cm_Vhistory, rv_step] = solve(obj, cm_Y, tab_PFcondition, sct_options)
    end
end
