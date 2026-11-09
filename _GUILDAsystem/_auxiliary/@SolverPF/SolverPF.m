classdef SolverPF < auxiliary
% Solver of the power flow calculation (net.calculate_powerflow).
%
% net.solver_PF holds one. It stores no numerical settings: the settings of each run are
% the PowerFlowCalculation section of GUILDA.setting (GUILDA.config("PowerFlowCalculation")),
% with the Name-Value options of the call applied to that call only (see OptionMap and
% get_options). Results are returned as a ResultPF.
%
% - `Method`: how the power equations are solved (see the table). Every method except
%   "fsolve" runs on MATLAB alone; "fsolve" needs Optimization Toolbox.
%
%   | Method                | Class (algorithm)                                       | MaxIteration 0 (automatic) |
%   |-----------------------|---------------------------------------------------------|----------------------------|
%   | "newton"              | MethodNewtonRaphson (analytic Jacobian)                 | 50                         |
%   | "gradient"            | MethodGradient (theta += alpha*dP, V += alpha*dQ./V)    | 1e6                        |
%   | "levenberg-marquardt" | MethodLevenbergMarquardt (analytic Jacobian)            | 100                        |
%   | "fsolve"              | MethodFsolve (fsolve, analytic Jacobian)                | 400                        |
%   | "dynamic"             | MethodDynamic (virtual bus dynamics, ode15s)            | not used                   |
%
% - `Tolerance` [pu]: every method converges when the largest P/Q mismatch is at most
%   Tolerance ("newton", "levenberg-marquardt" and "fsolve" also count the set |V| and
%   slack angle residuals). "fsolve" also passes it as FunctionTolerance of fsolve and
%   checks the mismatch after fsolve stops. "dynamic" tightens its ODE tolerances with it.
% - `WarmStart`: true starts from the last converged solution of this network, kept by the
%   solver; false, or no kept solution, is the flat start: angle 0 and magnitude 1, with
%   the set V at PV and slack buses and the set angle at the slack bus. "gradient" and
%   "dynamic" always start the fixed values (slack angle and voltage, PV voltages) at
%   their set values.
% - The solver keeps, between runs on the same network: the last converged solution
%   (discarded only when buses or branches are added, removed or replaced; buses are
%   matched by object, not by tag), the bus admittance matrix and the power equations
%   (rebuilt after the edits that change them, see PowerNetwork.handle_edit).
%   net.reset_solver() discards them.
% - Settings of one method: NewtonStepSize (StepSize of MethodNewtonRaphson),
%   GradientStepSize (alpha of MethodGradient; 0 uses 0.5/(max|Y_ii|*Vmax^2), Vmax the
%   largest set bus voltage or 1), FsolveUseParallel and FsolveMaxFunEvals (fsolve).
%   "gradient" converges linearly: it needs thousands of iterations on 10-bus networks.
% - For "newton", a singular Jacobian (an island without a slack bus) gives minimum norm
%   steps. A non-slack bus without branches has no determined voltage: every method
%   returns flag -2 without solving. "gradient" fixes the slack angle and voltage and the
%   PV voltages, and updates the angle only at PV buses.
% - `Verbose` (Display): "iter" prints one line per iteration for "newton", "gradient"
%   and "levenberg-marquardt" (the fsolve display for "fsolve"), and the final message.
% - flag: 1 converged, 0 MaxIteration reached (for "dynamic", its virtual time limit),
%   -2 diverged or no solution found; the Method classes set flag and output (see
%   MethodBase).
% - `OptionMap` is the input of tools.resolve_options. Verbose=true sets Display="iter",
%   Verbose=false sets Display="none".
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% result = net.calculate_powerflow();                                  % GUILDA.setting
% result = net.calculate_powerflow(Method="dynamic", Verbose=true);    % this call only
% result = net.calculate_powerflow(WarmStart=false);                   % flat start
% ```
%
% See also ResultPF, PowerNetwork.calculate_powerflow, MethodNewtonRaphson, MethodGradient,
% MethodLevenbergMarquardt, MethodFsolve, MethodDynamic, MethodBase

    properties(Constant) % Settings
        OptionMap = struct( ...
            "Method",       "Method", ...
            "Tolerance",    "Tolerance", ...
            "MaxIteration", "MaxIteration", ...
            "Verbose",      {{"Display", @(l) replace(string(logical(l)), ["true","false"], ["iter","none"])}}, ...
            "WarmStart",    "WarmStart")    % Name-Value options of net.calculate_powerflow and the setting each one sets (see the class help). <@Type> struct
    end

    properties(Access=private) % Warm start and cache
        a_Bus (:,1) cell = cell(0,1)        % Buses of the network the data below belongs to, in its bus order.
        n_revTopology (1,1) double = NaN    % Topology revision of the network when a_Bus was taken.
        cv_Vwarm (:,1) double = zeros(0,1)  % [pu] Last converged bus voltages (a_Bus order); empty when none.
        n_revY (1,1) double = NaN           % Admittance revision of the network when cm_Y was built.
        cm_Y (:,:) double = zeros(0,0)      % [pu] Cached bus admittance matrix (a_Bus order).
        n_revPF (1,1) double = NaN          % Power flow revision of the network when sct_equation was built.
        sct_equation struct = struct([])    % Cached power flow conditions and equations (tab, f_res, f_jac, f_grad).
    end

    methods
        function obj = SolverPF()
        % Create a power flow solver.
        %
        % A network creates its own (net.solver_PF); net.reset_solver() replaces it with a
        % new one, which discards the warm start solution and the cache.
            arguments (Output)
                obj                        % Power flow solver.
            end
        end

        sct_options = get_options(obj, nv)
        [result,flag,output] = solve(obj, net, sct_options)
    end
end
