function validate_options(opt)
% Value checks of the Name-Value options (names are already checked by resolve_options)
    arguments (Input)
        opt.Method       (1,1) string  {mustBeMember(opt.Method,["newton","gradient","levenberg-marquardt","fsolve","dynamic"])}
        opt.Tolerance    (1,1) double  {mustBeNonnegative}
        opt.MaxIteration (1,1) double  {mustBeNonnegative,mustBeInteger}
        opt.Verbose      (1,1) logical
    end
end
