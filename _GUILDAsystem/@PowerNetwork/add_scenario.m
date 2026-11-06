function add_scenario(obj, sc)
% Add simulation scenarios to the network.
%
% `sc` is a Scenario or a cell of Scenario objects (e.g. from Scenario.import_csv). Each
% is checked against this network first (the buses, branches, components and global
% controllers its disturbances name, by tag) and its tag must not be used by another
% scenario of the network; nothing is added when a check fails. A scenario of another
% network is moved: it is removed from that network (use sc.copy() to keep it there).
% Adding a scenario of this network again does nothing. Scenarios are not model data:
% the equilibrium does not become stale and nothing is logged as an edit.
%
% <@Examples>
% ```matlab
% sc = Scenario("case1", Time=[0, 20]);
% sc.add_fault("B008", [0.10, 0.17]);
% sc.add_open_branch("EL003", [0.17, 20]);
% net.add_scenario(sc);
% result = net.simulate(sc);
% ```
%
% See also PowerNetwork.remove_scenario, PowerNetwork.simulate, Scenario
%
% <@Group> Model building
    arguments (Input)
        obj
        sc   % Scenario, or a cell of Scenario objects.
    end
    if ~iscell(sc)
        sc = {sc};
    end
    sc = sc(:);
    if ~all(cellfun(@(s) isa(s, "Scenario") && isscalar(s), sc))
        error(msg("GUILDA:PowerNetwork:NotScenario"));
    end

    % Checks before the network changes
    lv_new  = cellfun(@(s) isempty(s.a_PowerNetwork) || s.a_PowerNetwork ~= obj, sc);
    sv_tag  = string(cellfun(@(s) s.s_tag, sc, 'UniformOutput', false));
    sv_have = string(cellfun(@(s) s.s_tag, obj.a_Scenario, 'UniformOutput', false));
    for k = find(lv_new(:)).'
        if ismember(sv_tag(k), sv_have) || sum(sv_tag(lv_new) == sv_tag(k)) > 1
            error(msg("GUILDA:PowerNetwork:ScenarioTagInUse", char(sv_tag(k)), char(obj.s_tag)));
        end
        sc{k}.validate(obj);
    end

    for k = find(lv_new(:)).'
        if ~isempty(sc{k}.a_PowerNetwork)
            sc{k}.a_PowerNetwork.remove_scenario(sc{k}.s_tag);
        end
        obj.a_Scenario = [obj.a_Scenario; sc(k)];
        sc{k}.a_PowerNetwork = obj;
    end
end
