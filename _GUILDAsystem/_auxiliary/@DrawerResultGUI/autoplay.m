function autoplay(obj, c_output)
% Start playing the last plot when it animates, as if its Play button had been pressed, without blocking.
%
% The last plot (G_plot) plays when it is a GraphBase with two or more samples (e.g.
% ResultODE.plot_diagram or plot_spring_model). A GraphChart only moves its time cursor, so
% it plays only when it drives a graph that animates: another output of the same call
% (c_output) is a GraphBase other than a GraphChart with two or more samples (e.g.
% ResultOPF.plot_iteration: G_chart plays and the linked G_net follows it). A plain time
% chart (ResultODE.plot_trajectory) does not play. Only G_plot gets G.play(), so one timer
% plays. G.play() starts the timer playback of the graph and returns at once, so the window
% stays usable while it plays; it plays nothing under matlab -batch or in a hidden window,
% so tests and hidden windows stay as drawn. The playback stops when the window closes or
% another plot replaces it (its axes are deleted), and when Pause of the playback bar is
% pressed. A network diagram drawn as G_plot also gets FlowAnimation on.
    arguments (Input)
        obj
        c_output cell = {}  % The outputs of the call that drew G_plot.
    end
    arguments (Output)
    end
    G = obj.G_plot;
    if ~(isa(G, "GraphBase") && isscalar(G) && isvalid(G)) || isempty(G.ax) || ~all(isgraphics(G.ax))
        return
    end
    if isa(G, "GraphNetDiagram") && ~G.FlowAnimation
        G.FlowAnimation = true;
    end
    if numel(G.rv_t) < 2
        return
    end
    if isa(G, "GraphChart") && ~any(cellfun(@(g) isa(g, "GraphBase") && isscalar(g) && isvalid(g) ...
            && ~isa(g, "GraphChart") && numel(g.rv_t) >= 2, c_output))
        return
    end
    G.play();
end
