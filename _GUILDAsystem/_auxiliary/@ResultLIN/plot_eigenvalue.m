function fig = plot_eigenvalue(obj, opt)
% Plot the eigenvalue map.
%
% Draws the eigenvalue map of the linear model: the finite generalized eigenvalues of
% (A, E) of get_ss(Type) in the complex plane, with the imaginary axis (the port
% model for an object-level result, see ResultLIN). It needs no toolbox.
% Eigenvalues with a positive real part (larger than Tolerance) are drawn in red.
% The only figure of the analysis: get_sys draws none (its PlotFcn is a live display
% during the linearization).
    arguments (Input)
        obj
        opt.Type (1,1) string {mustBeMember(opt.Type, ["ODE","DAE"])} = default_type(obj) % Model whose eigenvalues are drawn: "ODE" or "DAE". Default: the Type of the result.
        opt.Tolerance (1,1) double {mustBeNonnegative} = 1e-6 % Real part above which an eigenvalue is drawn as unstable.
        opt.Parent = [] % Container to draw in. A new figure when empty.
    end
    arguments (Output)
        fig % Axes of the map.
    end
    if isempty(opt.Parent)
        opt.Parent = figure();
    end

    sys = obj.get_ss(opt.Type, Format="struct");
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
    if ~(isfield(obj.output, "s_layer") && obj.output.s_layer == "PowerNetwork")
        s_title = "Eigenvalues (" + obj.output.s_layer + ")";
    else
        s_title = "Eigenvalues (" + opt.Type + ")";
    end
    if isfield(obj.output, "l_equilibrium") && ~obj.output.l_equilibrium
        s_title = s_title + " at the given point";
    end
    title(fig, s_title);
end


function str = default_type(obj)
% Type of the linearization ("ODE" when the result has none)
    str = "ODE";
    if isfield(obj.options, "Type")
        str = obj.options.Type;
    end
end
