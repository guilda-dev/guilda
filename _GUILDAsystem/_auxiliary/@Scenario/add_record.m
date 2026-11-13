function s_tag = add_record(obj, d, s_kind)
% Add the offset and input of record d with one tag; an empty tag takes <s_kind><n>.
%
% The offset goes to tab_offset (at t_start), the input to tab_input; both rows share the
% tag. A record without offset and input marks its time span only: one row in tab_offset
% for a single time, else one row in tab_input. The tag must not be in any of the three
% tables, and Fault or Parallel followed by digits are reserved for tab_event.
    arguments (Input)
        obj
        d (1,1) struct          % Record: Tag, TimeSpan and any fields of add_disturbance (the others blank).
        s_kind (1,1) string     % Prefix of the automatic tag ("" keeps the tag as given).
    end
    arguments (Output)
        s_tag (1,1) string      % Tag of the added disturbance.
    end
    r = blank_record(d.Tag, d.TimeSpan);
    for s_name = string(fieldnames(d)).'
        r.(s_name) = d.(s_name);
    end
    d = r;
    sv_have = [obj.tab_event.Tag; obj.tab_offset.Tag; obj.tab_input.Tag];
    if strlength(d.Tag) == 0 && ~ismissing(d.Tag) && s_kind ~= ""
        % <s_kind><n> with n the largest number in use with this prefix plus one
        sv_num = extractAfter(sv_have(startsWith(sv_have, s_kind)), strlength(s_kind));
        rv_num = str2double(sv_num(matches(sv_num, digitsPattern)));
        d.Tag  = s_kind + (max([0; rv_num(:)]) + 1);
    end
    % Tags name the columns of the phase table: unique and not reserved
    if ismissing(d.Tag) || ismember(d.Tag, ["t1","t2","Properties","Row","Variables",""]) ...
            || matches(d.Tag, ["NoAction", "Fault", "Parallel"] + digitsPattern)
        error(msg("GUILDA:Scenario:ReservedTag", char(string(d.Tag)), char(obj.s_tag)));
    end
    if ismember(d.Tag, sv_have)
        error(msg("GUILDA:Scenario:DuplicateTag", char(d.Tag), char(obj.s_tag)));
    end
    d = normalize_input(d, obj.s_tag);
    validate_disturbance(d, obj.s_tag, obj.a_PowerNetwork);
    ts = d.TimeSpan;
    l_offset = strlength(d.OffsetUnit) > 0 || ~isempty(d.OffsetState) || ~isempty(d.OffsetValue);
    l_input  = strlength(d.InputUnit) > 0 || ~isempty(d.InputName) || ~isempty(d.InputValue);
    if l_offset || ~l_input && ts(1) == ts(end)
        obj.tab_offset = [obj.tab_offset; table(d.Tag, ts(1), d.OffsetUnit, {d.OffsetState}, {d.OffsetValue}, ...
                          'VariableNames', obj.tab_offset.Properties.VariableNames)];
    end
    if l_input || ~l_offset && ts(1) < ts(end)
        obj.tab_input = [obj.tab_input; table(d.Tag, ts, d.InputUnit, {d.InputName}, {d.InputValue}, d.InputMethod, ...
                         'VariableNames', obj.tab_input.Properties.VariableNames)];
    end
    s_tag = d.Tag;
end
