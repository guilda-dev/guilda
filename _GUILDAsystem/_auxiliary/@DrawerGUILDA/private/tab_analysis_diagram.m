function G = tab_analysis_diagram(G, h_parent, history, f_draw)
% Diagram of an analysis tab: drawn by f_draw in the diagram panel of the tab, or the default one on an error.
%
% f_draw gets the diagram of the tab and draws into it (Graph=G) or anew in h_parent (see
% tab_pf_diagram). The INFO messages of the drawing are not printed. On any error of f_draw
% the panel is emptied and the default diagram (draw_network) is drawn instead.
    arguments (Input)
        G          % Diagram of the tab, or [].
        h_parent   % Diagram panel of the tab.
        history    % History of the app (net and the result variables).
        f_draw     % @(G, h_parent, history) returning the GraphNetDiagram drawn.
    end
    arguments (Output)
        G  % Diagram drawn, or [] (draw_network for a network without buses). <@Type> GraphNetDiagram
    end
    try
        evalc("G = f_draw(G, h_parent, history);");
    catch
        delete(h_parent.Children);
        h_parent.UserData = [];
        G = draw_network([], h_parent, history.get_variable("net"), true);
    end
end
