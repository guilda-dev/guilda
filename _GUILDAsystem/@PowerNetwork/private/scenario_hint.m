function s_hint = scenario_hint(sv_have)
% Text of GUILDA:PowerNetwork:ScenarioNotFound: the scenarios of the network, or how to create one
    arguments (Input)
        sv_have string   % Tags of the scenarios of the network.
    end
    arguments (Output)
        s_hint (1,1) string   % One sentence.
    end
    if isempty(sv_have)
        s_hint = "The network has no scenario: create one with net.add_scenario(""name"") (its Time is [0, 10]).";
        return
    end
    sv_show = "'" + sv_have(1:min(10, end)) + "'";
    if numel(sv_have) > 10
        sv_show(end+1) = "... (" + numel(sv_have) + " in all)";
    end
    s_hint = "Scenarios of the network: " + join(sv_show, ", ") + ". Create another with net.add_scenario.";
end
