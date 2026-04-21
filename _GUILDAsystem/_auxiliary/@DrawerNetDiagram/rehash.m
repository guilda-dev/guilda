function rehash(obj)
    if ~isgraphics(obj.ax)
       obj.ax = axes('Parent',figure());
    end
    if obj.flag_new || obj.NodeHeightMode ~= "none"
        obj.draw_graph_network();
        obj.flag_new = false;
    end
    obj.reflect_color_mode();
    obj.reflect_node_label();
    obj.reflect_arrow_forward();
end