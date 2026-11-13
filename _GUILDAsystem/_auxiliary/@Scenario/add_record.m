function s_tag = add_record(obj, d, s_kind)
% Add the disturbance record d; an empty tag takes <s_kind><n>.
    arguments (Input)
        obj
        d       % Disturbance record (struct with the fields of add_disturbance).
        s_kind  % Prefix of the automatic tag ("" keeps the tag as given).
    end
    arguments (Output)
        s_tag   % Tag of the added disturbance.
    end
    if strlength(d.Tag) == 0 && ~ismissing(d.Tag) && s_kind ~= ""
        % <s_kind><n> with n the largest number in use with this prefix plus one
        sv_tag = obj.tab_disturbance.Tag;
        sv_num = extractAfter(sv_tag(startsWith(sv_tag, s_kind)), strlength(s_kind));
        rv_num = str2double(sv_num(matches(sv_num, digitsPattern)));
        d.Tag  = s_kind + (max([0; rv_num(:)]) + 1);
    end
    % Tags name the columns of the phase table: unique and not reserved
    if ismissing(d.Tag) || ismember(d.Tag, ["t1","t2","Properties","Row","Variables",""]) ...
            || matches(d.Tag, "NoAction" + digitsPattern)
        error(msg("GUILDA:Scenario:ReservedTag", char(string(d.Tag)), char(obj.s_tag)));
    end
    if ismember(d.Tag, obj.tab_disturbance.Tag)
        error(msg("GUILDA:Scenario:DuplicateTag", char(d.Tag), char(obj.s_tag)));
    end
    d = normalize_input(d, obj.s_tag);
    validate_disturbance(d, obj.s_tag, obj.a_PowerNetwork);
    ts = d.TimeSpan;
    if isscalar(ts)
        ts = [ts, ts];
    end
    row = table(d.Tag, ts, {d.FaultBus}, {d.TripUnit}, {d.OpenBranch}, d.OffsetUnit, ...
                {d.OffsetState}, {d.OffsetValue}, d.InputUnit, {d.InputName}, {d.InputValue}, d.InputMethod, ...
                'VariableNames', ["Tag","TimeSpan","FaultBus","TripUnit","OpenBranch","OffsetUnit", ...
                                  "OffsetState","OffsetValue","InputUnit","InputName","InputValue","InputMethod"]);
    obj.tab_disturbance = [obj.tab_disturbance; row];
    s_tag = d.Tag;
end
