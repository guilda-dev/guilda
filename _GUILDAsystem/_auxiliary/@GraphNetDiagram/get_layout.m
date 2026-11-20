function sct_layout = get_layout(obj)
% Return the positions drawn now, in the form of net.get_layout.
%
% tab_bus has the columns Tag, X, Y (the bus centers, with the automatic layout and the
% moves of set_position) and tab_component the columns Tag (full tag), DX, DY (relative
% to the center of the bus). No other column is given: the diagram changes no other
% graph parameter, so net.set_layout(G.get_layout()) writes the positions only. The model
% is never changed by the diagram itself.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% G = net.plot_diagram();
% G.set_position("B001", [0.1, 0.9]);
% net.set_layout(G.get_layout());
% ```
%
% See also PowerNetwork.set_layout, GraphNetDiagram.set_position
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_layout (1,1) struct  % Fields tab_bus (Tag, X, Y) and tab_component (Tag, DX, DY).
    end
    Tag = obj.sv_bus(:);
    rm_xy = zeros(0, 2);
    if obj.n_bus > 0
        rm_xy = obj.tab_bus.graph{:, ["X","Y"]};
    end
    tab_bus = table(Tag, rm_xy(:, 1), rm_xy(:, 2), 'VariableNames', ["Tag", "X", "Y"]);
    Tag = obj.sv_componentTag(:);
    rm_d = zeros(0, 2);
    if obj.n_component > 0
        rm_d = obj.tab_component.graph{:, ["DX","DY"]};
    end
    tab_component = table(Tag, rm_d(:, 1), rm_d(:, 2), 'VariableNames', ["Tag", "DX", "DY"]);
    sct_layout = struct("tab_bus", tab_bus, "tab_component", tab_component);
end
