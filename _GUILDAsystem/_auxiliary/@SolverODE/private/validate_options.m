function validate_options(opt)
% Value checks of the Name-Value options (names are already checked by resolve_options)
    arguments (Input)
        opt.Solver               (1,1) matlab.ode.SolverID
        opt.SolverOptions        (1,1) matlab.ode.Options
        opt.Tolerance            (1,1) double {mustBePositive, mustBeBetween(opt.Tolerance,1e-15,1e-3,"closed")}
        opt.AbsoluteTolerance    (1,1) double {mustBePositive, mustBeBetween(opt.AbsoluteTolerance,1e-15,1e-3,"closed")}
        opt.SeparateComplexParts (1,1) matlab.lang.OnOffSwitchState
        opt.TimeLimit            (1,1) double {mustBePositive}
        opt.Progress             {mustBeProgress}
        opt.Verbose              (1,1) logical
        opt.PlotFcn                             % checked by tools.check_plotfcn
    end
end
