function tab_model_click(data, h_panel)
% Show the clicked element of the diagram in the model GUI: a bus, a branch or a component (also its link).
%
% The element is found by its tag in the network of the model GUI; the model GUI then
% notifies TargetChanged, which selects it in the diagram.
    arguments (Input)
        data     % GraphEventData of the click (Tag, Kind, Index).
        h_panel  % Panel of the tab (UserData: the model GUI and its network).
    end
    arguments (Output)
    end
    if ~isstruct(h_panel.UserData)
        return
    end
    net = h_panel.UserData.net;
    a_model = [];
    switch data.Kind
        case "bus"
            c_model = net.a_Bus;
        case "branch"
            c_model = net.a_Branch;
        case {"component", "link"}
            c_model = [cell(0, 1); tools.vcellfun(@(b) reshape(b.a_Component, [], 1), net.a_Bus)];
        otherwise
            c_model = {};
    end
    i_model = find(cellfun(@(m) string(m.s_tag) == data.Tag, c_model), 1);
    if ~isempty(i_model)
        a_model = c_model{i_model};
    end
    if ~isempty(a_model)
        h_panel.UserData.gui.render(a_model);
    end
end
