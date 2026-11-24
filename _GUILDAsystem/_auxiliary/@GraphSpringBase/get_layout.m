function sct_layout = get_layout(obj) %#ok<STOUT>
% Not supported: the positions of a spring model are voltage phasors, not a layout.
%
% The nodes sit at their voltage phasors (2D) or on the surface z = log|V| (3D), so the
% picture has no layout to save with net.set_layout. Use GraphNetDiagram.get_layout for
% that.
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_layout (1,1) struct  % Never returned.
    end
    error(msg("GUILDA:GraphSpringBase:PositionPhysical", class(obj)));
end
