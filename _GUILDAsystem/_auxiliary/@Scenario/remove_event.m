function remove_event(obj, tag)
% Remove events by tag: their rows leave tab_event, tab_offset and tab_input.
%
% A removed event is no longer in the scenario (its a_Scenario is []); an unknown tag
% stops with GUILDA:Scenario:DisturbanceNotFound and nothing is removed.
%
% <@Examples>
% ```matlab
% ev = sc.add_fault("B008", [1, 1.05]);   % two rows of Fault001 in tab_event
% sc.remove_event(ev.s_tag);              % both rows are removed
% ```
    arguments (Input)
        obj
        tag (:,1) string  % Tags of the events to remove.
    end
    sv_have = string(cellfun(@(e) e.s_tag, obj.a_Event, 'UniformOutput', false));
    lv_bad = ~ismember(tag, sv_have);
    if any(lv_bad)
        error(msg("GUILDA:Scenario:DisturbanceNotFound", char(join(tag(lv_bad), ", ")), char(obj.s_tag)));
    end
    lv_rm = ismember(sv_have, tag);
    for ev = reshape(obj.a_Event(lv_rm), 1, [])
        ev{1}.a_Scenario = [];
    end
    obj.a_Event = obj.a_Event(~lv_rm);
end
