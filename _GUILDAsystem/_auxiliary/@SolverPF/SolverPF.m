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
% ```
%
% See also ResultPF, PowerNetwork.calculate_powerflow, MethodNewtonRaphson, MethodGradient,
% MethodLevenbergMarquardt, MethodFsolve, MethodDynamic, MethodBase

    properties(Constant) % Settings
        OptionMap = struct( ...
            "Method",       "Method", ...
            "Tolerance",    "Tolerance", ...
            "MaxIteration", "MaxIteration", ...
            "Verbose",      {{"Display", @(l) replace(string(logical(l)), ["true","false"], ["iter","none"])}})                                              % Name-Value options of net.calculate_powerflow and the setting each one sets (see the class help). <@Type> struct
    end

    methods
        function obj = SolverPF()
        % Create a power flow solver.
        %
        % A network creates its own (net.solver_PF); net.reset_solver() replaces it with a
        % new one.
            arguments (Output)
                obj  % Power flow solver.
            end
        end

        sct_options = get_options(obj, nv)
        [result,flag,output] = solve(obj, net, sct_options)
    end
end
