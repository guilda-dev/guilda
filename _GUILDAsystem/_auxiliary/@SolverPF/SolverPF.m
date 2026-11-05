classdef SolverPF < auxiliary
% Solver of the power flow calculation (net.calculate_powerflow).
%
% net.solver_PF holds one; its properties are the stored defaults of
% net.calculate_powerflow and are kept between runs. Name-Value options of a call override
% them for that call only (see OptionMap and get_options). The solver holds settings only:
% results are returned as a ResultPF.
%
% - `Method`: "algebraic" (fsolve on the power equations) or "dynamic" (virtual bus
%   dynamics that settle at the power flow solution).
% - `Tolerance`: "algebraic": FunctionTolerance of fsolve; "dynamic": largest P/Q mismatch
%   [pu]. 0 uses the solver default (1e-6 / 1e-5).
% - `dynamic` has the fields Mass and Damper of the virtual bus dynamics, foh_PQ, and
%   t_span (output times [s] of the integration).
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
% See also ResultPF, PowerNetwork.calculate_powerflow

    properties(Access=public) % Settings
        Method (1,1) string {mustBeMember(Method,["algebraic","dynamic"])} = "algebraic"  % Calculation method: "algebraic" (fsolve) or "dynamic" (virtual bus dynamics; see the class help).
        Tolerance (1,1) double {mustBeNonnegative} = 0  % Convergence tolerance; 0 uses the solver default (see the class help).
        MaxIterations (1,1) double {mustBeNonnegative,mustBeInteger}  % MaxIterations option of fsolve ("algebraic"); 0 keeps the fsolve default.
        Display (1,1) string {mustBeMember(Display,["none","iter","iter-detailed","final","final-detailed"])}='none'  % Display option of fsolve ("algebraic").
        MaxFunEvals (1,1) double {mustBeNonnegative,mustBeInteger}  % MaxFunctionEvaluations option of fsolve ("algebraic"); 0 keeps the fsolve default.
        UseParallel (1,1) logical  % UseParallel option of fsolve ("algebraic").
        PlotFcn (1,1) string {mustBeMember(PlotFcn,["none","optimplotx","optimplotfunccount","optimplotfval","optimplotstepsize","optimplotfirstorderopt"])}="none"  % PlotFcn option of fsolve ("algebraic"); "none" for no plot.
        WhenFailed (1,1) string {mustBeMember(WhenFailed,["WARN","ERROR","DISP","NONE"])}="NONE"  % Reaction to no convergence: "WARN", "ERROR", "DISP" (print output.message) or "NONE" (check flag).
        dynamic (1,1) struct = struct("Mass",0,"Damper",0.1,"foh_PQ",0,"t_span",0:1/120:50);  % Settings of the "dynamic" method: Mass, Damper, foh_PQ and t_span [s] (see the class help).
    end

    properties(Constant) % Settings
        OptionMap = struct( ...
            "Method",       "Method", ...
            "Tolerance",    "Tolerance", ...
            "MaxIteration", "MaxIterations", ...
            "Verbose",      {{"Display", @(l) replace(string(logical(l)), ["true","false"], ["iter","none"])}})  % Name-Value options of net.calculate_powerflow and the property each one sets (see the class help). <@Type> struct
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

        function sct_options = get_options(obj, nv)
        % Get the effective settings of one run as a struct.
        %
        % Every stored setting of the solver, with the Name-Value overrides of the call applied. The solver itself is not changed.
        % A name that is not in OptionMap stops with GUILDA:resolve_options:UnknownName;
        % an invalid value stops with the validation error of the option.
            arguments (Input)
                obj % Solver holding the defaults (net.solver_PF).
                nv (1,:) cell = {} % Name-Value overrides: Method, Tolerance, MaxIteration, Verbose.
            end
            arguments (Output)
                sct_options % One field per setting (Method, Tolerance, MaxIterations, Display, ..., dynamic).
            end
            sct_given = tools.resolve_options(obj, SolverPF.OptionMap, nv);
            validate_options(nv{:});

            mc = metaclass(obj);
            a_prop = mc.PropertyList(~[mc.PropertyList.Constant] & strcmp({mc.PropertyList.SetAccess}, 'public'));
            sct_options = struct();
            for s_prop = string({a_prop.Name})
                if isfield(sct_given, s_prop)
                    sct_options.(s_prop) = sct_given.(s_prop);
                else
                    sct_options.(s_prop) = obj.(s_prop);
                end
            end
            sct_options.Method = string(sct_options.Method);
        end

        [result,flag,output] = solve(obj, net, sct_options)
    end

    methods(Hidden)
        [cv_Vbus,flag,output,cm_Vhistory,rv_step] = solve_algebraic(obj, cm_Y, tab_PFset, sct_options)
        [cv_Vbus,flag,output,cm_Vhistory,rv_step] = solve_dynamic(  obj, cm_Y, tab_PFset, sct_options)
        opt = optimoption(obj, sct_options)
    end
end


function validate_options(opt)
% Value checks of the Name-Value options (names are already checked by resolve_options)
    arguments (Input)
        opt.Method       (1,1) string  {mustBeMember(opt.Method,["algebraic","dynamic"])}
        opt.Tolerance    (1,1) double  {mustBeNonnegative}
        opt.MaxIteration (1,1) double  {mustBeNonnegative,mustBeInteger}
        opt.Verbose      (1,1) logical
    end
end
