classdef PowerFlowCalculation < auxiliary
% <@Desc>
% Solver of the power flow calculation. net.solver_PF holds one; its properties are the
% stored defaults of net.calculate_powerflow and are kept between runs. Name-Value options
% of a call override them for that call only (see OptionMap and get_options). The solver
% holds settings only: results are returned as a PowerFlowResult.
% <@Role> Class Category
% <@Constructor>
% obj = PowerFlowCalculation()
% Reads the defaults from GUILDA.config("PowerFlowCalculation").

    properties(Access=public)
        % <@Desc> Calculation method: "algebraic" (fsolve on the power equations) or
        % "dynamic" (virtual bus dynamics that settle at the power flow solution).
        % <@Role> Settings
        % <@Type> string
        % <@Size> 1x1
        Method        (1,1) string {mustBeMember(Method,["algebraic","dynamic"])} = "algebraic"

        % <@Desc> Convergence tolerance. "algebraic": FunctionTolerance of fsolve;
        % "dynamic": largest P/Q mismatch [pu]. 0 uses the solver default (1e-6 / 1e-5).
        % <@Role> Settings
        % <@Type> double
        % <@Size> 1x1
        Tolerance     (1,1) double {mustBeNonnegative} = 0

        MaxIterations (1,1) double {mustBeNonnegative,mustBeInteger}
        Display       (1,1) string {mustBeMember(Display,["none","iter","iter-detailed","final","final-detailed"])}='none'
        MaxFunEvals   (1,1) double {mustBeNonnegative,mustBeInteger}
        UseParallel   (1,1) logical
        PlotFcn       (1,1) string {mustBeMember(PlotFcn,["none","optimplotx","optimplotfunccount","optimplotfval","optimplotstepsize","optimplotfirstorderopt"])}="none"
        WhenFailed    (1,1) string {mustBeMember(WhenFailed,["WARN","ERROR","DISP","NONE"])}="NONE"
        dynamic       (1,1) struct  = struct("Mass",0,"Damper",0.1,"foh_PQ",0,"t_span",0:1/120:50);
    end

    properties(Constant)
        % <@Desc> Name-Value options of net.calculate_powerflow and the solver property each
        % one sets (input of tools.resolve_options). Only the common option names are used.
        % Verbose=true sets Display="iter", Verbose=false sets Display="none".
        % <@Role> Settings
        % <@Type> struct
        % <@Size> 1x1
        OptionMap = struct( ...
            "Method",       "Method", ...
            "Tolerance",    "Tolerance", ...
            "MaxIteration", "MaxIterations", ...
            "Verbose",      {{"Display", @(l) replace(string(logical(l)), ["true","false"], ["iter","none"])}})
    end

    methods
        function obj = PowerFlowCalculation()
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
        %   {"Name": "obj", "Type": "PowerFlowCalculation", "Description": "Solver holding the defaults (net.solver_PF).", "Required": true, "Default": "-"},
        %   {"Name": "nv", "Type": "cell", "Description": "Name-Value overrides: Method, Tolerance, MaxIteration, Verbose.", "Required": false, "Default": "{}"}
        % ]
        % <@Returns>
        % [
        %   {"Name": "s_options", "Type": "struct", "Description": "One field per setting (Method, Tolerance, MaxIterations, Display, ..., dynamic)."}
        % ]
            arguments
                obj
                nv (1,:) cell = {}
            end
            s_given = tools.resolve_options(obj, PowerFlowCalculation.OptionMap, nv);
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
        end

        [result,flag,output] = solve(obj, net, s_options)
    end

    methods(Hidden)
        [cv_Vbus,flag,output,cm_Vhistory,rv_step] = solve_algebraic(obj, cm_Y, tab_PFset, s_options)
        [cv_Vbus,flag,output,cm_Vhistory,rv_step] = solve_dynamic(  obj, cm_Y, tab_PFset, s_options)
        opt = optimoption(obj, s_options)
    end
end


function validate_options(opt)
% Value checks of the Name-Value options (names are already checked by resolve_options)
    arguments
        opt.Method       (1,1) string  {mustBeMember(opt.Method,["algebraic","dynamic"])}
        opt.Tolerance    (1,1) double  {mustBeNonnegative}
        opt.MaxIteration (1,1) double  {mustBeNonnegative,mustBeInteger}
        opt.Verbose      (1,1) logical
    end
end
