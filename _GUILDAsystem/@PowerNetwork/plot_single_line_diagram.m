function G = plot_single_line_diagram(obj, opt)
% Draw the topology as a black-and-white single-line diagram for a paper.
%
% The diagram has the 2D layout of plot_diagram (the graph parameters of the elements)
% and the symbols of a single-line diagram, all in black on white: a bus is a thick bar or
% dot, a branch a thin line, a transformer two overlapping circles, a generator (a class
% of component.generator) a circle with a sine inside, a load (component.load) a filled
% triangle pointing away from its bus, any other component a marker of its Shape. The
% labels are the bus tags, without a box. There are no colors, colorbar, title, flow dots
% or data-dependent widths, and the axes are hidden with tight limits. No power flow is
% needed: it draws the topology (plot_diagram with State="topology").
%
% With Parent empty, a new white figure for one column of a two-column paper is made:
% 8.5 cm wide, as high as the layout needs (3 to 12 cm), with labels of 8 pt (smaller
% beyond 30 buses: 8*sqrt(30/n_bus), at least 5 pt), so that exportgraphics writes it at
% its size. With a Parent the diagram is drawn in it.
% The returned GraphNetDiagram works as any diagram: a click on an element or its data
% tip selects it, and set_style changes colors and sizes.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% G = net.plot_single_line_diagram();
% exportgraphics(G.ax, "ieee14.pdf", ContentType="vector");
% exportgraphics(G.ax, "ieee14.png", Resolution=600);
% ```
%
% See also PowerNetwork.plot_diagram, ResultPF.plot_single_line_diagram, GraphNetDiagram
%
% <@Group> Queries and display
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
    r_font = min(8, max(5, round(8*sqrt(30/max(numel(obj.a_Bus), 1)))));   % 8 pt, smaller beyond 30 buses
    G = obj.plot_diagram(State="topology", Parent=h_parent, Dimension="2D", ColorMode="none", ...
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
