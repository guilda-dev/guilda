function fig = Plot(obj, opt)
% Plot the component outputs and the bus voltages.
%
% Draws the solution as bar charts: the active power P [pu] of each component (and the
% reactive power Q for "AC OPF"), then for "DC OPF" and "AC OPF" the bus voltage angle
% [deg], and for "AC OPF" the bus voltage magnitude [pu].
% optimize_powerflow(..., Plot=true) calls it.
    arguments (Input)
        obj
        opt.Parent = [] % Container to draw in. A new figure when empty.
    end
    arguments (Output)
        fig % Layout holding the axes: component power, then the voltage angle (DC/AC OPF) and magnitude (AC OPF).
    end
    if isempty(opt.Parent)
        opt.Parent = figure();
    end

    s_method = "";
    if isfield(obj.options, "Method")
        s_method = obj.options.Method;
    end
    l_V   = ismember("Varg", obj.tab_bus.Properties.VariableNames);
    l_AC  = ismember("Q", obj.tab_bus.Properties.VariableNames);
    n_tile = 1 + l_V + l_AC;

    fig = tiledlayout(opt.Parent, n_tile, 1, "TileSpacing", "compact");
    s_title = "Optimal power flow";
    if s_method ~= ""
        s_title = s_title + " (" + s_method + ")";
    end
    if ~isnan(obj.r_cost)
        s_title = s_title + ", cost = " + num2str(obj.r_cost, 6);
    end
    if ~obj.l_success
        s_title = s_title + " - not solved";
    end
    title(fig, s_title);

    % component rows (the branch-end rows are "<branch>_<bus>")
    sv_row  = string(obj.tab_cub.Properties.RowNames);
    lv_com  = true(size(sv_row));
    if ~isempty(obj.tab_branch)
        sv_br  = string(obj.tab_branch.Properties.RowNames);
        lv_com = ~startsWith(sv_row, sv_br + "_");
    end
    x = categorical(sv_row(lv_com), sv_row(lv_com));

    ax = nexttile(fig);
    if l_AC
        bar(ax, x, obj.tab_cub{lv_com, ["P","Q"]});
        legend(ax, ["P","Q"], "Location", "best");
        ylabel(ax, "P, Q [pu]");
    else
        bar(ax, x, obj.tab_cub.P(lv_com));
        ylabel(ax, "P [pu]");
    end
    grid(ax, "on");

    sv_bus = string(obj.tab_bus.Properties.RowNames);
    x = categorical(sv_bus, sv_bus);
    if l_AC
        ax = nexttile(fig);
        bar(ax, x, obj.tab_bus.V);
        ylabel(ax, "|V| [pu]");
        grid(ax, "on");
    end
    if l_V
        ax = nexttile(fig);
        bar(ax, x, rad2deg(obj.tab_bus.Varg));
        ylabel(ax, "\angleV [deg]");
        grid(ax, "on");
    end
end
