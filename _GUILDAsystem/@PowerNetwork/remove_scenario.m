function remove_scenario(obj, sr_tag)
% Remove simulation scenarios by tag.
%
% The removed scenarios no longer refer to this network (sc.a_PowerNetwork is empty); add
% them to a network again with add_scenario. The equilibrium does not become stale.
%
% <@Examples>
% ```matlab
% net.remove_scenario("case1")
% ```
%
% See also PowerNetwork.add_scenario, Scenario
%
% <@Group> Model building
    arguments
        obj
        sr_tag (1,:) string   % Tags of the scenarios to remove.
    end
    sv_have = string(cellfun(@(s) s.s_tag, obj.a_Scenario, 'UniformOutput', false));
    sv_missing = sr_tag(~ismember(sr_tag, sv_have));
    if ~isempty(sv_missing)
        error(msg("GUILDA:PowerNetwork:ScenarioNotFound", char(join(sv_missing, "', '")), char(obj.s_tag)));
    end
    lv_rm = ismember(sv_have, sr_tag);
    a_rm  = obj.a_Scenario(lv_rm);
    obj.a_Scenario = obj.a_Scenario(~lv_rm);
    cellfun(@(s) s.set_parent([]), a_rm);
end
