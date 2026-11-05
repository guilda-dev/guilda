function check_tag(s_tag, s_scenario, sv_tag)
% Tags name the columns of the phase table: unique and not reserved
    if ismissing(s_tag) || ismember(s_tag, ["t1","t2","Properties","Row","Variables",""]) ...
            || matches(s_tag, "NoAction" + digitsPattern)
        error(msg("GUILDA:Scenario:ReservedTag", char(string(s_tag)), char(s_scenario)));
    end
    if ismember(s_tag, sv_tag)
        error(msg("GUILDA:Scenario:DuplicateTag", char(s_tag), char(s_scenario)));
    end
end
