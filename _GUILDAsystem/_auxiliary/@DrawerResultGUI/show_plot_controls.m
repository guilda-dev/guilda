function show_plot_controls(obj)
% Show the control panel of the last plot right of the plot panel, or remove it.
%
% While the toggle "Display options" (Tag "controls") is pressed and the last plot returned
% a GraphBase (G_plot), G_plot.show_controls(Parent=<grid of the Plot tab>) fills the second
% column of that grid (230 px; 0 px for a graph without declared controls). Otherwise that column is 0 px wide and its panel is removed.
% A plot run deletes the axes and with them the panel shown before, so it is shown again
% after each plot. Changes in the panel are not logged.
    arguments (Input)
        obj
    end
    arguments (Output)
    end
    if ~isvalid(obj.h_plot)
        return
    end
    h_grid = obj.h_plot.Parent;
    h_toggle = findobj(obj.h_container, "Tag", "controls");
    h_toggle = h_toggle(arrayfun(@(h) isa(h, "matlab.ui.control.StateButton"), h_toggle));
    delete(h_grid.Children(h_grid.Children ~= obj.h_plot))
    G = obj.G_plot;
    if ~isempty(h_toggle) && h_toggle(1).Value && isa(G, "GraphBase") && isscalar(G) && isvalid(G) ...
            && ~isempty(G.ax) && all(isgraphics(G.ax))
        h_panel = G.show_controls(Parent=h_grid);
        h_panel.Layout.Row = 1;
        h_panel.Layout.Column = 2;
        % A graph without declared controls gets no empty column
        h_widget = findall(h_panel);
        if any(~arrayfun(@(h) isa(h, "matlab.ui.container.Panel") || isa(h, "matlab.ui.container.GridLayout") ...
                || isa(h, "matlab.ui.control.Label"), h_widget))
            h_grid.ColumnWidth{2} = 230;
        else
            h_grid.ColumnWidth{2} = 0;
        end
    else
        h_grid.ColumnWidth{2} = 0;
    end
end
