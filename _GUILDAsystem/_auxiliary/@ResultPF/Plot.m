function fig = Plot(obj, opt)
% Plot the bus voltage profile.
%
% Draws the voltage profile of the solution: the voltage magnitude [pu] and the phase
% angle [deg] of each bus, as bar charts in two tiles.
% The only figure of the analysis: calculate_powerflow draws none (its PlotFcn is a live
% display during the calculation).
    arguments (Input)
        obj
        opt.Parent = [] % Container to draw in. A new figure when empty.
    end
    arguments (Output)
        fig % Layout holding the two axes (magnitude, angle).
    end
    if isempty(opt.Parent)
        opt.Parent = figure();
    end

    sv_bus  = string(obj.tab_bus.Properties.RowNames);
    x       = categorical(sv_bus, sv_bus);

    fig = tiledlayout(opt.Parent, 2, 1, "TileSpacing", "compact");
    s_title = "Power flow";
    if isfield(obj.options, "Solver")
        s_title = s_title + " (" + obj.options.Solver + ")";
    elseif isfield(obj.options, "Method")
        s_title = s_title + " (" + obj.options.Method + ")";
    end
    if ~obj.l_success
        s_title = s_title + " - not converged";
    end
    title(fig, s_title);

    ax = nexttile(fig);
    bar(ax, x, obj.tab_bus.V);
    ylabel(ax, "|V| [pu]");
    grid(ax, "on");

    ax = nexttile(fig);
    bar(ax, x, rad2deg(obj.tab_bus.Varg));
    ylabel(ax, "\angleV [deg]");
    grid(ax, "on");
end
