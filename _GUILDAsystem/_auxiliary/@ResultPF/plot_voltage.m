function G = plot_voltage(obj, opt)
% Plot the bus voltage profile.
%
% Draws the voltage profile of the solution as bar charts, one bar per bus: the voltage
% magnitude [pu] and the phase angle [deg], in two panels ("both") or one. With Limit=true,
% the operating limits Vmin and Vmax of each bus (tab_parameter.operation in the network
% snapshot) are drawn on the magnitude as dashed lines over the buses; infinite or missing
% limits are not drawn. With more than 20 buses, the bus names on the horizontal axis
% are thinned to at most 20 evenly spaced ones and turned vertical; every bus keeps its
% bar. It reads only the stored result. The only figure of the analysis:
% calculate_powerflow draws none (its PlotFcn is a live display during the calculation).
%
% It returns the chart G (GraphChart). Its elements are tagged:
%
% - the bus tag: the bar of the bus, in each panel drawn (|V| and angle bars of a bus
%   share the tag, so set_style and select act on both);
% - "Vmin", "Vmax": the dashed limit lines (kind "line"), when drawn.
%
% <@Examples>
% ```matlab
% res = network.IEEE9bus().calculate_powerflow();
% G = res.plot_voltage();
% G.set_style("B002", Color="r");              % both bars of bus B002
% G.set_style("Vmax", LineStyle="-");
% res.plot_voltage(Quantity="magnitude", Limit=false);
% ```
%
% See also GraphChart, ResultPF.disp_bus, PowerNetwork.calculate_powerflow
    arguments (Input)
        obj
        opt.Parent = []                 % Container (figure, uifigure, uipanel, uitab, uigridlayout), or axes/uiaxes for one panel; [] for a new figure.
        opt.Quantity (1,1) string {mustBeMember(opt.Quantity, ["magnitude","angle","both"])} = "both"  % Panels drawn: |V|, the angle, or both.
        opt.Limit (1,1) logical = true  % Draw the finite Vmin and Vmax of each bus on the magnitude.
    end
    arguments (Output)
        G  % The chart (GraphChart): panels magnitude, then angle.
    end
    sv_bus  = string(obj.tab_bus.Properties.RowNames);
    s_title = "Power flow";
    if isfield(obj.options, "Solver")
        s_title = s_title + " (" + obj.options.Solver + ")";
    elseif isfield(obj.options, "Method")
        s_title = s_title + " (" + obj.options.Method + ")";
    end
    if ~obj.l_success
        s_title = s_title + " - not converged";
    end

    sct_panel  = struct("s_ylabel", {});
    sct_series = struct("i_panel", {}, "s_type", {}, "sv_x", {}, "rm_y", {}, "sv_tag", {}, "sv_legend", {}, ...
                        "rm_color", {}, "r_lineWidth", {}, "s_lineStyle", {}, "s_marker", {}, "r_markerSize", {});
    if opt.Quantity ~= "angle"
        sct_panel(end+1).s_ylabel = "|V| [pu]";
        sct_series(end+1) = struct("i_panel", 1, "s_type", "bar", "sv_x", sv_bus, "rm_y", obj.tab_bus.V, ...
            "sv_tag", sv_bus, "sv_legend", [], "rm_color", [], "r_lineWidth", [], "s_lineStyle", [], ...
            "s_marker", [], "r_markerSize", []);
        if opt.Limit
            sct = bus_data(obj);
            for s_lim = ["Vmin", "Vmax"]
                rv = sct.("rv_" + s_lim);
                rv(isinf(rv)) = NaN;
                if all(isnan(rv))
                    continue
                end
                sct_series(end+1) = struct("i_panel", 1, "s_type", "line", "sv_x", sv_bus, "rm_y", rv, ...
                    "sv_tag", s_lim, "sv_legend", "", "rm_color", [0.85 0.33 0.10], "r_lineWidth", 1.2, ...
                    "s_lineStyle", "--", "s_marker", "_", "r_markerSize", 12); %#ok<AGROW>
            end
        end
    end
    if opt.Quantity ~= "magnitude"
        sct_panel(end+1).s_ylabel = "\angleV [deg]";
        sct_series(end+1) = struct("i_panel", numel(sct_panel), "s_type", "bar", "sv_x", sv_bus, ...
            "rm_y", rad2deg(obj.tab_bus.Varg), "sv_tag", sv_bus, "sv_legend", [], "rm_color", [], ...
            "r_lineWidth", [], "s_lineStyle", [], "s_marker", [], "r_markerSize", []);
    end
    sct = struct("s_title", s_title, "sct_panel", sct_panel, "sct_series", sct_series);
    G = GraphChart(sct, Parent=opt.Parent);
    n_bus = numel(sv_bus);
    if n_bus > 20   % readable names for many buses: at most 20 tick labels, vertical
        iv_tick = 1:ceil(n_bus/20):n_bus;
        set(G.ax, "XTick", iv_tick, "XTickLabel", sv_bus(iv_tick), "XTickLabelRotation", 90);
    end
end
