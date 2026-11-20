function h_layout = clear_gui(h_container, m_ui)
% Remove the GUI drawn in the container: its grid, the parts kept aside for later renders and their context menus.
%
% Only the grid of the GUI (Tag "DrawerModelGUI") is removed: an app may keep other
% components in the container. The context menus of the tables belong to the figure, so
% they are removed separately. m_ui is emptied.
    arguments (Input)
        h_container  % Container of the GUI.
        m_ui         % Components kept between renders (build_frame). <@Type> containers.Map
    end
    arguments (Output)
        h_layout  % Layout of the grid removed in a uigridlayout container ([] when there is none).
    end
    h_old = h_container.Children;
    h_old = h_old(arrayfun(@(c) isprop(c, "Tag") && c.Tag == "DrawerModelGUI", h_old));
    h_layout = [];
    if ~isempty(h_old)
        h_layout = h_old(1).Layout;
    end
    % The parts kept aside (detached from the grid) and every table with its menu
    h_part = h_old;
    if isKey(m_ui, "spare")
        h_part = [h_part; m_ui("spare")];
    end
    h_part = h_part(arrayfun(@(c) ~isa(c, "matlab.graphics.GraphicsPlaceholder") && isvalid(c), h_part));
    if ~isempty(h_part)
        h_table = findobj(h_part, "Type", "uitable");
        h_table = h_table(arrayfun(@(t) isa(t, "matlab.ui.control.Table"), h_table));
        for k = 1:numel(h_table)
            h_menu = h_table(k).ContextMenu;
            if isa(h_menu, "matlab.ui.container.ContextMenu") && isvalid(h_menu)
                delete(h_menu)
            end
        end
        for k = 1:numel(h_part)    % a part may be inside another one deleted before it
            if isvalid(h_part(k))
                delete(h_part(k))
            end
        end
    end
    remove(m_ui, keys(m_ui));
end
