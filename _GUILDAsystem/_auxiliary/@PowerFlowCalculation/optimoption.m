function opt = optimoption(~, s_options)
% fsolve options of the "algebraic" method from the effective settings s_options
% (see get_options). 0 for MaxIterations, MaxFunEvals or Tolerance keeps the fsolve default.

    if s_options.PlotFcn=="none"
        str_PlotFcn = [];
    else
        str_PlotFcn = s_options.PlotFcn;
    end
    opt = optimoptions("fsolve",...
                       "UseParallel" , s_options.UseParallel  ,...
                       "Display"     , s_options.Display      ,...
                       "PlotFcn"     , str_PlotFcn            ,...
                       'SpecifyObjectiveGradient', true );
    if s_options.MaxFunEvals ~= 0
        opt = optimoptions(opt,"MaxFunctionEvaluations", s_options.MaxFunEvals);
    end
    if s_options.MaxIterations ~= 0
        opt = optimoptions(opt, "MaxIterations", s_options.MaxIterations);
    end
    if s_options.Tolerance ~= 0
        opt = optimoptions(opt, "FunctionTolerance", s_options.Tolerance);
    end
end
