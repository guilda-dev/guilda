function G = tab_pf_diagram(G, h_parent, history)
% Diagram of the power flow tab: the network at the equilibrium with the buses colored by type.
%
% net.plot_diagram(State="auto") without flow colors and without a colorbar, the buses
% colored by their power-flow type (Bus.s_bustype): slack red, PV blue, PQ gray. A run does
% not change the drawing: the result is viewed in the Analyze result window.
%
% The network is drawn into the diagram of the tab (Graph=G) while it shows the network
% (h_parent.UserData "network"), else anew in h_parent.
    arguments (Input)
        G          % Diagram of the tab, or [].
        h_parent   % Diagram panel of the tab.
        history    % History of the app.
    end
    arguments (Output)
        G  % Diagram drawn. <@Type> GraphNetDiagram
    end
    net = history.get_variable("net");
    if isa(G, "GraphNetDiagram") && isscalar(G) && isvalid(G) && isequal(h_parent.UserData, "network")
        G = net.plot_diagram(Graph=G, State="auto", ColorMode="none", TitleFormat="");
    else
        delete(h_parent.Children);
        G = net.plot_diagram(Parent=h_parent, State="auto", ColorMode="none", TitleFormat="");
        h_parent.UserData = "network";
    end
    colorbar(G.ax(1), "off");
    sv_tag  = string(cellfun(@(b) b.s_tag, net.a_Bus, "UniformOutput", false));
    sv_type = string(cellfun(@(b) b.s_bustype, net.a_Bus, "UniformOutput", false));
    for c_color = {"slack", "#D62728"; "PV", "#1F77B4"; "PQ", "#7F7F7F"}.'
        if any(sv_type == c_color{1})
            G.set_style(sv_tag(sv_type == c_color{1}), Color=c_color{2});
        end
    end
end
