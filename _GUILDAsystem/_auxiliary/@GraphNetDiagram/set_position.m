function set_position(obj, sr_tag, rm_xy)
% Move buses or components in the drawing (never in the model).
%
% The positions live in the diagram; those of the graph parameters of the snapshot, or of
% the automatic layout, are the defaults. A bus position is its center; a component
% position is absolute here and kept relative to its bus (DX, DY), so a moved bus takes
% its components and their bend points with it, unless their own positions are given in
% the same call. The branches and the links follow their ends. The diagram is drawn again
% at the sample shown. G.get_layout returns the positions; net.set_layout(G.get_layout())
% saves them in the model.
%
% <@Examples>
% ```matlab
% G = net.plot_diagram();
% G.set_position(["B001", "B002"], [0.1 0.9; 0.3 0.9]);
% ```
    arguments (Input)
        obj
        sr_tag (1,:) string                % Tags of buses or components (see tab_element).
        rm_xy (:,2) double {mustBeFinite}  % New positions, one row (x, y) per tag.
    end
    if size(rm_xy, 1) ~= numel(sr_tag)
        error(msg("GUILDA:GraphNetDiagram:PositionSize", numel(sr_tag), size(rm_xy, 1)));
    end
    tab = obj.element_table();
    sv_bad = sr_tag(~ismember(sr_tag, tab.Tag));
    if ~isempty(sv_bad)
        error(msg("GUILDA:GraphBase:UnknownTag", join(sv_bad, ", "), class(obj)));
    end
    l_bus  = ismember(sr_tag, obj.sv_bus);
    l_comp = ismember(sr_tag, obj.sv_componentTag);
    if ~all(l_bus | l_comp)
        error(msg("GUILDA:GraphNetDiagram:PositionKind", join(sr_tag(~(l_bus | l_comp)), ", ")));
    end

    % Buses first (their components keep DX, DY); then the components given, relative to their bus
    for j = find(l_bus)
        i = find(obj.sv_bus == sr_tag(j), 1);
        obj.tab_bus.graph{i, ["X","Y"]} = rm_xy(j, :);
    end
    for j = find(l_comp)
        c = find(obj.sv_componentTag == sr_tag(j), 1);
        obj.tab_component.graph{c, ["DX","DY"]} = rm_xy(j, :) - obj.tab_bus.graph{obj.tab_component.bus(c), ["X","Y"]};
    end
    if ~validate(obj)
        obj.create_scene();
        obj.apply_selection();
    end
end
