function G = plot_dispatch(obj, opt)
% Plot the component outputs and the bus voltages.
%
% Draws the solution as bar charts (GraphChart) in panels one above the other: the active
% power P [pu] of each component (and the reactive power Q for "AC OPF", grouped with P,
% with a legend), then for "AC OPF" the bus voltage magnitude [pu], and for "DC OPF" and
% "AC OPF" the bus voltage angle [deg]. The bars are elements of the chart tagged by the
% component or bus (P and Q of a component share its tag). The title shows the method,
% the cost and "not solved" when the OPF failed. The only figure of the analysis:
% calculate_optimal_powerflow draws none (its PlotFcn is a live display during the
% calculation).
%
% <@Examples>
% ```matlab
% res = network.IEEE14bus().calculate_optimal_powerflow(Method="AC OPF");
% G = res.plot_dispatch();
% G.set_style("B001SG1", Color="r");     % the P and Q bars of a component
% ```
%
% See also GraphChart, ResultOPF.plot_lmp, ResultOPF.plot_iteration
    arguments (Input)
        obj
        opt.Parent = []  % Container (figure, uifigure, uipanel, uitab, uigridlayout) to draw in; [] for a new figure.
    end
    arguments (Output)
        G  % The chart (GraphChart): component power, then the voltage magnitude (AC OPF) and angle (DC/AC OPF).
    end
    s_method = "";
    if isfield(obj.options, "Method")
        s_method = obj.options.Method;
    end
    l_V   = ismember("Varg", obj.tab_bus.Properties.VariableNames);
    l_AC  = ismember("Q", obj.tab_bus.Properties.VariableNames);

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

    % component rows (the branch-end rows are "<branch>_<bus>")
    sv_row  = string(obj.tab_cub.Properties.RowNames);
    lv_com  = true(size(sv_row));
    if ~isempty(obj.tab_branch)
        sv_br  = string(obj.tab_branch.Properties.RowNames);
        lv_com = ~startsWith(sv_row, sv_br + "_");
    end
    sv_com = sv_row(lv_com);
    sv_bus = string(obj.tab_bus.Properties.RowNames);

    % panels and bar series: P (and Q, grouped) of the components, |V| (AC) and the angle (DC, AC)
    f_panel  = @(s_ylabel) struct("s_ylabel", s_ylabel, "s_legendLocation", "best");
    f_series = @(i_panel, sv_x, rv_y, s_legend) struct("i_panel", i_panel, "s_type", "bar", "sv_x", sv_x, "rm_y", rv_y, "sv_legend", s_legend);
    sct = struct("s_title", s_title);
    if l_AC
        sct.sct_panel  = f_panel("P, Q [pu]");
        sct.sct_series = [f_series(1, sv_com, obj.tab_cub.P(lv_com), "P"), f_series(1, sv_com, obj.tab_cub.Q(lv_com), "Q")];
        sct.sct_panel(end+1)  = f_panel("|V| [pu]");
        sct.sct_series(end+1) = f_series(2, sv_bus, obj.tab_bus.V, "");
    else
        sct.sct_panel  = f_panel("P [pu]");
        sct.sct_series = f_series(1, sv_com, obj.tab_cub.P(lv_com), "");
    end
    if l_V
        sct.sct_panel(end+1)  = f_panel("\angleV [deg]");
        sct.sct_series(end+1) = f_series(numel(sct.sct_panel), sv_bus, rad2deg(obj.tab_bus.Varg), "");
    end
    G = GraphChart(sct, Parent=opt.Parent);
end
