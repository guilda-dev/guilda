function opt = optimoption(~, sct_options)
% Build the fsolve options of the "algebraic" method from the effective settings sct_options
% (see get_options). 0 for MaxIterations, MaxFunEvals or Tolerance keeps the fsolve default.

    if sct_options.PlotFcn=="none"
        str_PlotFcn = [];
    else
        str_PlotFcn = sct_options.PlotFcn;
    end
    opt = optimoptions("fsolve",...
                       "UseParallel" , sct_options.UseParallel  ,...
                       "Display"     , sct_options.Display      ,...
                       "PlotFcn"     , str_PlotFcn            ,...
                       'SpecifyObjectiveGradient', true );
    if sct_options.MaxFunEvals ~= 0
        opt = optimoptions(opt,"MaxFunctionEvaluations", sct_options.MaxFunEvals);
    end
    if sct_options.MaxIterations ~= 0
        opt = optimoptions(opt, "MaxIterations", sct_options.MaxIterations);
    end
    if sct_options.Tolerance ~= 0
        opt = optimoptions(opt, "FunctionTolerance", sct_options.Tolerance);
    end
end
