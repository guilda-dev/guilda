function autoplay(obj, c_output)
% Start playing the first output graph of the plot that has a playback bar, as if its Play button had been pressed, without blocking.
%
% The graphs are the outputs of the call (c_output; {G_plot} when it is empty), in their
% order. The first scalar GraphBase among them whose container holds a playback bar (Tag
% "GUILDA:GraphBase:PlaybackBar"; the container is ax(1).Parent.Parent, the parent of its
% tiled layout) plays: a graph whose drawing changes with time (e.g. ResultODE.plot_diagram,
% plot_spring_model, ResultOPF.plot_iteration: G_net). A chart whose time only moves a
% cursor has no bar and does not play by itself (ResultODE.plot_trajectory); a chart linked
% to the graph that plays follows it (the side chart G_chart of ResultODE.plot_diagram).
% Only one graph gets G.play(), so one timer plays. G.play() starts the timer playback of
% the graph and returns at once, so the window stays usable while it plays; it plays
% nothing under matlab -batch or in a hidden window, so tests and hidden windows stay as
% drawn. The playback stops when the window closes or another plot replaces it (its axes
% are deleted), and when Pause of the playback bar is pressed. A network diagram drawn as
% G_plot also gets FlowAnimation on.
    arguments (Input)
        obj
        c_output cell = {}  % The outputs of the call that drew G_plot.
    end
    arguments (Output)
    end
    G = obj.G_plot;
    if isa(G, "GraphNetDiagram") && isscalar(G) && isvalid(G) && ~isempty(G.ax) && all(isgraphics(G.ax)) ...
            && ~G.FlowAnimation
        G.FlowAnimation = true;
    end
    if isempty(c_output)
        c_output = {G};
    end
    for i = 1:numel(c_output)
        g = c_output{i};
        if ~(isa(g, "GraphBase") && isscalar(g) && isvalid(g)) || isempty(g.ax) || ~all(isgraphics(g.ax)) ...
                || numel(g.rv_t) < 2
            continue
        end
        h_host = g.ax(1).Parent;
        if ~isa(h_host, "matlab.graphics.layout.TiledChartLayout")
            continue
        end
        if ~isempty(findall(h_host.Parent, "-depth", 1, "Tag", "GUILDA:GraphBase:PlaybackBar"))
            g.play();
            return
        end
    end
end
