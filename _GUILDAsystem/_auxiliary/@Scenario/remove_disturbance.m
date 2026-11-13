function remove_disturbance(obj, tag)
% Remove disturbances by tag: all rows of each tag in tab_event, tab_offset and tab_input.
%
% <@Examples>
% ```matlab
% s_tag = sc.add_fault("B008", [1, 1.05]);   % two rows of Fault001 in tab_event
% sc.remove_disturbance(s_tag);              % both rows are removed
% ```
    arguments (Input)
        obj
        tag (:,1) string % Tags of the disturbances to remove.
    end
    lv_bad = ~ismember(tag, [obj.tab_event.Tag; obj.tab_offset.Tag; obj.tab_input.Tag]);
    if any(lv_bad)
        error(msg("GUILDA:Scenario:DisturbanceNotFound", char(join(tag(lv_bad), ", ")), char(obj.s_tag)));
    end
    obj.tab_event  = obj.tab_event(~ismember(obj.tab_event.Tag, tag), :);
    obj.tab_offset = obj.tab_offset(~ismember(obj.tab_offset.Tag, tag), :);
    obj.tab_input  = obj.tab_input(~ismember(obj.tab_input.Tag, tag), :);
end
