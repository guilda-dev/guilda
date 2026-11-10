function handle_edit(obj, a_layer, tag, log)
% Network-wide rules for an edit of any layer of the network (LayerPackage.log_edit),
% also before the first initialize.
%
% - At most one slack bus: a bus reports bus.l_isSlack = true as a "Slack" edit, and the
%   network releases the others.
% - The stale tag powerflow is marked for the edits that change the power flow:
%     the network     base (baseMVA), Topology (buses and branches added, removed or
%                     replaced)
%     a bus           dynamics (shunt), powerflow, Slack, Topology (components connected,
%                     replaced or removed)
%     a branch        dynamics
%     a component     powerflow
% - The stale tag input is marked for an edit of the inputs of a component (set_input):
%   only initialize(Method="FixedInput") keeps them; no revision counter changes.
% - The revision counters are increased for the same edits; the solvers compare them with
%   the values their warm start and cache were made with:
%     n_revY         the network base (baseMVA) and Topology, bus dynamics (shunt), branch
%                    dynamics: the bus admittance matrix
%     n_revPF        every n_revY edit, and bus powerflow, Slack and Topology, component
%                    powerflow: the power flow equations
%     n_revTopology  the network Topology: the warm start (and every cache)
%     n_revOPF       every n_revPF edit, the network Hz, and the operation and OPF
%                    parameters and the tag of any layer: the OPF problem
% - The stale tag odefcn is marked for a Hz edit of the network (base, told from baseMVA
%   by s_lastEdited of its base container): the edit does not reach the models, whose handles bind
%   the frequency.
% Other edits are ignored here (the components and controllers mark their own tags).
%
% <@Group> Called by analyses
    arguments (Input)
        obj
        a_layer        % Edited layer (the owner for a parameter edit).
        tag string     % Kind of edit (see LayerPackage.log_edit).
        log string     % Message of the edit.
    end
    if tag == "Slack"
        keep_one_slack(obj, a_layer);
    end
    if a_layer == obj
        if tag == "base" && obj.a_Parameter{cellfun(@(p) p.s_tag=="base", obj.a_Parameter)}.s_lastEdited == "Hz"
            obj.sct_stale.odefcn(end+1,1) = log;
            obj.n_revOPF = obj.n_revOPF + 1;    % p.base of the OPF Cost and Constraint
            return
        end
        l_Y        = matches(tag, ["base","Topology"]);
        l_powerflow = l_Y;
        obj.n_revTopology = obj.n_revTopology + (tag == "Topology");
    elseif isa(a_layer, "Bus")
        l_Y         = tag == "dynamics";
        l_powerflow = matches(tag, ["dynamics","powerflow","Slack","Topology"]);
    elseif isa(a_layer, "Branch")
        l_Y         = tag == "dynamics";
        l_powerflow = l_Y;
    elseif isa(a_layer, "Component")
        l_Y         = false;
        l_powerflow = tag == "powerflow";
        if tag == "input"
            obj.sct_stale.input(end+1,1) = log;
        end
    else
        l_Y         = false;
        l_powerflow = false;
    end
    obj.n_revY = obj.n_revY + l_Y;
    obj.n_revOPF = obj.n_revOPF + (l_powerflow || matches(tag, ["operation","OPF","Tag"]));
    if l_powerflow
        obj.n_revPF = obj.n_revPF + 1;
        obj.sct_stale.powerflow(end+1,1) = log;
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
