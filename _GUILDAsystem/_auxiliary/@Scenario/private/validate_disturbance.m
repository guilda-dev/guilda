function validate_disturbance(d, s_scenario, net)
% Checks of one offset and input record; with net = [], only those without the network.
    arguments (Input)
        d           % Record (struct with the fields of add_disturbance, see blank_record).
        s_scenario  % Tag of the scenario (for the messages).
        net         % Network of the scenario, or [].
    end
    c_lbl = {char(d.Tag), char(s_scenario)};
    ts = d.TimeSpan;
    if ~isnumeric(ts) || ~isreal(ts) || any(isnan(ts)) || (numel(ts) == 2 && ts(1) > ts(2))
        s_ts = class(ts);
        if isnumeric(ts)
            s_ts = mat2str(ts);
        end
        error(msg("GUILDA:Scenario:InvalidTimeSpan", c_lbl{:}, s_ts));
    end

    % An input needs its end time; an offset acts at one instant.
    l_lasting = strlength(d.InputUnit) > 0 || ~isempty(d.InputName) || ~isempty(d.InputValue);
    if l_lasting && (isscalar(ts) || ts(1) == ts(2))
        error(msg("GUILDA:Scenario:ZeroLengthTimeSpan", c_lbl{:}, mat2str(ts)));
    end

    l_net = ~isempty(net);
    if l_net
        s_net  = char(net.s_tag);
        a_comp = cellfun(@(b) b.a_Component, net.a_Bus, 'UniformOutput', false);
        a_comp = vertcat(cell(0,1), a_comp{:});
        sv_tag = string(cellfun(@(c) c.s_tag, a_comp, 'UniformOutput', false));
    end

    if strlength(d.OffsetUnit) > 0 || ~isempty(d.OffsetState) || ~isempty(d.OffsetValue)
        if l_net
            lv_cmp = sv_tag == d.OffsetUnit;
            if ~any(lv_cmp)
                error(msg("GUILDA:Scenario:UnknownOffsetUnit", c_lbl{:}, char(d.OffsetUnit), s_net));
            end
            sv_x = string(a_comp{find(lv_cmp,1)}.sv_x(:));
            lv_bad = ~ismember(d.OffsetState, sv_x);
            if any(lv_bad)
                error(msg("GUILDA:Scenario:UnknownOffsetState", c_lbl{:}, ...
                        char(join(d.OffsetState(lv_bad), ", ")), char(d.OffsetUnit), char(join(sv_x, ", "))));
            end
        end
        checkValueCount(c_lbl, "OffsetValue", d.OffsetValue, "OffsetState", d.OffsetState);
    end

    if strlength(d.InputUnit) == 0 && isempty(d.InputName) && isempty(d.InputValue)
        return
    end
    if l_net
        lv_cmp = sv_tag == d.InputUnit;
        if ~any(lv_cmp)
            error(msg("GUILDA:Scenario:UnknownInputUnit", c_lbl{:}, char(d.InputUnit), s_net));
        end
        sv_u = string(a_comp{find(lv_cmp,1)}.sv_u(:));
        lv_bad = ~ismember(d.InputName, sv_u);
        if any(lv_bad)
            error(msg("GUILDA:Scenario:UnknownInputName", c_lbl{:}, ...
                    char(join(d.InputName(lv_bad), ", ")), char(d.InputUnit), char(join(sv_u, ", "))));
        end
    end
    if d.InputMethod == ""
        checkValueCount(c_lbl, "InputValue", d.InputValue, "InputName", d.InputName);
        return
    end
    % A time series [t, v_1, ..., v_n] (normalize_input made it from a matrix or a table)
    v = d.InputValue;
    n_name = numel(d.InputName);
    s_reason = "";
    if ~isnumeric(v) || ~isreal(v) || ~ismatrix(v) || isempty(v)
        s_reason = "it is not a real numeric matrix";
    elseif n_name == 0 || size(v,2) ~= 1 + n_name
        s_reason = "it has " + size(v,2) + " column(s) for " + n_name + " input name(s)";
    elseif ~all(isfinite(v), "all")
        s_reason = "it has a value that is not finite";
    elseif v(1,1) ~= 0
        s_reason = "the first time is " + v(1,1) + ", not 0";
    elseif any(diff(v(:,1)) <= 0)
        s_reason = "the times do not increase strictly";
    end
    if s_reason ~= ""
        error(msg("GUILDA:Scenario:InvalidInputSeries", c_lbl{:}, char(s_reason)));
    end
end
