classdef SolverOPF < auxiliary
% Solver of the optimal power flow (net.optimize_powerflow).
%
% net.solver_OPF holds one; its properties are the stored defaults of
% net.optimize_powerflow and are kept between runs. Name-Value options of a call override
% them for that call only (see OptionMap and get_options). The solver holds settings only:
% the optimization problem is built by build_opf_problem of the network, buses, components
% and branches, and results are returned as a ResultOPF.
%
% - `Method`: "ELD" (economic load dispatch, branches ignored), "DC OPF" (DC approximation:
%   |V| = 1, no losses, b_ij = 1/(X*tap) as in MATPOWER) or "AC OPF" (AC power flow
%   equations).
% - `Solver` "auto" uses the solver that solve chooses for the problem: linprog, quadprog
%   or fmincon.
% - `OptionMap` is the input of tools.resolve_options. Only the common option names are
%   used. Tolerance sets OptimalityTolerance; Verbose=true sets Display="iter",
%   Verbose=false sets Display="none".
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.solver_OPF.Method = "DC OPF";              % stored default, kept between runs
% result = net.optimize_powerflow();             % uses "DC OPF"
% result = net.optimize_powerflow(Method="ELD", Verbose=true);   % this call only
% ```
%
% See also ResultOPF, PowerNetwork.optimize_powerflow, PowerNetwork.set_opffcn

    properties(Access=public) % Settings
        Method (1,1) string {mustBeMember(Method,["ELD","DC OPF","AC OPF"])} = "AC OPF"  % Formulation of the problem: "ELD", "DC OPF" or "AC OPF" (see the class help).
        Solver (1,1) string {mustBeMember(Solver,["auto","linprog","quadprog","fmincon"])} = "auto"  % Optimization solver; "auto" uses the one that solve (Optimization Toolbox) chooses.
        Algorithm_linprog (1,1) string = "dual-simplex-highs"  % Algorithm option of linprog.
        Algorithm_quadprog (1,1) string = "interior-point-convex"  % Algorithm option of quadprog.
        Algorithm_fmincon (1,1) string = "interior-point"  % Algorithm option of fmincon.
        Display (1,1) string {mustBeMember(Display,["default","none","iter","iter-detailed","final","final-detailed","notify","notify-detailed"])} = "default"  % Display option of the solver; "default" keeps the default of the solver.
        MaxIteration (1,1) double = NaN  % MaxIterations option of the solver; NaN keeps the default of the solver.
        OptimalityTolerance (1,1) double = NaN  % OptimalityTolerance option of the solver; NaN keeps the default of the solver.
        StepTolerance (1,1) double = NaN  % StepTolerance option of the solver; NaN keeps the default.
        MaxFunctionEvaluations (1,1) double = NaN  % MaxFunctionEvaluations option of the solver; NaN keeps the default.
        UseParallel (1,1) logical = false  % UseParallel option of fmincon (other solvers ignore it).
    end

    properties(Constant) % Settings
        OptionMap = struct( ...
            "Method",       "Method", ...
            "Solver",       "Solver", ...
            "Tolerance",    "OptimalityTolerance", ...
            "MaxIteration", "MaxIteration", ...
            "Verbose",      {{"Display", @(l) replace(string(logical(l)), ["true","false"], ["iter","none"])}})  % Name-Value options of net.optimize_powerflow and the property each one sets (see the class help). <@Type> struct
    end

    methods
        function obj = SolverOPF()
        % Create an OPF solver with the defaults of GUILDA.config("OptimalPowerFlow").
        %
        % A network creates its own (net.solver_OPF); net.reset_solver() replaces it with a
        % new one.
            arguments (Output)
                obj  % OPF solver with the configured defaults.
            end
            sct = GUILDA.config("OptimalPowerFlow");
            obj.Method                 = sct.Method.Value;
            obj.Solver                 = sct.Solver.Value;
            obj.Algorithm_linprog      = sct.Algorithm_linprog.Value;
            obj.Algorithm_quadprog     = sct.Algorithm_quadprog.Value;
            obj.Algorithm_fmincon      = sct.Algorithm_fmincon.Value;
            obj.Display                = sct.Display.Value;
            obj.MaxIteration           = sct.MaxIteration.Value;
            obj.OptimalityTolerance    = sct.OptimalityTolerance.Value;
            obj.StepTolerance          = sct.StepTolerance.Value;
            obj.MaxFunctionEvaluations = sct.MaxFunctionEvaluations.Value;
            obj.UseParallel            = sct.UseParallel.Value;
        end

        sct_options = get_options(obj, nv)
        [result,flag,output] = solve(obj, net, sct_options)
    end

    methods(Hidden)
        [s_solver, c_nv] = optimoption(obj, prob, sct_options)
    end
end
