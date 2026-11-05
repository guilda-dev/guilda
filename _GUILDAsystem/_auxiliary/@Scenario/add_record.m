function s_tag = add_record(obj, d, s_kind)
% Add the disturbance record d; an empty tag takes <s_kind><n>.
    arguments (Input)
        obj
        d       % Disturbance record (struct with the fields of add_disturbance).
        s_kind  % Prefix of the automatic tag ("" keeps the tag as given).
    end
    arguments (Output)
        s_tag   % Tag of the added disturbance.
    end
    if strlength(d.Tag) == 0 && ~ismissing(d.Tag) && s_kind ~= ""
        d.Tag = next_tag(obj.tab_disturbance.Tag, s_kind);
    end
    check_tag(d.Tag, obj.s_tag, obj.tab_disturbance.Tag);
    validate_disturbance(d, obj.s_tag, obj.a_PowerNetwork);
    obj.tab_disturbance = [obj.tab_disturbance; record_row(d)];
    s_tag = d.Tag;
end
