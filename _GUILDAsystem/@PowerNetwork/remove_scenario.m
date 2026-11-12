function remove_scenario(obj, sr_tag)
% Remove simulation scenarios by tag and delete them.
%
% A variable that holds a removed scenario becomes an invalid handle (isvalid is false).
% A tag that is not a scenario of the network stops with
% GUILDA:PowerNetwork:ScenarioNotFound and nothing is removed. The equilibrium does not
% become stale. To keep a copy, add one first: net.add_scenario(tag, From=sc).
%
% <@Examples>
% ```matlab
% net.remove_scenario("case1")
% ```
%
% See also PowerNetwork.add_scenario, Scenario
%
% <@Group> Model building
    arguments (Input)
        obj
        sr_tag (1,:) string   % Tags of the scenarios to remove.
    end
    sv_have = string(cellfun(@(s) s.s_tag, obj.a_Scenario, 'UniformOutput', false));
    sv_missing = sr_tag(~ismember(sr_tag, sv_have));
    if ~isempty(sv_missing)
        error(msg("GUILDA:PowerNetwork:ScenarioNotFound", char(join(sv_missing, "', '")), char(obj.s_tag), ...
                  char(scenario_hint(sv_have))));
    end
    lv_rm = ismember(sv_have, sr_tag);
    a_rm  = obj.a_Scenario(lv_rm);
    obj.a_Scenario = obj.a_Scenario(~lv_rm);
    for k = 1:numel(a_rm)
        delete(a_rm{k});
    end
end
