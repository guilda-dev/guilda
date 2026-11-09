classdef (Sealed = true) SolverCPF < auxiliary
% Solver of the continuation power flow (CPF).
%
% Starting from the equilibrium found by net.initialize, it scales the loads of LoadBus by
% (1 + lambda) and traces the power flow solution with a predictor-corrector method past
% the maximum loading point (the nose of the PV curve). net.solver_CPF holds one; its
% properties are the stored defaults of net.calculate_continuation_powerflow and are kept
% between runs. Name-Value options of a call override them for that call only (see
% OptionMap and get_options). The solver holds settings only: results are returned as a
% ResultCPF.
%
% - The power the components of the `LoadBus` buses draw is multiplied by (1 + lambda).
% - `StepSize` multiplies the tangent at the first step and the secant from the previous
%   step afterwards. The trace stops before `MaxIterations` when lambda falls below 0 after
%   the nose.
% - With `UseInternalState` true, the generator powers follow their state equations
%   (getCompPQ) and all loads are scaled; when false, the components inject their
%   equilibrium powers. True stops with GUILDA:build_layout:MissingGetCompPQ if a component
%   has no getCompPQ.
% - `OptionMap` is the input of tools.resolve_options. MaxIteration, Tolerance and Verbose
%   are common names; LoadBus, InitialLambda, StepSize, ArcLength and UseInternalState have
%   no common equivalent.
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
% See also ResultCPF, PowerNetwork.calculate_continuation_powerflow

    properties (Access=public) % Settings
        LoadBus (1,:) string = strings(1,0)                              % Tags of the buses whose loads are scaled by (1 + lambda); must not be empty when solving.
        InitialLambda (1,1) double = 0                                   % Value of lambda at the starting point (the equilibrium).
        MaxIterations (1,1) double {mustBePositive,mustBeInteger} = 500  % Maximum number of predictor-corrector steps (the trace stops earlier when lambda falls below 0).
        StepSize (1,1) double {mustBePositive} = 0.5                     % Step size of the predictor (see the class help).
        ArcLength (1,1) double {mustBePositive} = 1e-3                   % Arc length of the corrector: the corrected point satisfies |x - x_current|^2 = ArcLength.
        Tolerance (1,1) double {mustBePositive} = 1e-5                   % Tolerance of the largest residual of the Newton-Raphson corrector (its ConvTol).
        UseInternalState (1,1) logical = false                           % Solve the power flow with the internal states of the generators (see the class help).
        Verbose (1,1) logical = false                                    % Print lambda at each step.
    end

    properties (Constant) % Settings
        OptionMap = struct( ...
            "LoadBus",          {{"LoadBus", @(b) reshape(string(b), 1, [])}}, ...
            "MaxIteration",     "MaxIterations", ...
            "Tolerance",        "Tolerance", ...
            "StepSize",         "StepSize", ...
            "ArcLength",        "ArcLength", ...
            "InitialLambda",    "InitialLambda", ...
            "UseInternalState", "UseInternalState", ...
            "Verbose",          "Verbose")                               % Name-Value options of net.calculate_continuation_powerflow and the property each one sets. <@Type> struct
    end

    methods
        function obj = SolverCPF(varargin)
        % Create a CPF solver with the defaults of GUILDA.config("ContinuationPowerFlow").
        %
        % A network creates its own (net.solver_CPF); net.reset_solver() replaces it with a
        % new one. Any argument (the v3 form SolverCPF(net, Name, Value)) stops with
        % GUILDA:v3_cpf_constructor:ContinuationPowerFlowConstructor.
            arguments (Input, Repeating)
                varargin  % Arguments of the removed v3 form (any of them stops with an error).
            end
            arguments (Output)
                obj  % CPF solver with the configured defaults.
            end
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

        sct_options = get_options(obj, nv)
        [result,flag,output] = solve(obj, net, sct_options)
    end
end
