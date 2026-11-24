function [sv_line, rv_value, s_label] = color_readout(obj, s_kind, iv_index, s_sep)
% Lines "<name><s_sep><value>" of the color values of elements of a kind, and the colorbar label.
%
% The value of an element is its row of BusColorData, ComponentColorData, BranchColorData
% or LinkColorData (s_kind): under BusColorMode "V" and "angle" (buses) and ColorMode
% "I", "P", "Q" and "Loss" the values of the quantity at the sample shown
% (reflect_color_mode), else the values set. The colorbar label is ColorbarLabel, or with
% "" the quantity of BusColorMode ("|V| [pu]", "∠V [deg]") when it is not "none", else
% that of ColorMode ("|I| [pu]", "P [pu]", "Q [pu]", "Loss [pu]"; "" for "user" and
% "none"). The name of the lines is that label,
% or "color" when it is "". The value is written with %.5g (5 significant digits); an element without a finite
% value (NaN, no row) has a missing line. Used by the data tips (create_scene), the labels
% of LabelMode "value" (reflect_node_label) and the colorbar (apply_style).
    arguments (Input)
        obj
        s_kind (1,1) string           % "bus", "component", "branch" or "link".
        iv_index (:,1) double         % Indices of the elements in the vectors of the kind.
        s_sep (1,1) string = " = "    % Text between the name and the value.
    end
    arguments (Output)
        sv_line (:,1) string   % Line of each element; missing without a finite value.
        rv_value (:,1) double  % Color value of each element (NaN: none).
        s_label (1,1) string   % Label of the colorbar.
    end
    switch s_kind
        case "bus";       rv_data = obj.BusColorData;
        case "component"; rv_data = obj.ComponentColorData;
        case "branch";    rv_data = obj.BranchColorData;
        otherwise;        rv_data = obj.LinkColorData;
    end
    rv_value = nan(numel(iv_index), 1);
    lv = iv_index >= 1 & iv_index <= numel(rv_data);
    rv_value(lv) = rv_data(iv_index(lv));

    s_label = obj.ColorbarLabel;
    if s_label == "" && obj.BusColorMode ~= "none"
        s_label = "|V| [pu]";
        if obj.BusColorMode == "angle"
            s_label = "∠V [deg]";
        end
    elseif s_label == ""
        switch obj.ColorMode
            case "I";    s_label = "|I| [pu]";
            case "P";    s_label = "P [pu]";
            case "Q";    s_label = "Q [pu]";
            case "Loss"; s_label = "Loss [pu]";
        end
    end
    s_name = s_label;
    if s_name == ""
        s_name = "color";
    end
    sv_line = string(nan(numel(iv_index), 1));
    lv = isfinite(rv_value);
    sv_line(lv) = s_name + s_sep + compose("%.5g", rv_value(lv));
end
