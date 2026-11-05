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
