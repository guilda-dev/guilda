function rehash(obj)
% Update the drawing to the state shown: draw it again when needed, then the colors,
% labels and arrows.
    arguments (Input)
        obj
    end
    if isempty(obj.cv_Vbus)          % no state yet (options set in the constructor)
        return
    end
    if ~isgraphics(obj.ax)
        obj.ax = axes(figure());
    end
    if obj.l_redraw || obj.BusHeightMode ~= "none"
        obj.draw_graph_network();
        obj.l_redraw = false;
    end
    obj.reflect_color_mode();
    obj.reflect_node_label();
    obj.reflect_arrow_forward();
end
