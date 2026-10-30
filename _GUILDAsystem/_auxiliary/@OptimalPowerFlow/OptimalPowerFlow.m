classdef OptimalPowerFlow < auxiliary
% <@Desc>
% Solver of the optimal power flow. net.solver_OPF holds one; its properties are the
% stored defaults of net.optimize_powerflow and are kept between runs. Name-Value options
% of a call override them for that call only (see OptionMap and get_options). The solver
% holds settings only: the optimization problem is built by build_opf_problem of the
% network, buses, components and branches, and results are returned as an OPFResult.
% <@Role> Class Category
% <@Constructor>
% obj = OptimalPowerFlow()
% Reads the defaults from GUILDA.config("OptimalPowerFlow").

    properties(Access=public)
        % <@Desc> Formulation: "ELD" (economic load dispatch, branches ignored), "DC OPF"
        % (DC approximation: |V| = 1, no losses, b_ij = 1/(X*tap) as in MATPOWER) or "AC OPF" (AC power
        % flow equations).
        % <@Role> Settings
        % <@Type> string
        % <@Size> 1x1
        Method              (1,1) string {mustBeMember(Method,["ELD","DC OPF","AC OPF"])} = "AC OPF"

        % <@Desc> Optimization solver. "auto" uses the solver that solve (Optimization
        % Toolbox) chooses for the problem: linprog, quadprog or fmincon.
        % <@Role> Settings
        % <@Type> string
        % <@Size> 1x1
        Solver              (1,1) string {mustBeMember(Solver,["auto","linprog","quadprog","fmincon"])} = "auto"

        Algorithm_linprog   (1,1) string = "dual-simplex-highs"
        Algorithm_quadprog  (1,1) string = "interior-point-convex"
        Algorithm_fmincon   (1,1) string = "interior-point"

        % <@Desc> Display option of the solver; "default" keeps the default of the solver.
        % <@Role> Settings
        % <@Type> string
        % <@Size> 1x1
        Display             (1,1) string {mustBeMember(Display,["default","none","iter","iter-detailed","final","final-detailed","notify","notify-detailed"])} = "default"

        % <@Desc> MaxIterations option of the solver; NaN keeps the default of the solver.
        % <@Role> Settings
        % <@Type> double
        % <@Size> 1x1
        MaxIteration        (1,1) double = NaN

        % <@Desc> OptimalityTolerance option of the solver; NaN keeps the default of the solver.
        % <@Role> Settings
        % <@Type> double
        % <@Size> 1x1
        OptimalityTolerance (1,1) double = NaN

        StepTolerance          (1,1) double  = NaN
        MaxFunctionEvaluations (1,1) double  = NaN
        UseParallel            (1,1) logical = false
    end

    properties(Constant)
        % <@Desc> Name-Value options of net.optimize_powerflow and the solver property each
        % one sets (input of tools.resolve_options). Only the common option names are used.
        % Tolerance sets OptimalityTolerance; Verbose=true sets Display="iter",
        % Verbose=false sets Display="none".
        % <@Role> Settings
        % <@Type> struct
        % <@Size> 1x1
        OptionMap = struct( ...
            "Method",       "Method", ...
            "Solver",       "Solver", ...
            "Tolerance",    "OptimalityTolerance", ...
            "MaxIteration", "MaxIteration", ...
            "Verbose",      {{"Display", @(l) replace(string(logical(l)), ["true","false"], ["iter","none"])}})
    end

    methods
        function obj = OptimalPowerFlow()
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
        % <@Desc>
        % Effective settings of one run: every stored setting of the solver, with the
        % Name-Value overrides of the call applied. The solver itself is not changed.
        % A name that is not in OptionMap stops with GUILDA:resolve_options:UnknownName;
        % an invalid value stops with the validation error of the option.
        % <@Role> Settings
        % <@Summary> Stored settings + call-time overrides, as a struct.
        % <@Signatures>
        % [
        %   "s_options = get_options(obj)",
        %   "s_options = get_options(obj, {Name1, Value1, ...})"
        % ]
        % <@Parameters>
        % [
        %   {"Name": "obj", "Type": "OptimalPowerFlow", "Description": "Solver holding the defaults (net.solver_OPF).", "Required": true, "Default": "-"},
        %   {"Name": "nv", "Type": "cell", "Description": "Name-Value overrides: Method, Solver, Tolerance, MaxIteration, Verbose.", "Required": false, "Default": "{}"}
        % ]
        % <@Returns>
        % [
        %   {"Name": "s_options", "Type": "struct", "Description": "One field per setting (Method, Solver, Algorithm_*, Display, MaxIteration, ...)."}
        % ]
            arguments
                obj
                nv (1,:) cell = {}
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
