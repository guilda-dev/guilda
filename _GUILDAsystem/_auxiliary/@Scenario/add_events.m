function add_events(obj, tab)
% Add rows to tab_event with their tags (add_fault, add_trip, add_open_branch, JSON, From).
%
% The rows keep their tags, which must not be in tab_event yet. The Point of a parallel
% row is set to NaN (only a fault uses it). The rows are checked together with those in
% the table (validate_events); nothing is added when a check fails.
    arguments (Input)
        obj
        tab table   % Rows with the columns of tab_event (Tag, Target, Time, Status, Point).
    end
    tab = tab(:, ["Tag","Target","Time","Status","Point"]);
    tab.Tag    = string(tab.Tag);
    tab.Target = string(tab.Target);
    tab.Status = string(tab.Status);
    tab.Time   = double(tab.Time);
    tab.Point  = double(tab.Point);
    tab.Point(startsWith(tab.Tag, "Parallel")) = NaN;
    sv_dup = intersect(tab.Tag, obj.tab_event.Tag);
    if ~isempty(sv_dup)
        error(msg("GUILDA:Scenario:DuplicateTag", char(sv_dup(1)), char(obj.s_tag)));
    end
    tab_all = [obj.tab_event; tab];
    validate_events(tab_all, obj.s_tag, obj.a_PowerNetwork);
    obj.tab_event = tab_all;
end
