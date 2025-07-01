function [x,fval,exitflag,output,lambda,grad,hessian] = solve(obj,opt)
    arguments
        obj 
        opt.KeepFiles          (1,1) logical = false
        opt.Algorithm_linprog  (1,1) string {mustBeMember(opt.Algorithm_linprog ,["interior-point-legacy","interior-point","dual-simplex-highs"])} = config.systemFunc.get("Optimization","Algorithm_linprog","Value")               
        opt.Algorithm_quadprog (1,1) string {mustBeMember(opt.Algorithm_quadprog,["active-set","trust-region-reflective","interior-point-convex"])} = config.systemFunc.get("Optimization","Algorithm_quadprog","Value")               
        opt.Algorithm_fmincon  (1,1) string {mustBeMember(opt.Algorithm_fmincon ,["active-set","sqp-codegen","sqp","trust-region-reflective","interior-point"])} = config.systemFunc.get("Optimization","Algorithm_fmincon","Value")               
        opt.Display            (1,1) string {mustBeMember(opt.Display,["none","iter","iter-detailed","final","final-detailed","notify","notify-detailed"])} = config.systemFunc.get("Optimization","Display","Value")
        opt.MaxIteration           (1,1) double = config.systemFunc.get("Optimization","MaxIteration","Value")
        opt.OptimalityTolerance    (1,1) double = config.systemFunc.get("Optimization","OptimalityTolerance","Value")
        opt.StepTolerance          (1,1) double = config.systemFunc.get("Optimization","StepTolerance","Value")
        opt.MaxFunctionEvaluations (1,1) double = config.systemFunc.get("Optimization","MaxFunctionEvaluations","Value")
        opt.UseParallel            (1,1) logical= config.systemFunc.get("Optimization","UseParallel","Value")
    end
    assert( isempty(obj.xsub), config.lang("補助変数が存在するため計画問題が完成されていません。", ...
           "The planning problem is not complete due to the presence of auxiliary variables."))
    
    grad = [];
    hessian = [];
    switch obj.solver
        case "fmincon"
            set = tools.hcellfun(@(c) func(opt,c), {'MaxIteration','OptimalityTolerance','StepTolerance','MaxFunctionEvaluations'});
            option = optimoptions("fmincon", ...
                                "Algorithm", opt.Algorithm_fmincon,...
                                  "Display", opt.Display,...
                              "UseParallel", opt.UseParallel, set{:});
            [x,fval,exitflag,output,lambda,grad,hessian] = obj.fmincon(option,opt.KeepFiles);
        case "quadprog"
            if opt.Display=="notify";          opt.Display="final";          end
            if opt.Display=="notify_detailed"; opt.Display="final_detailed"; end
            set = tools.hcellfun(@(c) func(opt,c), {'MaxIteration','OptimalityTolerance','StepTolerance'});
            option = optimoptions("quadprog", ...
                                 "Algorithm", opt.Algorithm_quadprog,...
                                   "Display", opt.Display, set{:});
            [x,fval,exitflag,output,lambda] = obj.quadprog(option);
        case "linprog"
            if ismember(opt.Display,["notify","notify_detailed","final_detailed"])
                opt.Display="final";
            elseif opt.Display=="iter-detailed"
                opt.Display="iter";
            end
            set = tools.hcellfun(@(c) func(opt,c), {'MaxIteration','OptimalityTolerance'});
            option = optimoptions( "linprog", ...
                                 "Algorithm", opt.Algorithm_quadprog,...
                                   "Display", opt.Display, set{:});
            [x,fval,exitflag,output,lambda] = obj.linprog(option);
    end
    function out = func(opt,field)
        out = {};
        if ~isnan(opt.(field))
            out={field,opt.(field)}; 
        end
    end
end