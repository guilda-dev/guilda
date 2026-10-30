classdef ContinuationPowerFlowV3 < handle
% v3 view of the continuation power flow, returned by Continuation_Power_Flow(net, opt).
%
% It keeps the v3 option names (CPFBus, CPFInitLam, CPFMaxIter, CPFStepSize, CPFArcL,
% CPFUseInternal), `[sol, sol_pred] = solve(obj)` and `CPF_Result.x_sol` / `x_prd`.
% solve runs net.calculate_continuation_powerflow with these options; net.solver_CPF is
% not changed. Differences from v3: sol and sol_pred are in the full variable layout
% (the same as CPF_Result.x_sol / x_prd, lambda in the last row), CPF_Result.result holds
% the CPFResult, and an empty CPFBus stops with an error instead of a warning. The v3
% options CPFFcn, CPFJac and CPFInitVal are not supported.
%
% <@Examples>
% ```matlab
% cpf = Continuation_Power_Flow(net, struct("CPFBus", ["B009","B010"]));
% [sol, sol_pred] = cpf.solve;
% ```
%
% <@Deprecated>
% Use net.calculate_continuation_powerflow(LoadBus=sv_bus), which returns a CPFResult.
%
% See also Continuation_Power_Flow, PowerNetwork.calculate_continuation_powerflow, CPFResult

    properties (Access=public) % Options
        CPFBus         (:,1) string = strings(0,1)   % Tags of the buses whose loads are scaled (LoadBus).
        CPFInitLam     (1,1) double = 0              % lambda at the starting point (InitialLambda).
        CPFMaxIter     (1,1) {mustBePositive} = 500  % Maximum number of predictor-corrector steps (MaxIteration).
        CPFStepSize    (1,1) {mustBePositive} = 0.5  % Step size of the predictor (StepSize).
        CPFArcL        (1,1) {mustBePositive} = 10^-3   % Arc length of the corrector (ArcLength).
        CPFUseInternal (1,1) logical = false         % Solve with the internal states of the generators (UseInternalState).
    end
    properties (SetAccess=private) % Result
        CPFNet                                       % Network to analyse.
        CPF_Result = struct("x_sol", [], "x_prd", [], "result", [])   % Result of the last solve: x_sol, x_prd and the CPFResult.
    end

    methods
        function obj = ContinuationPowerFlowV3(net, opt)
            % Create the v3 view for a network with the given v3 options.
            arguments
                net                 % Network to analyse.
                opt.CPFBus          % Tags of the buses whose loads are scaled.
                opt.CPFInitLam      % lambda at the starting point.
                opt.CPFMaxIter      % Maximum number of predictor-corrector steps.
                opt.CPFStepSize     % Step size of the predictor.
                opt.CPFArcL         % Arc length of the corrector.
                opt.CPFUseInternal  % Solve with the internal states of the generators.
            end
            obj.CPFNet = net;
            for str_name = string(fieldnames(opt)).'
                obj.(str_name) = opt.(str_name);
            end
        end

        function [sol, sol_pred] = solve(obj)
            % Run net.calculate_continuation_powerflow with the v3 options.
            %
            % The result is also stored in CPF_Result.
            arguments (Output)
                sol        % Solutions along the path (full variable layout, lambda in the last row).
                sol_pred   % Predicted points along the path, in the same layout.
            end
            res = obj.CPFNet.calculate_continuation_powerflow( ...
                "LoadBus", obj.CPFBus, "InitialLambda", obj.CPFInitLam, ...
                "MaxIteration", obj.CPFMaxIter, "StepSize", obj.CPFStepSize, ...
                "ArcLength", obj.CPFArcL, "UseInternalState", obj.CPFUseInternal);
            obj.CPF_Result = struct("x_sol", res.rm_x, "x_prd", res.rm_xPredicted, "result", res);
            sol      = res.rm_x;
            sol_pred = res.rm_xPredicted;
        end
    end
end
