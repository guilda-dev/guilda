function rehash(obj)
    arguments (Input)
        obj
    end
    if ~isgraphics(obj.ax)
       obj.ax = axes('Parent',figure());
    end
    if obj.l_redraw || obj.BusHeightMode ~= "none"
        obj.draw_graph_network();
        obj.l_redraw = false;
    end
    obj.reflect_color_mode();
    obj.reflect_node_label();
    obj.reflect_arrow_forward();
end