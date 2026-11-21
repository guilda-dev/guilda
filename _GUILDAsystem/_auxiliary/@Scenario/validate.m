function validate(obj)
% Check every event against the network of the scenario as it is now.
%
% (1) Tags: an offset or input tag is not reserved (GUILDA:Scenario:ReservedTag: t1, t2,
% Properties, Row, Variables, empty, NoAction, Fault or Parallel followed by digits), and
% each tag is used by one event only (GUILDA:Scenario:DuplicateTag). (2) The rows of
% tab_event (validate_events). (3) Each row of tab_offset and tab_input
% (validate_disturbance).
    arguments (Input)
        obj
    end
    sv_seen = strings(0,1);
    for k = 1:numel(obj.a_Event)
        s_tag = obj.a_Event{k}.s_tag;
        if obj.a_Event{k}.s_table ~= "event" && (ismissing(s_tag) ...
                || ismember(s_tag, ["t1","t2","Properties","Row","Variables",""]) ...
                || matches(s_tag, ["NoAction", "Fault", "Parallel"] + digitsPattern))
            error(msg("GUILDA:Scenario:ReservedTag", char(string(s_tag)), char(obj.s_tag)));
        end
        if ismember(s_tag, sv_seen)
            error(msg("GUILDA:Scenario:DuplicateTag", char(s_tag), char(obj.s_tag)));
        end
        sv_seen(end+1, 1) = s_tag; %#ok<AGROW>
    end
    validate_events(obj.tab_event, obj.s_tag, obj.a_PowerNetwork);
    for c_tab = {obj.tab_offset, obj.tab_input}
        for k = 1:height(c_tab{1})
            validate_disturbance(get_record(c_tab{1}, k), obj.s_tag, obj.a_PowerNetwork);
        end
    end
end
