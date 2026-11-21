function apply_style(obj, iv_element)
% Set the color and width of the separator lines of the elements iv_element.
    arguments (Input)
        obj
        iv_element (:,1) double  % Rows of the elements in tab_element.
    end
    hv = obj.sct_plt.Separator;
    for i = iv_element'
        if isgraphics(hv(i))
            set(hv(i), "Color", obj.SeparatorColor(i, :), "LineWidth", obj.SeparatorLineWidth(i));
        end
    end
end
