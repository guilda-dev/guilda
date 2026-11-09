classdef SolverPF < auxiliary
% Solver of the power flow calculation (net.calculate_powerflow).
%
% net.solver_PF holds one; its properties are the stored defaults of
% net.calculate_powerflow and are kept between runs. Name-Value options of a call override
% them for that call only (see OptionMap and get_options). The solver holds settings only:
% results are returned as a ResultPF.
%
% - `Method`: how the power equations are solved (see the table). Every method except
%   "fsolve" runs on MATLAB alone; "fsolve" needs Optimization Toolbox.
%
%   | Method                | Class (algorithm)                                       | Tolerance (default)                     | MaxIterations (default) |
%   |-----------------------|---------------------------------------------------------|-----------------------------------------|-------------------------|
%   | "newton"              | MethodNewtonRaphson (analytic Jacobian)                 | largest P/Q mismatch [pu] (1e-8)        | 50                      |
%   | "gradient"            | MethodGradient (theta += alpha*dP, V += alpha*dQ./V)    | largest P/Q mismatch [pu] (1e-8)        | 1e6                     |
%   | "levenberg-marquardt" | MethodLevenbergMarquardt (analytic Jacobian)            | largest P/Q mismatch [pu] (1e-8)        | 100                     |
%   | "fsolve"              | MethodFsolve (fsolve, analytic Jacobian)                | largest P/Q mismatch [pu] (1e-6)        | fsolve default (400)    |
%   | "dynamic"             | MethodDynamic (virtual bus dynamics, ode15s)            | largest P/Q mismatch [pu] (1e-5)        | not used                |
%
%   0 for Tolerance or MaxIterations uses the default of the method. "fsolve" also passes
%   Tolerance as FunctionTolerance of fsolve. For "newton", a
%   singular Jacobian (an island without a slack bus) gives minimum norm steps. A non-slack bus without branches has no
%   determined voltage: every method returns flag -2 (false for "dynamic") without solving. solve creates the
%   Method object from the settings for each run. The residual and Jacobian of the power
%   equations (x = real and imaginary parts of the bus voltages) are shared by "newton",
%   "levenberg-marquardt" and "fsolve". "gradient" fixes the slack angle and voltage and
%   the PV voltages, and updates the angle only at PV buses.
% - `gradient` has the field StepSize (alpha of MethodGradient; 0 uses 0.5/(max|Y_ii|*Vmax^2),
%   Vmax the largest set or initial bus voltage). "gradient" converges linearly: it needs
%   thousands of iterations on 10-bus networks and more on larger ones.
% - `dynamic` has the fields Mass, Damper, foh_PQ and t_span of MethodDynamic.
% - `Display`: "iter" and "iter-detailed" print one line per iteration for "newton",
%   "gradient" and "levenberg-marquardt", and every value but "none" prints the final
%   message. Display, MaxFunEvals, UseParallel and PlotFcn are passed to fsolve.
% - flag: 1 converged, 0 MaxIterations reached, -2 diverged or no solution found
%   (logical for "dynamic"); the Method classes set flag and output (see MethodBase).
% - `OptionMap` is the input of tools.resolve_options. Only the common option names are
%   used. Verbose=true sets Display="iter", Verbose=false sets Display="none".
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.solver_PF.WhenFailed = "WARN";            % stored default, kept between runs
% result = net.calculate_powerflow();
% result = net.calculate_powerflow(Method="dynamic", Verbose=true);   % this call only
% ```
%
% See also ResultPF, PowerNetwork.calculate_powerflow, MethodNewtonRaphson, MethodGradient,
% MethodLevenbergMarquardt, MethodFsolve, MethodDynamic, MethodBase

    properties(Access=public) % Settings
        Method (1,1) string {mustBeMember(Method,["newton","gradient","levenberg-marquardt","fsolve","dynamic"])} = "newton"                                         % Calculation method: "newton", "gradient", "levenberg-marquardt", "fsolve" or "dynamic" (see the class help).
        Tolerance (1,1) double {mustBeNonnegative} = 0                                                                                                               % Convergence tolerance; 0 uses the solver default (see the class help).
        MaxIterations (1,1) double {mustBeNonnegative,mustBeInteger}                                                                                                 % Maximum number of iterations of "newton", "gradient", "levenberg-marquardt" and "fsolve"; 0 uses the method default (see the class help).
        Display (1,1) string {mustBeMember(Display,["none","iter","iter-detailed","final","final-detailed"])}='none'                                                 % Progress display: "iter"/"iter-detailed" print each iteration; Display option of fsolve.
        MaxFunEvals (1,1) double {mustBeNonnegative,mustBeInteger}                                                                                                   % MaxFunctionEvaluations option of fsolve ("fsolve"); 0 keeps the fsolve default.
        UseParallel (1,1) logical                                                                                                                                    % UseParallel option of fsolve ("fsolve").
        PlotFcn (1,1) string {mustBeMember(PlotFcn,["none","optimplotx","optimplotfunccount","optimplotfval","optimplotstepsize","optimplotfirstorderopt"])}="none"  % PlotFcn option of fsolve ("fsolve"); "none" for no plot.
        WhenFailed (1,1) string {mustBeMember(WhenFailed,["WARN","ERROR","DISP","NONE"])}="NONE"                                                                     % Reaction to no convergence: "WARN", "ERROR", "DISP" (print output.message) or "NONE" (check flag).
        gradient (1,1) struct = struct("StepSize",0);                                                                                                                % Settings of the "gradient" method: StepSize (alpha; 0 uses the default of the class help).
        dynamic (1,1) struct = struct("Mass",0,"Damper",0.1,"foh_PQ",0,"t_span",0:1/120:50);                                                                         % Settings of the "dynamic" method: Mass, Damper, foh_PQ and t_span [s] (see the class help).
    end

    properties(Constant) % Settings
        OptionMap = struct( ...
            "Method",       "Method", ...
            "Tolerance",    "Tolerance", ...
            "MaxIteration", "MaxIterations", ...
            "Verbose",      {{"Display", @(l) replace(string(logical(l)), ["true","false"], ["iter","none"])}})                                                      % Name-Value options of net.calculate_powerflow and the property each one sets (see the class help). <@Type> struct
    end

    methods
        function obj = SolverPF()
        % Create a power flow solver with the defaults of GUILDA.config("PowerFlowCalculation").
        %
        % A network creates its own (net.solver_PF); net.reset_solver() replaces it with a
        % new one.
            arguments (Output)
                obj  % Power flow solver with the configured defaults.
            end
            sct = GUILDA.config("PowerFlowCalculation");
            obj.Method        = sct.Method.Value;
            obj.Tolerance     = sct.Tolerance.Value;
            obj.MaxIterations = sct.MaxIterations.Value;
            obj.Display       = sct.Display.Value;
            obj.MaxFunEvals   = sct.MaxFunEvals.Value;
            obj.UseParallel   = sct.UseParallel.Value;
            obj.PlotFcn       = sct.PlotFcn.Value;
            obj.WhenFailed    = sct.WhenFailed.Value;
        end

        sct_options = get_options(obj, nv)
        [result,flag,output] = solve(obj, net, sct_options)
    end
end
