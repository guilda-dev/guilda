function opt = GUILDAoptions_fsolve()
    struct_default    = GUILDA.config("EnvFsolve");

    if struct_default.PlotFcn=="none"
        PlotFcn = [];
    end
    opt = optimoptions("fsolve",...
                       "MaxIterations" , struct_default.MaxIterations,...
                       "UseParallel"   , struct_default.UseParallel  ,...
                       "Display"       , struct_default.Display      ,...
                       "PlotFcn"       , PlotFcn                           );
    
    MaxFunEvals = struct_default.MaxFunEvals;
    if ~isnan(MaxFunEvals)
        opt = optimoptions(opt,"MaxFunctionEvaluations", MaxFunEvals);
    end

end