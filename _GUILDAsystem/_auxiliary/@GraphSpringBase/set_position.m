function set_position(obj, sr_tag, rm_xy) %#ok<INUSD>
% Not supported: the position of a node is its voltage phasor.
%
% The nodes of a spring model sit at their voltage phasors (2D) or on the surface
% z = log|V| (3D), so their positions follow from the data and cannot be set. Change the
% data with set_data instead.
    arguments (Input)
        obj
        sr_tag (1,:) string  % Tags of the elements.
        rm_xy (:,2) double   % New positions, one row (x, y) per tag.
    end
    error(msg("GUILDA:GraphSpringBase:PositionPhysical", class(obj)));
end
