function reflect_node_label(obj)
% Write the labels of LabelMode into BusLabel and ComponentLabel and show or hide them.
%
% "bus" shows the bus tags only (the component labels hold their tags, hidden); "tag" and
% "value" show the labels of the buses and the components; with "user" the labels set are
% kept (the tags fill labels that were never set); "none" hides all. The text objects of
% the component labels are made the first time they are shown, or when a label is set
% (set.ComponentLabel, make_component_labels).
    arguments (Input)
        obj
    end
    n_bus = obj.n_bus;
    n_com = obj.n_component;

    sv_bus = string(nan(n_bus, 1));
    sv_com = string(nan(n_com, 1));
    l_bus  = true;
    l_com  = true;
    switch obj.LabelMode
        case "user"
            if numel(obj.BusLabel) == n_bus
                sv_bus = obj.BusLabel;
            else
                sv_bus = obj.sv_bus;
            end
            if numel(obj.ComponentLabel) == n_com
                sv_com = obj.ComponentLabel;
            else
                sv_com = obj.sv_component;
            end
        case {"tag", "bus"}
            sv_bus = reshape(obj.sv_bus, n_bus, 1);
            sv_com = reshape(obj.sv_component, n_com, 1);
            l_com  = obj.LabelMode == "tag";
        case "value"
            rv_Varg = angle(obj.cv_Vbus) * 180/pi;
            rv_Vmag = abs(obj.cv_Vbus);
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
        otherwise   % "none"
            l_bus = false;
            l_com = false;
    end

    obj.BusLabel = sv_bus;
    l_auto = obj.l_labelAuto;
    obj.l_labelAuto = true;            % the labels of the mode make no text objects in set.ComponentLabel
    c_auto = onCleanup(@() set_auto(obj, l_auto));
    obj.ComponentLabel = sv_com;
    clear c_auto

    if l_com
        obj.make_component_labels((1:n_com)');
    end
    hv = obj.sct_plt.NodeLabel(:);
    set(hv(isgraphics(hv)), "Visible", l_bus);
    hv = obj.sct_plt.CompLabel(:);
    set(hv(isgraphics(hv)), "Visible", l_com);
end


function set_auto(obj, l_auto)
% Give back the state of l_labelAuto (onCleanup).
    arguments (Input)
        obj
        l_auto (1,1) logical  % State before.
    end
    if isvalid(obj)
        obj.l_labelAuto = l_auto;
    end
end
