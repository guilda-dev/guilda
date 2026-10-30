function fig = Plot(obj, opt)
% Plot the eigenvalue map.
%
% Draws the eigenvalue map of the linear model: the finite generalized eigenvalues of
% (A, E) of get_ss(Algorithm) in the complex plane, with the imaginary axis.
% Eigenvalues with a positive real part (larger than Tolerance) are drawn in red.
% net.linearize(..., Plot=true) calls it.
    arguments
        obj
        opt.Algorithm (1,1) string {mustBeMember(opt.Algorithm, ["Kron","Feedback","DAE"])} = "Kron" % Model whose eigenvalues are drawn (the finite ones are the same for all three).
        opt.Tolerance (1,1) double {mustBeNonnegative} = 1e-6 % Real part above which an eigenvalue is drawn as unstable.
        opt.Parent = [] % Container to draw in. A new figure when empty.
    end
    arguments (Output)
        fig % Axes of the map.
    end
    if isempty(opt.Parent)
        opt.Parent = figure();
    end

    sys = obj.get_ss(opt.Algorithm);
    e = eig(sys.A, sys.E);
    e = e(isfinite(e));
    lv_unstable = real(e) > opt.Tolerance;

    fig = axes(opt.Parent);
    hold(fig, "on");
    plot(fig, real(e(~lv_unstable)), imag(e(~lv_unstable)), "x", "Color", [0 0.4470 0.7410]);
    plot(fig, real(e( lv_unstable)), imag(e( lv_unstable)), "x", "Color", [0.8500 0.1 0.1]);
    xline(fig, 0, ":");
    hold(fig, "off");
    grid(fig, "on");
    xlabel(fig, "Real");
    ylabel(fig, "Imag");
    str_title = "Eigenvalues (" + opt.Algorithm + ")";
    if isfield(obj.output, "l_equilibrium") && ~obj.output.l_equilibrium
        str_title = str_title + " at the given point";
    end
    title(fig, str_title);
end
