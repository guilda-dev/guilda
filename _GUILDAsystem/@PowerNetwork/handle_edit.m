function handle_edit(obj, a_layer, tag, log)
% Network-wide rules for an edit of any layer of the network (log_edit), also
% before the first initialize: at most one slack bus (a bus reports
% bus.l_isSlack = true as a "Slack" edit; the network releases the others),
% and a network Hz edit marks the f_* handles of every layer, so the next
% analysis (check_edit) builds them with the new frequency.
%
% <@Group> Called by analyses
    arguments (Input)
        obj
        a_layer        % Edited layer (the bus for a "Slack" edit).
        tag string     % Kind of edit (see edit_effect).
        log string     % Log message.
    end
    handle_edit@PowerSystemModel(obj, a_layer, tag, log);
    if tag == "Parameter(base)" && log == "edit Hz" && isa(a_layer, "Parameter") && obj.is_parent_of(a_layer)
        obj.mark_odefcn();
        return
    end
    if tag ~= "Slack"
        return
    end
    lv_this = tools.vcellfun(@(b) b == a_layer, obj.a_Bus);
    if ~any(lv_this) || ~obj.a_Bus{lv_this}.l_isSlack
        return
    end
    for i = find(~lv_this(:)')
        bus = obj.a_Bus{i};
        if bus.l_isSlack
            bus.l_isSlack = false;
        end
    end
end
