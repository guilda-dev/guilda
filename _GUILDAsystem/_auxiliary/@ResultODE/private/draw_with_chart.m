function [G, G_chart] = draw_with_chart(obj, h_parent, s_trajectory, s_default, fcn_graph)
% Draw the animated graph of plot_spring_model or plot_diagram, with the side chart of a trajectory on its right.
%
% The graph is drawn by fcn_graph(h) in h. With a side chart, the container h_parent (a
% new figure of 1400 x 600 px when it is empty; a uigridlayout gets a borderless uipanel
% first) holds two borderless panels side by side: the graph on the left (60 %, with its
% playback bar) and the chart plot_trajectory(Quantity=s_trajectory) on the right (40 %,
% no bar: its time only moves the cursor). The two are linked, so the bar of the graph
% moves the cursor of the chart. s_trajectory "auto" draws s_default; "none" and an axes
% or uiaxes h_parent draw the graph alone in h_parent (G_chart []). A drawing that fails
% removes the panels (and the new figure) it made.
    arguments (Input)
        obj                                % The result. <@Type> ResultODE
        h_parent                           % Parent of the method: a container, an axes or uiaxes, or [] for a new figure.
        s_trajectory (1,1) string          % Quantity of the side chart (as plot_trajectory), "auto" or "none".
        s_default (1,1) string             % Quantity drawn for "auto".
        fcn_graph (1,1) function_handle    % Draws the graph in a parent h as fcn_graph(h).
    end
    arguments (Output)
        G        % The animated graph (GraphBase).
        G_chart  % The side chart (GraphChart), or [] without one.
    end
    G_chart = [];
    sv_container = ["matlab.ui.Figure", "matlab.ui.container.Panel", "matlab.ui.container.Tab", ...
                    "matlab.ui.container.GridLayout"];
    l_container = isempty(h_parent) || (isscalar(h_parent) && isgraphics(h_parent) ...
        && any(arrayfun(@(s) isa(h_parent, s), sv_container)));
    if s_trajectory == "none" || ~l_container      % an axes (or a wrong Parent: the error of the graph)
        G = fcn_graph(h_parent);
        return
    end
    if s_trajectory == "auto"
        s_trajectory = s_default;
    end

    h_host = h_parent;
    h_made = gobjects(0);                           % what is deleted when the drawing fails
    if isempty(h_host)
        h_host = figure("Color", "w", "Position", [100 100 1400 600]);
        h_made = h_host;
    elseif isa(h_host, "matlab.ui.container.GridLayout")
        h_host = uipanel(h_host, "BorderType", "none");
        h_made = h_host;
    end
    rv_back = [1 1 1];
    if isprop(h_host, "Color")
        rv_back = h_host.Color;
    elseif isprop(h_host, "BackgroundColor")
        rv_back = h_host.BackgroundColor;
    end
    h_left  = uipanel(h_host, "Units", "normalized", "Position", [0 0 0.6 1], "BorderType", "none", ...
        "BackgroundColor", rv_back);
    h_right = uipanel(h_host, "Units", "normalized", "Position", [0.6 0 0.4 1], "BorderType", "none", ...
        "BackgroundColor", rv_back);
    if isempty(h_made)
        h_made = [h_left, h_right];
    end
    try
        G_chart = obj.plot_trajectory(Quantity=s_trajectory, Parent=h_right);
        G = fcn_graph(h_left);
    catch err
        delete(h_made(isgraphics(h_made)));
        rethrow(err);
    end
    G.link(G_chart);
end
