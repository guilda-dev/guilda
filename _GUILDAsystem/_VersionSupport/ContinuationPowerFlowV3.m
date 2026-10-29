classdef ContinuationPowerFlowV3 < handle
% <@Desc>
% v3 view of the continuation power flow, returned by Continuation_Power_Flow(net, opt).
% It keeps the v3 option names (CPFBus, CPFInitLam, CPFMaxIter, CPFStepSize, CPFArcL,
% CPFUseInternal), [sol, sol_pred] = solve(obj) and CPF_Result.x_sol / x_prd. solve runs
% net.calculate_continuation_powerflow with these options; net.solver_CPF is not changed.
% Differences from v3: sol and sol_pred are in the full variable layout (the same as
% CPF_Result.x_sol / x_prd, lambda in the last row), CPF_Result.result holds the CPFResult,
% and an empty CPFBus stops with an error instead of a warning. The v3 options CPFFcn,
% CPFJac and CPFInitVal are not supported.
% <@Role> Compatibility
% <@Constructor>
% obj = ContinuationPowerFlowV3(net, Name, Value)

    properties (Access=public)
        CPFBus         (:,1) string = strings(0,1)
        CPFInitLam     (1,1) double = 0
        CPFMaxIter     (1,1) {mustBePositive} = 500
        CPFStepSize    (1,1) {mustBePositive} = 0.5
        CPFArcL        (1,1) {mustBePositive} = 10^-3
        CPFUseInternal (1,1) logical = false
    end
    properties (SetAccess=private)
        CPFNet
        CPF_Result = struct("x_sol", [], "x_prd", [], "result", [])
    end

    methods
        function obj = ContinuationPowerFlowV3(net, opt)
            arguments
                net
                opt.CPFBus
                opt.CPFInitLam
                opt.CPFMaxIter
                opt.CPFStepSize
                opt.CPFArcL
                opt.CPFUseInternal
            end
            obj.CPFNet = net;
            for str_name = string(fieldnames(opt)).'
                obj.(str_name) = opt.(str_name);
            end
        end

        function [sol, sol_pred] = solve(obj)
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
