classdef (Sealed = true) ContinuationPowerFlow < auxiliary
% <@Desc>
% Solver of the continuation power flow (CPF). Starting from the equilibrium found by
% net.initialize, it scales the loads of LoadBus by (1 + lambda) and traces the power flow
% solution with a predictor-corrector method past the maximum loading point (the nose of
% the PV curve). net.solver_CPF holds one; its properties are the stored defaults of
% net.calculate_continuation_powerflow and are kept between runs. Name-Value options of a
% call override them for that call only (see OptionMap and get_options). The solver holds
% settings only: results are returned as a CPFResult.
% <@Role> Class Category
% <@Constructor>
% obj = ContinuationPowerFlow()
% Reads the defaults from GUILDA.config("ContinuationPowerFlow").

    properties (Access=public)
        % <@Desc> Tags of the buses whose loads are increased: the power the components of
        % these buses draw is multiplied by (1 + lambda). Must not be empty when solving.
        % <@Role> Settings
        % <@Type> string
        % <@Size> 1xn
        LoadBus          (1,:) string = strings(1,0)

        % <@Desc> Value of lambda at the starting point (the equilibrium).
        % <@Role> Settings
        % <@Type> double
        % <@Size> 1x1
        InitialLambda    (1,1) double = 0

        % <@Desc> Maximum number of predictor-corrector steps. The trace stops earlier when
        % lambda falls below 0 after the nose.
        % <@Role> Settings
        % <@Type> double
        % <@Size> 1x1
        MaxIterations    (1,1) double {mustBePositive,mustBeInteger} = 500

        % <@Desc> Step size of the predictor (multiplies the tangent at the first step and
        % the secant from the previous step afterwards).
        % <@Role> Settings
        % <@Type> double
        % <@Size> 1x1
        StepSize         (1,1) double {mustBePositive} = 0.5

        % <@Desc> Arc length of the corrector: the corrected point satisfies
        % |x - x_current|^2 = ArcLength.
        % <@Role> Settings
        % <@Type> double
        % <@Size> 1x1
        ArcLength        (1,1) double {mustBePositive} = 1e-3

        % <@Desc> Convergence tolerance (ConvTol) of the Newton-Raphson corrector.
        % <@Role> Settings
        % <@Type> double
        % <@Size> 1x1
        Tolerance        (1,1) double {mustBePositive} = 1e-5

        % <@Desc> Solve the power flow with the internal states of the generators: when true,
        % the generator powers follow their state equations (getCompPQ) and all loads are
        % scaled; when false, the components inject their equilibrium powers.
        % <@Role> Settings
        % <@Type> logical
        % <@Size> 1x1
        UseInternalState (1,1) logical = false

        % <@Desc> Print lambda at each step.
        % <@Role> Settings
        % <@Type> logical
        % <@Size> 1x1
        Verbose          (1,1) logical = false
    end

    properties (Constant)
        % <@Desc> Name-Value options of net.calculate_continuation_powerflow and the solver
        % property each one sets (input of tools.resolve_options). MaxIteration, Tolerance
        % and Verbose are common names; LoadBus, InitialLambda, StepSize, ArcLength and
        % UseInternalState have no common equivalent.
        % <@Role> Settings
        % <@Type> struct
        % <@Size> 1x1
        OptionMap = struct( ...
            "LoadBus",          {{"LoadBus", @(b) reshape(string(b), 1, [])}}, ...
            "MaxIteration",     "MaxIterations", ...
            "Tolerance",        "Tolerance", ...
            "StepSize",         "StepSize", ...
            "ArcLength",        "ArcLength", ...
            "InitialLambda",    "InitialLambda", ...
            "UseInternalState", "UseInternalState", ...
            "Verbose",          "Verbose")
    end

    methods
        function obj = ContinuationPowerFlow()
            sct = GUILDA.config("ContinuationPowerFlow");
            sv_bus = string(sct.LoadBus.Value);
            obj.LoadBus          = reshape(sv_bus(~ismissing(sv_bus) & sv_bus ~= ""), 1, []);
            obj.InitialLambda    = sct.InitialLambda.Value;
            obj.MaxIterations    = sct.MaxIterations.Value;
            obj.StepSize         = sct.StepSize.Value;
            obj.ArcLength        = sct.ArcLength.Value;
            obj.Tolerance        = sct.Tolerance.Value;
            obj.UseInternalState = sct.UseInternalState.Value;
            obj.Verbose          = sct.Verbose.Value;
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
        %   {"Name": "obj", "Type": "ContinuationPowerFlow", "Description": "Solver holding the defaults (net.solver_CPF).", "Required": true, "Default": "-"},
        %   {"Name": "nv", "Type": "cell", "Description": "Name-Value overrides: LoadBus, MaxIteration, Tolerance, StepSize, ArcLength, InitialLambda, UseInternalState, Verbose.", "Required": false, "Default": "{}"}
        % ]
        % <@Returns>
        % [
        %   {"Name": "s_options", "Type": "struct", "Description": "One field per setting (LoadBus, InitialLambda, MaxIterations, StepSize, ArcLength, Tolerance, UseInternalState, Verbose)."}
        % ]
            arguments
                obj
                nv (1,:) cell = {}
            end
            s_given = tools.resolve_options(obj, ContinuationPowerFlow.OptionMap, nv);
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
            s_options.LoadBus = reshape(string(s_options.LoadBus), 1, []);
        end

        [result,flag,output] = solve(obj, net, s_options)
    end
end


function validate_options(opt)
% Value checks of the Name-Value options (names are already checked by resolve_options)
    arguments
        opt.LoadBus          {mustBeText}
        opt.MaxIteration     (1,1) double  {mustBePositive,mustBeInteger}
        opt.Tolerance        (1,1) double  {mustBePositive}
        opt.StepSize         (1,1) double  {mustBePositive}
        opt.ArcLength        (1,1) double  {mustBePositive}
        opt.InitialLambda    (1,1) double
        opt.UseInternalState (1,1) logical
        opt.Verbose          (1,1) logical
    end
end
