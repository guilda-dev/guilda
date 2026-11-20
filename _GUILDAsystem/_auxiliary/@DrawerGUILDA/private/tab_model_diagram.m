function G = tab_model_diagram(G, h_parent, h_panel, history)
% Diagram of the model tab: net.plot_diagram(State="auto") with the element of the model GUI selected.
    arguments (Input)
        G          % Diagram shown, or [].
        h_parent   % Panel of the diagram.
        h_panel    % Panel of the tab (UserData: the model GUI).
        history    % History of the app.
    end
    arguments (Output)
        G  % Diagram drawn. <@Type> GraphNetDiagram
    end
    net = history.get_variable("net");
    G = draw_network(G, h_parent, net, false);
    if isstruct(h_panel.UserData)
        tab_model_select(G, h_panel.UserData.gui.a_target, net);
    end
end
