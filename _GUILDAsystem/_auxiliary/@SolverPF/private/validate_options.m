function validate_options(opt)
% Value checks of the Name-Value options (names are already checked by resolve_options)
    arguments (Input)
        opt.Solver       (1,1) string  {mustBeMember(opt.Solver,["newton","gradient","levenberg-marquardt","fsolve","dynamic"])}
        opt.Tolerance    (1,1) double  {mustBePositive}
        opt.MaxIteration (1,1) double  {mustBeIntegerOrNaN}
        opt.Verbose      (1,1) logical
        opt.WarmStart    (1,1) logical
        opt.PlotFcn                   % checked by tools.check_plotfcn
    end
end


function mustBeIntegerOrNaN(r)
% NaN (the automatic value) or a nonnegative integer
    if ~isnan(r)
        mustBeNonnegative(r)
        mustBeInteger(r)
    end
end
