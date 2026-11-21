function set_position(obj, sr_tag, rm_xy) %#ok<INUSD>
% Move elements of the drawing (only graphs with a free layout).
%
% A graph with a free layout (GraphNetDiagram) overrides this method; it moves the
% elements in the drawing only, never in the model. In the other graphs the positions
% follow from the data, and this method raises an error.
%
% <@Examples>
% ```matlab
% G = net.plot_diagram();
% G.set_position("B001", [0.2, 0.8]);
% ```
    arguments (Input)
        obj
        sr_tag (1,:) string  % Tags of the elements.
        rm_xy (:,2) double   % New positions, one row (x, y) per tag.
    end
    error(msg("GUILDA:GraphBase:PositionNotSupported", class(obj)));
end
