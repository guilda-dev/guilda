function l = is_numerical_failure(me, o)
% The errors with which the solver gives up on a phase. ode.solve rethrows the errors
% of the right-hand side without its stack, so only the identifier tells them from
% the errors of input functions and models: any other identifier is not one of these.
% The mass matrix error is checked against the phase, as an input function may
% call an ode solver of its own.
    arguments (Input)
        me  (1,1) MException  % Error of the solver.
        o                     % MATLAB ode object of the phase.
    end
    arguments (Output)
        l  (1,1) logical  % True when the solver gave up on the phase.
    end
    s_id = string(me.identifier);
    l = ismember(s_id, ["MATLAB:daeic12:NeedBetterY0", "MATLAB:daeic12:IndexGTOne", ...
                          "MATLAB:daeic3:NeedBetterY0", "MATLAB:daeic3:IndexGTOne", ...
                          "MATLAB:decic:IndexGTOne", "MATLAB:decic:ConvergenceFail"]) ...
        || (ismember(s_id, ["MATLAB:ode15s:MassMatrixAllZero", "MATLAB:ode23t:MassMatrixAllZero"]) ...
            && nnz(o.MassMatrix.MassMatrix) == 0);
end
