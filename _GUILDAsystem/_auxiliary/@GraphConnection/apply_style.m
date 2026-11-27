function apply_style(obj, iv_element)
% Set the color, text and width of the blocks and the color, label, width and style of the arrows of the rows iv_element.
%
% A block has a light fill of its color; a bus is filled with its color.
    arguments (Input)
        obj
        iv_element (:,1) double  % Rows of the elements in tab_element.
    end
    d   = obj.sct_data;
    plt = obj.sct_plt;
    n_b = numel(d.sv_blockTag);
    for i_row = iv_element'
        if i_row <= n_b
            i = i_row;
            rv_c = obj.BlockColor(i, :);
            rv_face = 1 - 0.1 * (1 - rv_c);
            if d.sv_blockKind(i) == "bus"
                rv_face = rv_c;
            end
            if isgraphics(plt.Block(i))
                set(plt.Block(i), "EdgeColor", rv_c, "FaceColor", rv_face, "LineWidth", obj.BlockLineWidth(i));
            end
            if isgraphics(plt.BlockText(i))
                sv_text = obj.BlockLabel(i);
                if d.sv_blockClass(i) ~= ""
                    sv_text = [sv_text; d.sv_blockClass(i)];
                end
                set(plt.BlockText(i), "String", cellstr(sv_text), "Color", 0.6 * rv_c);
            end
        else
            i = i_row - n_b;
            rv_c = obj.ArrowColor(i, :);
            if isgraphics(plt.Arrow(i))
                set(plt.Arrow(i), "Color", rv_c, "LineWidth", obj.ArrowLineWidth(i), "LineStyle", obj.ArrowLineStyle(i));
            end
            if isgraphics(plt.ArrowHead(i))
                set(plt.ArrowHead(i), "FaceColor", rv_c, "EdgeColor", rv_c);
            end
            if isgraphics(plt.ArrowText(i))
                set(plt.ArrowText(i), "String", obj.ArrowLabel(i), "Color", 0.8 * rv_c);
            end
        end
    end
end
