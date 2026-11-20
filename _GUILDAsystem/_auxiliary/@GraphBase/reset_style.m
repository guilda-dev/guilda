function reset_style(obj, sr_tag)
% Return the appearance of elements to the defaults of the data.
%
% Every vector property that set_style writes (see style_properties of the subclass) gets
% back, for the elements with the given tags, the value it had when the element came with
% the data. With no argument, all elements are reset. The selection is not changed.
%
% <@Examples>
% ```matlab
% G.set_style("B001", Color="r");
% G.reset_style("B001");
% G.reset_style();          % every element
% ```
    arguments (Input)
        obj
        sr_tag (1,:) string = unique(obj.tab_element.Tag, "stable")'  % Tags of the elements; all by default.
    end
    tab = obj.element_table();
    sv_bad = sr_tag(~ismember(sr_tag, tab.Tag));
    if ~isempty(sv_bad)
        error(msg("GUILDA:GraphBase:UnknownTag", join(sv_bad, ", "), class(obj)));
    end
    sct_map = obj.style_properties();
    l_row   = ismember(tab.Tag, sr_tag);
    for s_kind = string(fieldnames(sct_map))'
        iv = tab.Index(l_row & tab.Kind == s_kind);
        if isempty(iv)
            continue
        end
        for s_opt = string(fieldnames(sct_map.(s_kind)))'
            s_prop = sct_map.(s_kind).(s_opt);
            if ~isfield(obj.sct_styleDefault, s_prop)
                continue
            end
            v_def = obj.sct_styleDefault.(s_prop);
            v = obj.(s_prop);
            iv_ok = iv(iv <= size(v_def, 1) & iv <= size(v, 1));
            v(iv_ok, :) = v_def(iv_ok, :);
            obj.(s_prop) = v;
        end
    end
end
