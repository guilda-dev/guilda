function G = tab_cpf_diagram(G, h_parent, history)
% Diagram of the CPF tab: net.plot_diagram(State="auto"), with the LoadBus buses of res_cpf selected after a run.
%
% It draws into the diagram of the tab (Graph=G) when there is one, else anew in h_parent.
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
    try
        res = history.get_variable("res_cpf");
    catch    % no run yet: plain
        return
    end
    if isa(res, "ResultCPF") && isscalar(res) && isfield(res.options, "LoadBus")
        G.select(intersect(string(res.options.LoadBus), G.tab_element.Tag(G.tab_element.Kind == "bus"), "stable"));
    end
end
