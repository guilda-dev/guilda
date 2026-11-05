function validate_options(opt)
% Value checks of the Name-Value options (names are already checked by resolve_options)
    arguments (Input)
        opt.LoadBus          {mustBeText}
        opt.MaxIteration     (1,1) double  {mustBePositive,mustBeInteger}
        opt.Tolerance        (1,1) double  {mustBePositive}
        opt.StepSize         (1,1) double  {mustBePositive}
        opt.ArcLength        (1,1) double  {mustBePositive}
        opt.InitialLambda    (1,1) double
        opt.UseInternalState (1,1) logical
        opt.Verbose          (1,1) logical
    end
end
