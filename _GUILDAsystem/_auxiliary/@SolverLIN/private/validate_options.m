function validate_options(opt)
% Value checks of the Name-Value options (names are already checked by resolve_options)
    arguments (Input)
        opt.Method (1,1) string {mustBeMember(opt.Method, ["Kron","Feedback","DAE"])}
        opt.Point
        opt.Coordinate (1,1) string {mustBeMember(opt.Coordinate, ["theta&V","theta&rho","Vre&Vim"])}
    end
end
