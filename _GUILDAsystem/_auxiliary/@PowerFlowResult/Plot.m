function fig = Plot(obj, opt)
% Plot the bus voltage profile.
%
% Draws the voltage profile of the solution: the voltage magnitude [pu] and the phase
% angle [deg] of each bus, as bar charts in two tiles.
% calculate_powerflow(..., Plot=true) calls it.
    arguments
        obj
        opt.Parent = [] % Container to draw in. A new figure when empty.
    end
    arguments (Output)
        fig % Layout holding the two axes (magnitude, angle).
    end
    if isempty(opt.Parent)
        opt.Parent = figure();
    end

    str_bus = string(obj.tab_bus.Properties.RowNames);
    x       = categorical(str_bus, str_bus);

    fig = tiledlayout(opt.Parent, 2, 1, "TileSpacing", "compact");
    str_title = "Power flow";
    if isfield(obj.options, "Method")
        str_title = str_title + " (" + obj.options.Method + ")";
    end
    if ~obj.l_success
        str_title = str_title + " - not converged";
    end
    title(fig, str_title);

    ax = nexttile(fig);
    bar(ax, x, obj.tab_bus.V);
    ylabel(ax, "|V| [pu]");
    grid(ax, "on");

    ax = nexttile(fig);
    bar(ax, x, rad2deg(obj.tab_bus.Varg));
    ylabel(ax, "\angleV [deg]");
    grid(ax, "on");
end
