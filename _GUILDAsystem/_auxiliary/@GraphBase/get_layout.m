function sct_layout = get_layout(obj)
% Return the drawn positions in the form of net.get_layout (only graphs with a free layout).
%
% A graph with a free layout (GraphNetDiagram, GraphNetMap) overrides this method and
% returns the positions it draws, so that net.set_layout(G.get_layout()) saves them in the
% model. In the other graphs the positions follow from the data, and this method raises
% an error.
%
% <@Examples>
% ```matlab
% G = net.plot_diagram();
% net.set_layout(G.get_layout());
% ```
%
% See also PowerNetwork.get_layout, PowerNetwork.set_layout
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_layout (1,1) struct  % Layout tables by kind (see PowerNetwork.get_layout).
    end
    error(msg("GUILDA:GraphBase:PositionNotSupported", class(obj)));
end
