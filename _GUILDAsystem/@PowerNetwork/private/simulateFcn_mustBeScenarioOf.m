function simulateFcn_mustBeScenarioOf(net, s_scenario)
% Validate a scenario tag of net.simulate: the tag of a scenario of the network.
%
% A tag that is not one stops with GUILDA:PowerNetwork:ScenarioNotFound, which lists the
% scenarios of the network (up to 10) or tells how to create one.
    arguments (Input)
        net          % Network (PowerNetwork).
        s_scenario   % Tag to check.
    end
    sv_have = string(cellfun(@(s) s.s_tag, net.a_Scenario, 'UniformOutput', false));
    if ~ismember(string(s_scenario), sv_have)
        error(msg("GUILDA:PowerNetwork:ScenarioNotFound", char(join(string(s_scenario), "', '")), ...
                  char(net.s_tag), char(scenario_hint(sv_have))));
    end
end
