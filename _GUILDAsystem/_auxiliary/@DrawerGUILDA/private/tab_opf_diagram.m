function G = tab_opf_diagram(G, h_parent, history)
% Diagram of the OPF tab: the network at the equilibrium with the components that have a cost selected.
%
% net.plot_diagram(State="auto") with the components that have a cost in
% tab_parameter.OPF (HP, fP, HQ or fQ not 0) selected, into the diagram of the tab (Graph=G)
% while it shows the network (h_parent.UserData "network"), else anew in h_parent. A run
% does not change the drawing: the result (e.g. its LMP) is viewed in the Analyze result
% window.
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
        G = net.plot_diagram(Graph=G, State="auto", TitleFormat="", ColorbarLabel="Branch current |I| [pu]");
        G.clear_selection();
    else
        delete(h_parent.Children);
        G = net.plot_diagram(Parent=h_parent, State="auto", TitleFormat="", ColorbarLabel="Branch current |I| [pu]");
        h_parent.UserData = "network";
    end
    c_comp = vertcat(cell(0, 1), net.a_Bus{:});
    c_comp = vertcat(cell(0, 1), c_comp.a_Component);
    l_cost = cellfun(@(c) any(table2array(c.tab_parameter.OPF(:, ["HP", "fP", "HQ", "fQ"])) ~= 0), c_comp);
    G.select(string(c_comp(l_cost)));
end
