function validate_options(opt)
% Value checks of the Name-Value options (names are already checked by resolve_options)
    arguments (Input)
        opt.Method       (1,1) string  {mustBeMember(opt.Method,["ELD","DC OPF","AC OPF"])}
        opt.Solver       (1,1) string  {mustBeMember(opt.Solver,["auto","linprog","quadprog","fmincon"])}
        opt.Tolerance    (1,1) double  {mustBePositive}
        opt.MaxIteration (1,1) double  {mustBePositive,mustBeInteger}
        opt.Verbose      (1,1) logical
    end
end
