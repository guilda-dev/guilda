function make_component_labels(obj, iv_comp)
% Make the text objects of the component labels iv_comp that are not there yet.
%
% The texts are made hidden at CompLabelXYZ with CompLabelArgs, LabelFontSize and the
% label of ComponentLabel ("" when missing); reflect_node_label shows them with LabelMode.
% Component labels are made only when they are needed: when LabelMode shows them or when
% a label is set (set.ComponentLabel), so a large network draws fast with LabelMode "bus".
    arguments (Input)
        obj
        iv_comp (:,1) double  % Indices of the components.
    end
    plt = obj.sct_plt;
    if ~isfield(plt, "CompLabelXYZ")
        return
    end
    iv_comp = iv_comp(iv_comp >= 1 & iv_comp <= numel(plt.CompLabel));
    iv_comp = iv_comp(~isgraphics(plt.CompLabel(iv_comp)));
    sv_label = obj.ComponentLabel;
    for c = iv_comp'
        s = "";
        if c <= numel(sv_label) && ~ismissing(sv_label(c))
            s = sv_label(c);
        end
        rv_p = plt.CompLabelXYZ(c, :);
        obj.sct_plt.CompLabel(c) = text(obj.ax(1), rv_p(1), rv_p(2), rv_p(3), s, ...
            plt.CompLabelArgs{:}, "FontSize", obj.LabelFontSize, "Visible", "off");
    end
end
