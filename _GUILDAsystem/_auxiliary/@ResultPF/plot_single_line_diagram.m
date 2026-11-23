function G = plot_single_line_diagram(obj, opt)
% Draw the network of the power flow as a black-and-white single-line diagram for a paper.
%
% The same drawing as PowerNetwork.plot_single_line_diagram, from the network snapshot of
% the result (as plot_diagram): the 2D layout of the graph parameters, a bus as a thick
% bar or dot, a branch as a thin line, a transformer as two overlapping circles, a
% generator (a class of component.generator) as a circle with a sine inside, a load
% (component.load) as a filled triangle pointing away from its bus, any other component
% as a marker of its Shape, all in black on white, and the bus tags as labels without a
% box. The solution sets no color, width or size: there are no colors, colorbar, title,
% flow dots or data-dependent widths, and the axes are hidden with tight limits. The data
% tips show the values of the solution.
%
% With Parent empty, a new white figure for one column of a two-column paper is made:
% 8.5 cm wide, as high as the layout needs (3 to 12 cm), with labels of 8 pt (smaller
% beyond 30 buses: 8*sqrt(30/n_bus), at least 5 pt), so that exportgraphics writes it at
% its size. With a Parent the diagram is drawn in it.
%
% <@Examples>
% ```matlab
% res = network.IEEE9bus().calculate_powerflow();
% G = res.plot_single_line_diagram();
% exportgraphics(G.ax, "ieee9.png", Resolution=600);
% ```
%
% See also ResultPF.plot_diagram, PowerNetwork.plot_single_line_diagram, GraphNetDiagram
    arguments (Input)
        obj
        opt.Parent = []  % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure of 8.5 cm width.
    end
    arguments (Output)
        G  % GraphNetDiagram object of the drawing.
    end
    h_parent = opt.Parent;
    l_figure = isempty(h_parent);
    if l_figure
        h_parent = figure("Color", "w", "Units", "centimeters", "Position", [2 2 8.5 8.5]);
    end
    r_font = min(8, max(5, round(8*sqrt(30/max(height(obj.tab_bus), 1)))));   % 8 pt, smaller beyond 30 buses
    G = obj.plot_diagram(Parent=h_parent, Dimension="2D", ColorMode="none", ...
        BusColorMode="none", FlowMode="none", FlowAnimation=false, BranchWidthMode="none", ...
        BranchWidthRange=[0.6 0.6], MarkerSizeMode="none", MarkerSizeRange=[4 4], LinkWidth=0.6, ...
        BusHeightMode="none", LabelMode="bus", LabelFontSize=r_font, LabelFontWeight="normal", TitleFormat="");
    G.l_singleLine = true;
    if l_figure                        % tight, and as high as the layout
        ax = G.ax(1);
        if isa(ax.Parent, "matlab.graphics.layout.TiledChartLayout")
            ax.Parent.Padding = "tight";
        end
        h_parent.Position(4) = min(max(8.5*diff(ax.YLim)/diff(ax.XLim), 3), 12);
    end
end
