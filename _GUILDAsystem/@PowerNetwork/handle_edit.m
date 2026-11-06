function handle_edit(obj, a_layer, tag, log)
% Network-wide rules for an edit of any layer of the network (LayerPackage.log_edit),
% also before the first initialize.
%
% - At most one slack bus: a bus reports bus.l_isSlack = true as a "Slack" edit, and the
%   network releases the others.
% - The stale tag powerflow is marked for the edits that change the power flow:
%     the network     base (baseMVA, told from Hz by Parameter.s_lastEdited), Topology
%                     (buses and branches added, removed or replaced)
%     a bus           dynamics (shunt), powerflow, Slack, Topology (components connected,
%                     replaced or removed)
%     a branch        dynamics
%     a component     powerflow
%   Other edits are ignored here (the components and controllers mark their own tags).
%
% <@Group> Called by analyses
    arguments (Input)
        obj
        a_layer        % Edited layer (a Parameter container for a parameter edit).
        tag string     % Kind of edit (see LayerPackage.log_edit).
        log string     % Message of the edit.
    end
    if tag == "Slack"
        keep_one_slack(obj, a_layer);
    end
    if changes_powerflow(obj, a_layer, tag)
        obj.mark_stale("powerflow", log);
    end
end


function l = changes_powerflow(obj, a_layer, tag)
% True for the edits listed in the help
    a_owner = a_layer.edit_owner();
    if a_owner == obj
        l = (tag == "base" && a_layer.s_lastEdited == "baseMVA") || tag == "Topology";
    elseif isa(a_owner, "Bus")
        l = matches(tag, ["dynamics","powerflow","Slack","Topology"]);
    elseif isa(a_owner, "Branch")
        l = tag == "dynamics";
    elseif isa(a_owner, "Component")
        l = tag == "powerflow" && isa(a_layer, "Parameter");
    else
        l = false;
    end
end


function keep_one_slack(obj, a_layer)
% Releases the other buses when a_layer became the slack bus
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
