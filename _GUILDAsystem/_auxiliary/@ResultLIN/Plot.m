function fig = Plot(obj, opt)
% Plot the eigenvalue map.
%
% Draws the eigenvalue map of the linear model: the finite generalized eigenvalues of
% (A, E) of get_ss(Method) in the complex plane, with the imaginary axis (the port
% model for an object-level result, see ResultLIN). It needs no toolbox.
% Eigenvalues with a positive real part (larger than Tolerance) are drawn in red.
% net.linearize(..., Plot=true) calls it.
    arguments (Input)
        obj
        opt.Method (1,1) string {mustBeMember(opt.Method, ["Kron","Feedback","DAE"])} = default_algorithm(obj) % Model whose eigenvalues are drawn. Default: the Method of the linearization.
        opt.Tolerance (1,1) double {mustBeNonnegative} = 1e-6 % Real part above which an eigenvalue is drawn as unstable.
        opt.Parent = [] % Container to draw in. A new figure when empty.
    end
    arguments (Output)
        fig % Axes of the map.
    end
    if isempty(opt.Parent)
        opt.Parent = figure();
    end

    sys = obj.get_ss(opt.Method, Format="struct");
    e = eig(full(sys.A), full(sys.E));
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
    if isfield(obj.sct_model, "sct_sys")
        s_title = "Eigenvalues (" + obj.output.s_layer + ")";
    else
        s_title = "Eigenvalues (" + opt.Method + ")";
    end
    if isfield(obj.output, "l_equilibrium") && ~obj.output.l_equilibrium
        s_title = s_title + " at the given point";
    end
    title(fig, s_title);
end


function str = default_algorithm(obj)
% Method of the linearization ("Feedback" when the result has none)
    str = "Feedback";
    if isfield(obj.options, "Method")
        str = obj.options.Method;
    end
end
