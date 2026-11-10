function validate_options(opt)
% Value checks of the Name-Value options (names are already checked by resolve_options)
    arguments (Input)
        opt.Method       (1,1) string  {mustBeMember(opt.Method,["ELD","DC OPF","AC OPF"])}
        opt.Solver       (1,1) string  {mustBeMember(opt.Solver,["auto","linprog","quadprog","fmincon"])}
        opt.Tolerance    (1,1) double  {mustBePositiveOrNaN}
        opt.MaxIteration (1,1) double  {mustBePositiveIntegerOrNaN}
        opt.Verbose      (1,1) logical
        opt.Cost                       {mustBeHandleOrEmpty(opt.Cost)}
        opt.Constraint                 {mustBeHandleOrEmpty(opt.Constraint)}
        opt.DefaultCost  (1,1) logical
        opt.ReferenceBus (1,1) string
        opt.PlotFcn                    % checked by tools.check_plotfcn
    end
end


function mustBePositiveOrNaN(r)
% NaN (the default of the solver) or a positive value
    if ~isnan(r)
        mustBePositive(r)
    end
end


function mustBePositiveIntegerOrNaN(r)
% NaN (the default of the solver) or a positive integer
    if ~isnan(r)
        mustBePositive(r)
        mustBeInteger(r)
    end
end
