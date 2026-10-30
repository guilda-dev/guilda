classdef (Sealed = true) ContinuationPowerFlow < auxiliary
% Solver of the continuation power flow (CPF).
%
% Starting from the equilibrium found by net.initialize, it scales the loads of LoadBus by
% (1 + lambda) and traces the power flow solution with a predictor-corrector method past
% the maximum loading point (the nose of the PV curve). net.solver_CPF holds one; its
% properties are the stored defaults of net.calculate_continuation_powerflow and are kept
% between runs. Name-Value options of a call override them for that call only (see
% OptionMap and get_options). The solver holds settings only: results are returned as a
% CPFResult.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% net.solver_CPF.LoadBus = ["B009","B014"];       % stored default, kept between runs
% result = net.calculate_continuation_powerflow();
% result = net.calculate_continuation_powerflow(StepSize=0.1, Verbose=true);   % this call only
% ```
%
% See also CPFResult, PowerNetwork.calculate_continuation_powerflow

    properties (Access=public) % Settings
        % Tags of the buses whose loads are increased.
        % The power the components of these buses draw is multiplied by (1 + lambda). Must not
        % be empty when solving.
        LoadBus          (1,:) string = strings(1,0)

        % Value of lambda at the starting point (the equilibrium).
        InitialLambda    (1,1) double = 0

        % Maximum number of predictor-corrector steps.
        % The trace stops earlier when lambda falls below 0 after the nose.
        MaxIterations    (1,1) double {mustBePositive,mustBeInteger} = 500

        % Step size of the predictor.
        % It multiplies the tangent at the first step and the secant from the previous step
        % afterwards.
        StepSize         (1,1) double {mustBePositive} = 0.5

        % Arc length of the corrector.
        % The corrected point satisfies |x - x_current|^2 = ArcLength.
        ArcLength        (1,1) double {mustBePositive} = 1e-3

        % Convergence tolerance (ConvTol) of the Newton-Raphson corrector.
        Tolerance        (1,1) double {mustBePositive} = 1e-5

        % Solve the power flow with the internal states of the generators.
        % When true, the generator powers follow their state equations (getCompPQ) and all loads
        % are scaled; when false, the components inject their equilibrium powers.
        UseInternalState (1,1) logical = false

        % Print lambda at each step.
        Verbose          (1,1) logical = false
    end

    properties (Constant) % Settings
        % Name-Value options of net.calculate_continuation_powerflow and the solver property each one sets.
        % Input of tools.resolve_options.
        % MaxIteration, Tolerance and Verbose are common names; LoadBus, InitialLambda, StepSize,
        % ArcLength and UseInternalState have no common equivalent.
        % <@Type> struct
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
        function obj = ContinuationPowerFlow(varargin)
        % Create a CPF solver with the defaults of GUILDA.config("ContinuationPowerFlow").
        %
        % A network creates its own (net.solver_CPF); net.reset_solver() replaces it with a
        % new one. Any argument (the v3 form ContinuationPowerFlow(net, Name, Value)) stops with
        % GUILDA:Deprecated:ContinuationPowerFlowConstructor.
            v3_cpf_constructor(varargin);       % COMPAT(v3)
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
        % Get the effective settings of one run as a struct.
        %
        % Every stored setting of the solver, with the Name-Value overrides of the call applied. The solver itself is not changed.
        % A name that is not in OptionMap stops with GUILDA:resolve_options:UnknownName;
        % an invalid value stops with the validation error of the option.
            arguments
                obj % Solver holding the defaults (net.solver_CPF).
                nv (1,:) cell = {} % Name-Value overrides: LoadBus, MaxIteration, Tolerance, StepSize, ArcLength, InitialLambda, UseInternalState, Verbose.
            end
            arguments (Output)
                s_options % One field per setting (LoadBus, InitialLambda, MaxIterations, StepSize, ArcLength, Tolerance, UseInternalState, Verbose).
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
