function insert_event(obj, ev, l_keepTag)
% Add an event at the end of a_Event and check all events; on an error it is taken out again.
%
% Tags: a fault gets Fault<n> and a trip or a branch opening Parallel<n> (%03d, the largest
% number of the prefix in use plus one; trips and openings share the numbers), unless
% l_keepTag keeps its tag (add_scenario From, JSON). An offset or an input keeps its tag,
% and an empty tag becomes offset<n> or input<n> (no zero padding). Then validate checks all
% the events and tags against the network; when a check fails, the event is removed (its
% a_Scenario is [] again) and the error is thrown.
    arguments (Input)
        obj
        ev (1,1) EventBase          % Event not in a scenario.
        l_keepTag (1,1) logical     % Keep the tag of a fault, trip or opening.
    end
    l_numbered = ev.s_table == "event";
    if (l_numbered && ~l_keepTag) || (~l_numbered && ev.s_tag == "")
        sv_have = string(cellfun(@(e) e.s_tag, obj.a_Event, 'UniformOutput', false));
        sv_num  = extractAfter(sv_have(startsWith(sv_have, ev.s_prefix)), strlength(ev.s_prefix));
        n_next  = max([0; str2double(sv_num(matches(sv_num, digitsPattern)))]) + 1;
        if l_numbered
            ev.s_tag = ev.s_prefix + string(sprintf("%03d", n_next));
        else
            ev.s_tag = ev.s_prefix + n_next;
        end
    end
    ev.a_Scenario = obj;
    obj.a_Event{end+1, 1} = ev;
    try
        obj.validate();
    catch ME
        obj.a_Event(end) = [];
        ev.a_Scenario = [];
        rethrow(ME)
    end
end
