function reflect_node_label(obj)
    
    n_bus = obj.n_bus;
    n_com = obj.n_component;

    str_bus = string(nan(n_bus, 1));
    str_com = string(nan(n_com, 1));

    rv_Varg = angle(obj.cv_Vbus) * 180/pi;
    rv_Vmag = abs(obj.cv_Vbus);

    for i_bus = 1:n_bus
        str_bus(i_bus) = obj.str_bus(i_bus) + newline + ...
                         " ∠V="  + num2str(rv_Varg(i_bus), '%.2f') + "°"+newline+ ...
                         " |V|=" + num2str(rv_Vmag(i_bus), '%.2f');
    end
    for i_com = 1:n_com
        str_com(i_com) = obj.str_component(i_com) + newline + ...
                            " P=" + num2str(obj.rv_Pcomp(i_com), '%.2f') + newline+...
                            " Q=" + num2str(obj.rv_Qcomp(i_com), '%.2f');
    end
    obj.NodeLabelB = str_bus;
    obj.NodeLabelC = str_com;

    obj.NodeLabelVisible = obj.NodeLabelVisible;
end