function G = plot_pvcurve(obj, opt)
% Plot the PV curves.
%
% Draws the PV curves: the voltage magnitude [pu] of each bus against the load parameter
% lambda along the path. A dashed line marks the nose (maximum loading, r_lambdaMax).
% By default it draws the load buses (options.LoadBus); Bus selects other buses.
% The only figure of the analysis: calculate_continuation_powerflow draws none (its
% PlotFcn is a live display during the calculation).
%
% It returns the chart G (GraphChart): one line per bus, tagged with the bus tag. The
% nose line is fixed drawing, not an element. The samples of the chart are the steps
% (rv_t = 1 ... n_step, named "Step", text "Step k (λ = ...)"): G.set_time(k) puts a
% marker on each curve at step k (none before the first set_time), and G.link(G2) keeps
% it in step with the other plots of the steps (plot_diagram, plot_spring_model,
% plot_stability_index, plot_generator, plot_branch) and with
% net.get_sys({res, steps}).plot_eigenvalue / plot_eigenvalue_path.
%
% <@Examples>
% ```matlab
% G = res.plot_pvcurve(Bus="all");
% G.set_style(G.tab_element.Tag(1), Color="r", LineWidth=2);
% G.set_time(res.r_noseStep);       % markers at the nose
% ```
%
% See also GraphChart, PowerNetwork.calculate_continuation_powerflow
    arguments (Input)
        obj
        opt.Bus    {mustBeText} = default_bus(obj)  % Tags of the buses to draw; "all" for every bus.
        opt.Parent = []                             % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure.
    end
    arguments (Output)
        G  % The chart (GraphChart), one line per bus.
    end
    sv_plot = string(opt.Bus);
    if isequal(sv_plot, "all")
        sv_plot = obj.sv_bus;
    end
    [lv_found, iv_bus] = ismember(sv_plot, obj.sv_bus);
    if ~all(lv_found)
        error(msg("GUILDA:ResultCPF:UnknownBus", char(join(sv_plot(~lv_found), ", "))));
    end

    s_title = "PV curve";
    if ~obj.l_success
        s_title = s_title + " - nose not reached";
    end
    rv_lambda = reshape(obj.rv_lambda, 1, []);
    sct = step_sample(obj);
    sct.sct_panel  = struct("s_title", s_title, "s_xlabel", "\lambda", "s_ylabel", "|V| [pu]", ...
                            "s_legendLocation", "southwest", "l_time", ~isempty(rv_lambda), ...
                            "s_cursor", "marker");
    if isempty(rv_lambda)
        sct.sct_panel.s_cursor = "line";      % no path: no samples
    end
    sct.sct_series = struct("rv_x", rv_lambda, "rm_y", abs(obj.cm_Vbus(iv_bus,:)).', ...
                            "sv_tag", reshape(obj.sv_bus(iv_bus), [], 1), "r_lineWidth", 1.2);
    sct.sct_refline = struct.empty;
    if ~isnan(obj.r_lambdaMax)
        sct.sct_refline = struct("s_axis", "x", "r_value", obj.r_lambdaMax, ...
            "s_label", "\lambda_{max} = " + compose("%.4g", obj.r_lambdaMax), ...
            "rv_color", [0.15 0.15 0.15], "s_lineStyle", "--");
    end
    G = GraphChart(sct, Parent=opt.Parent);
end


function sv = default_bus(obj)
    sv = "all";
    if isfield(obj.options, "LoadBus") && ~isempty(obj.options.LoadBus)
        sv = obj.options.LoadBus;
    end
end
