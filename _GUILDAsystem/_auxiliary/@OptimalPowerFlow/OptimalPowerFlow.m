classdef OptimalPowerFlow < auxiliary
% Solver of the optimal power flow (net.optimize_powerflow).
%
% net.solver_OPF holds one; its properties are the stored defaults of
% net.optimize_powerflow and are kept between runs. Name-Value options of a call override them for that call only (see OptionMap and
% get_options). The solver holds settings only: the optimization problem is built by
% build_opf_problem of the network, buses, components and branches, and results are
% returned as an OPFResult.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.solver_OPF.Method = "DC OPF";              % stored default, kept between runs
% result = net.optimize_powerflow();             % uses "DC OPF"
% result = net.optimize_powerflow(Method="ELD", Verbose=true);   % this call only
% ```
%
% See also OPFResult, PowerNetwork.optimize_powerflow, PowerNetwork.set_opffcn

    properties(Access=public) % Settings
        % Formulation of the problem.
        % "ELD" (economic load dispatch, branches ignored), "DC OPF" (DC approximation: |V| = 1,
        % no losses, b_ij = 1/(X*tap) as in MATPOWER) or "AC OPF" (AC power flow equations).
        Method              (1,1) string {mustBeMember(Method,["ELD","DC OPF","AC OPF"])} = "AC OPF"

        % Optimization solver.
        % "auto" uses the solver that solve (Optimization Toolbox) chooses for the problem:
        % linprog, quadprog or fmincon.
        Solver              (1,1) string {mustBeMember(Solver,["auto","linprog","quadprog","fmincon"])} = "auto"

        Algorithm_linprog   (1,1) string = "dual-simplex-highs"    % Algorithm option of linprog.
        Algorithm_quadprog  (1,1) string = "interior-point-convex" % Algorithm option of quadprog.
        Algorithm_fmincon   (1,1) string = "interior-point"        % Algorithm option of fmincon.

        % Display option of the solver; "default" keeps the default of the solver.
        Display             (1,1) string {mustBeMember(Display,["default","none","iter","iter-detailed","final","final-detailed","notify","notify-detailed"])} = "default"

        % MaxIterations option of the solver; NaN keeps the default of the solver.
        MaxIteration        (1,1) double = NaN

        % OptimalityTolerance option of the solver; NaN keeps the default of the solver.
        OptimalityTolerance (1,1) double = NaN

        StepTolerance          (1,1) double  = NaN   % StepTolerance option of the solver; NaN keeps the default.
        MaxFunctionEvaluations (1,1) double  = NaN   % MaxFunctionEvaluations option of the solver; NaN keeps the default.
        UseParallel            (1,1) logical = false % UseParallel option of fmincon (other solvers ignore it).
    end

    properties(Constant) % Settings
        % Name-Value options of net.optimize_powerflow and the solver property each one sets.
        % Input of tools.resolve_options. Only the common option names are used. Tolerance sets OptimalityTolerance; Verbose=true
        % sets Display="iter", Verbose=false sets Display="none".
        % <@Type> struct
        OptionMap = struct( ...
            "Method",       "Method", ...
            "Solver",       "Solver", ...
            "Tolerance",    "OptimalityTolerance", ...
            "MaxIteration", "MaxIteration", ...
            "Verbose",      {{"Display", @(l) replace(string(logical(l)), ["true","false"], ["iter","none"])}})
    end

    methods
        function obj = OptimalPowerFlow()
        % Create an OPF solver with the defaults of GUILDA.config("OptimalPowerFlow").
        %
        % A network creates its own (net.solver_OPF); net.reset_solver() replaces it with a
        % new one.
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

        function s_options = get_options(obj, nv)
        % Get the effective settings of one run as a struct.
        %
        % Every stored setting of the solver, with the Name-Value overrides of the call applied. The solver itself is not changed.
        % A name that is not in OptionMap stops with GUILDA:resolve_options:UnknownName;
        % an invalid value stops with the validation error of the option.
            arguments
                obj % Solver holding the defaults (net.solver_OPF).
                nv (1,:) cell = {} % Name-Value overrides: Method, Solver, Tolerance, MaxIteration, Verbose.
            end
            arguments (Output)
                s_options % One field per setting (Method, Solver, Algorithm_*, Display, MaxIteration, ...).
            end
            s_given = tools.resolve_options(obj, OptimalPowerFlow.OptionMap, nv);
            validate_options(nv{:});

            mc = metaclass(obj);
            a_prop = mc.PropertyList(~[mc.PropertyList.Constant] & strcmp({mc.PropertyList.SetAccess}, 'public'));
            s_options = struct();
            for str_prop = string({a_prop.Name})
                if isfield(s_given, str_prop)
                    s_options.(str_prop) = s_given.(str_prop);
                else
                    s_options.(str_prop) = obj.(str_prop);
                end
            end
            s_options.Method = string(s_options.Method);
            s_options.Solver = string(s_options.Solver);
        end

        [result,flag,output] = solve(obj, net, s_options)
    end

    methods(Hidden)
        [str_solver, c_nv] = optimoption(obj, prob, s_options)
    end
end


function validate_options(opt)
% Value checks of the Name-Value options (names are already checked by resolve_options)
    arguments
        opt.Method       (1,1) string  {mustBeMember(opt.Method,["ELD","DC OPF","AC OPF"])}
        opt.Solver       (1,1) string  {mustBeMember(opt.Solver,["auto","linprog","quadprog","fmincon"])}
        opt.Tolerance    (1,1) double  {mustBePositive}
        opt.MaxIteration (1,1) double  {mustBePositive,mustBeInteger}
        opt.Verbose      (1,1) logical
    end
end
