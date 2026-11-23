function reflect_node_label(obj, iv_bus, iv_comp)
% Write the labels of LabelMode into BusLabel and ComponentLabel and show or hide them.
%
% "bus" shows the bus tags only (the component labels hold their tags, hidden); "tag" and
% "value" show the labels of the buses and the components; with "user" the labels set are
% kept (the tags fill labels that were never set); "none" hides all. With "value" a bus
% label is its tag, ∠V and |V|, and a component label its tag, P and Q, each followed by
% the line "<name>=<value>" of its color value (BusColorData, ComponentColorData) when it
% is finite, with the name and format of the data tips (color_readout). When the color
% value of a bus is |V| or ∠V (BusColorMode "V" or "angle"; or ColorMode "user" with a
% ColorbarLabel that starts with "|V|" or "∠V", spaces ignored, as a TimeChangedFcn may
% set it), a bus with that line drops its fixed "|V|=" or "∠V=" line, so the quantity is
% written once (with the digits of the color line). iv_bus and iv_comp
% are the rows written with "value" (the others keep their labels; the setters of the
% color values pass the rows that changed); the other modes write every row. The text
% objects of the component labels are made the first time they are shown, or when a label
% is set (set.ComponentLabel, make_component_labels).
    arguments (Input)
        obj
        iv_bus (:,1) double = (1:obj.n_bus)'         % Buses whose "value" labels are written.
        iv_comp (:,1) double = (1:obj.n_component)'  % Components whose "value" labels are written.
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
            if numel(obj.BusLabel) == n_bus && numel(obj.ComponentLabel) == n_com
                sv_bus = obj.BusLabel;
                sv_com = obj.ComponentLabel;
            else
                iv_bus  = (1:n_bus)';
                iv_comp = (1:n_com)';
            end
            c_Vbus = obj.cv_Vbus(iv_bus);
            sv_angle = newline + compose(" ∠V=%.2f°", angle(c_Vbus(:))*180/pi);
            sv_abs   = newline + compose(" |V|=%.2f", abs(c_Vbus(:)));
            sv_line = obj.color_readout("bus", iv_bus, "=");
            lv = ~ismissing(sv_line);
            % The color line of |V| or ∠V takes the place of the fixed line of that quantity
            s_label = erase(obj.ColorbarLabel, " ");
            l_user  = obj.BusColorMode == "none" && obj.ColorMode == "user";
            if obj.BusColorMode == "V" || (l_user && startsWith(s_label, "|V|"))
                sv_abs(lv) = "";
            elseif obj.BusColorMode == "angle" || (l_user && startsWith(s_label, "∠V"))
                sv_angle(lv) = "";
            end
            sv_bus(iv_bus) = reshape(obj.sv_bus(iv_bus), [], 1) + sv_angle + sv_abs;
            sv_bus(iv_bus(lv)) = sv_bus(iv_bus(lv)) + newline + " " + sv_line(lv);
            sv_com(iv_comp) = reshape(obj.sv_component(iv_comp), [], 1) + newline + ...
                compose(" P=%.2f", reshape(obj.rv_Pcomp(iv_comp), [], 1)) + newline + ...
                compose(" Q=%.2f", reshape(obj.rv_Qcomp(iv_comp), [], 1));
            sv_line = obj.color_readout("component", iv_comp, "=");
            lv = ~ismissing(sv_line);
            sv_com(iv_comp(lv)) = sv_com(iv_comp(lv)) + newline + " " + sv_line(lv);
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
