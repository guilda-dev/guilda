function remove_disturbance(obj, tag)
% Remove disturbances by tag.
    arguments (Input)
        obj
        tag (:,1) string % Tags of the disturbances to remove.
    end
    lv_bad = ~ismember(tag, obj.tab_disturbance.Tag);
    if any(lv_bad)
        error(msg("GUILDA:Scenario:DisturbanceNotFound", char(join(tag(lv_bad), ", ")), char(obj.s_tag)));
    end
    obj.tab_disturbance = obj.tab_disturbance(~ismember(obj.tab_disturbance.Tag, tag), :);
end
