function sct_layout = get_layout(obj)
% Return the bus positions drawn now, in the form of net.get_layout.
%
% tab_bus has the columns Tag, X, Y: the bus centers drawn, with the automatic layout and
% the moves of set_position. net.set_layout(G.get_layout()) writes these positions only.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% G = net.calculate_powerflow().plot_network();
% G.set_position("B001", [0, 0]);
% net.set_layout(G.get_layout());
% ```
%
% See also PowerNetwork.set_layout, GraphNetMap.set_position
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_layout (1,1) struct  % Field tab_bus (Tag, X, Y).
    end
    rm_xy = obj.sct_data.rm_xy;
    sct_layout = struct("tab_bus", table(obj.sct_data.sv_bus(:), rm_xy(:, 1), rm_xy(:, 2), ...
        'VariableNames', ["Tag", "X", "Y"]));
end
