function opt = optimoption(obj)

    if obj.PlotFcn=="none"
        str_PlotFcn = [];
    else
        str_PlotFcn = obj.PlotFcn;
    end
    opt = optimoptions("fsolve",...
                       "UseParallel" , obj.UseParallel  ,...
                       "Display"     , obj.Display      ,...
                       "PlotFcn"     , str_PlotFcn      ,...
                       'SpecifyObjectiveGradient', true );
    if obj.MaxFunEvals ~= 0
        opt = optimoptions(opt,"MaxFunctionEvaluations", obj.MaxFunEvals);
    end
    if obj.MaxIterations ~= 0
        opt = optimoptions(opt, "MaxIterations", obj.MaxIterations);
    end
    if obj.ExportJSON
        opt = optimoptions( opt, "OutputFcn", @obj.OutputFcn );
    end
end