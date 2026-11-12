function fig = plot_voltage(obj, opt)
% Plot the bus voltage profile.
%
% Draws the voltage profile of the solution as bar charts, one bar per bus: the voltage
% magnitude [pu] and the phase angle [deg], in two tiles ("both") or one. With Limit=true,
% the operating limits Vmin and Vmax of each bus (tab_parameter.operation in the network
% snapshot) are drawn on the magnitude as dashed lines (Tag "Vmin" and "Vmax"); infinite or
% missing limits are not drawn. It reads only the stored result. The only figure of the
% analysis: calculate_powerflow draws none (its PlotFcn is a live display during the
% calculation).
%
% <@Examples>
% ```matlab
% res = network.IEEE9bus().calculate_powerflow();
% res.plot_voltage();
% res.plot_voltage(Quantity="magnitude", Limit=false);
% ```
%
% See also ResultPF.disp_bus, PowerNetwork.calculate_powerflow
    arguments (Input)
        obj
        opt.Parent = [] % Container to draw in. A new figure when empty.
        opt.Quantity (1,1) string {mustBeMember(opt.Quantity, ["magnitude","angle","both"])} = "both" % Tiles drawn: |V|, the angle, or both.
        opt.Limit (1,1) logical = true % Draw the finite Vmin and Vmax of each bus on the magnitude.
    end
    arguments (Output)
        fig % Layout holding the axes (magnitude, then angle).
    end
    if isempty(opt.Parent)
        opt.Parent = figure();
    end

    sv_bus  = string(obj.tab_bus.Properties.RowNames);
    x       = categorical(sv_bus, sv_bus);
    l_mag   = opt.Quantity ~= "angle";
    l_ang   = opt.Quantity ~= "magnitude";

    fig = tiledlayout(opt.Parent, l_mag + l_ang, 1, "TileSpacing", "compact");
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

    if l_mag
        ax = nexttile(fig);
        bar(ax, x, obj.tab_bus.V);
        ylabel(ax, "|V| [pu]");
        grid(ax, "on");
        if opt.Limit
            draw_limits(ax, x, bus_data(obj));
        end
    end
    if l_ang
        ax = nexttile(fig);
        bar(ax, x, rad2deg(obj.tab_bus.Varg));
        ylabel(ax, "\angleV [deg]");
        grid(ax, "on");
    end
end


function draw_limits(ax, x, sct)
% Dashed lines of the finite Vmin and Vmax over the bars
    hold(ax, "on")
    for s_lim = ["Vmin", "Vmax"]
        rv = sct.("rv_" + s_lim);
        rv(isinf(rv)) = NaN;
        if all(isnan(rv))
            continue
        end
        plot(ax, x, rv, "--", "LineWidth", 1.2, "Marker", "_", "MarkerSize", 12, ...
             "Color", [0.85 0.33 0.10], "Tag", s_lim, "DisplayName", s_lim);
    end
    hold(ax, "off")
end
