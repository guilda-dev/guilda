function reflect_node_label(obj)
    arguments (Input)
        obj
    end
    
    n_bus = obj.n_bus;
    n_com = obj.n_component;

    sv_bus  = string(nan(n_bus, 1));
    sv_com  = string(nan(n_com, 1));

    rv_Varg = angle(obj.cv_Vbus) * 180/pi;
    rv_Vmag = abs(obj.cv_Vbus);

    is_visible = false;
    switch obj.LabelMode
        case "tag"
            is_visible = true;
            for i_bus = 1:n_bus
                sv_bus(i_bus) = obj.sv_bus(i_bus);
            end
            for i_com = 1:n_com
                sv_com(i_com) = obj.sv_component(i_com);
            end
        case "value"
            is_visible = true;
            for i_bus = 1:n_bus
                sv_bus(i_bus) = obj.sv_bus(i_bus) + newline + ...
                                 " ∠V="  + num2str(rv_Varg(i_bus), '%.2f') + "°"+newline+ ...
                                 " |V|=" + num2str(rv_Vmag(i_bus), '%.2f');
            end
            for i_com = 1:n_com
                sv_com(i_com) = obj.sv_component(i_com) + newline + ...
                                    " P=" + num2str(obj.rv_Pcomp(i_com), '%.2f') + newline+...
                                    " Q=" + num2str(obj.rv_Qcomp(i_com), '%.2f');
            end
    end

    obj.BusLabel = sv_bus;
    obj.ComponentLabel = sv_com;

    for i =1:numel(obj.sct_plt.NodeLabel)                              
        if isgraphics(obj.sct_plt.NodeLabel(i))                        
            obj.sct_plt.NodeLabel(i).Visible = is_visible;             
        end
    end
    for i =1:numel(obj.sct_plt.CompLabel)                              
        if isgraphics(obj.sct_plt.CompLabel(i))                        
            obj.sct_plt.CompLabel(i).Visible = is_visible;             
        end
    end
end