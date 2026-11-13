function validate_events(tab, s_scenario, net)
% Checks of the rows of tab_event against the network (see the Events of the Scenario help).
%
% Per tag: the targets are known (a fault: buses or branches, not both; a parallel event:
% components, local or global controllers, or branches), each target has two rows (the
% start, then the end) with t_start < t_end, and the Status and Point of the rows fit the
% kind of the target; "3LG" and "3open" need a branch of two or more circuits. Over the
% table: two faults, or two parallel events, of one target do not overlap (touching is
% allowed).
    arguments (Input)
        tab table                   % Rows of tab_event (Tag, Target, Time, Status, Point).
        s_scenario (1,1) string     % Tag of the scenario (for the messages).
        net PowerNetwork            % Network of the scenario.
    end
    s_net  = char(net.s_tag);
    sv_bus = reshape(string(cellfun(@(b) b.s_tag, net.a_Bus, 'UniformOutput', false)), [], 1);
    sv_br  = reshape(string(net.a_Branch), [], 1);
    % Components, their local controllers (nested ones too) and the global controllers
    c_unit = cellfun(@(b) b.a_Component, net.a_Bus, 'UniformOutput', false);
    c_unit = vertcat(cell(0,1), c_unit{:});
    k = 0;
    while k < numel(c_unit)
        k = k + 1;
        c_unit = [c_unit; reshape(c_unit{k}.a_LocalController, [], 1)]; %#ok<AGROW>
    end
    c_unit = [c_unit; reshape(net.a_GlobalController, [], 1)];
    sv_unit = reshape(string(cellfun(@(c) c.s_tag, c_unit, 'UniformOutput', false)), [], 1);

    % Rows of each tag and target
    lv_fault = startsWith(tab.Tag, "Fault");
    for s_tag = reshape(unique(tab.Tag, "stable"), 1, [])
        c_lbl  = {char(s_tag), char(s_scenario)};
        iv_tag = find(tab.Tag == s_tag);
        l_fault = lv_fault(iv_tag(1));
        sv_target = unique(tab.Target(iv_tag), "stable");
        lv_br = ismember(sv_target, sv_br);
        if l_fault
            lv_bus = ismember(sv_target, sv_bus);
            lv_bad = ~lv_bus & ~lv_br;
            if any(lv_bad)
                error(msg("GUILDA:Scenario:UnknownFaultTarget", c_lbl{:}, char(join(sv_target(lv_bad), ", ")), s_net));
            end
            if any(lv_bus) && any(lv_br)
                error(msg("GUILDA:Scenario:MixedFaultTarget", c_lbl{:}, char(join(sv_target(lv_bus), ", ")), ...
                          char(join(sv_target(lv_br), ", "))));
            end
        else
            lv_bad = ~lv_br & ~ismember(sv_target, sv_unit);
            if any(lv_bad)
                error(msg("GUILDA:Scenario:UnknownParallelTarget", c_lbl{:}, char(join(sv_target(lv_bad), ", ")), s_net));
            end
        end
        for i = 1:numel(sv_target)
            s_target = sv_target(i);
            iv = iv_tag(tab.Target(iv_tag) == s_target);
            if numel(iv) ~= 2
                error(msg("GUILDA:Scenario:InvalidEventRows", c_lbl{:}, char(s_target), ...
                          char("it has " + numel(iv) + " row(s), not 2")));
            end
            rv_t = tab.Time(iv);
            if ~isreal(rv_t) || any(isnan(rv_t)) || rv_t(1) > rv_t(2)
                error(msg("GUILDA:Scenario:InvalidTimeSpan", c_lbl{:}, mat2str(rv_t.')));
            end
            if rv_t(1) == rv_t(2)
                error(msg("GUILDA:Scenario:ZeroLengthTimeSpan", c_lbl{:}, mat2str(rv_t.')));
            end
            sv_status = tab.Status(iv);
            rv_point  = tab.Point(iv);
            s_reason  = "";
            if l_fault && ~lv_br(i)
                if sv_status(1) ~= "BG" || ~all(isnan(rv_point))
                    error(msg("GUILDA:Scenario:InvalidFaultStatus", c_lbl{:}, char(s_target), ...
                              char("bus " + s_target + " has Status """ + sv_status(1) + """ and Point " + mat2str(rv_point(1)))));
                end
                s_end = "none";
            elseif l_fault
                if ~ismember(sv_status(1), ["3LG","6LG"]) || isnan(rv_point(1))
                    error(msg("GUILDA:Scenario:InvalidFaultStatus", c_lbl{:}, char(s_target), ...
                              char("branch " + s_target + " has Status """ + sv_status(1) + """ and Point " + mat2str(rv_point(1)))));
                end
                if ~all(rv_point > 0 & rv_point < 1)
                    error(msg("GUILDA:Scenario:InvalidPoint", c_lbl{:}, char(s_target), mat2str(rv_point.')));
                end
                s_end = "none";
            else
                sr_start = "open";
                if lv_br(i)
                    sr_start = ["3open","6open"];
                end
                if ~ismember(sv_status(1), sr_start)
                    s_reason = "the start has Status """ + sv_status(1) + """, not " + join("""" + sr_start + """", " or ");
                end
                s_end = "close";
            end
            if s_reason == "" && sv_status(2) ~= s_end
                s_reason = "the end has Status """ + sv_status(2) + """, not """ + s_end + """";
            end
            if s_reason ~= ""
                error(msg("GUILDA:Scenario:InvalidEventRows", c_lbl{:}, char(s_target), char(s_reason)));
            end
            if lv_br(i) && ismember(sv_status(1), ["3LG","3open"]) ...
                    && net.a_Branch{sv_br == s_target}.tab_parameter.dynamics.circuit == 1
                error(msg("GUILDA:Scenario:SingleCircuit", c_lbl{:}, char(sv_status(1)), char(s_target)));
            end
        end
    end

    % Two events of one kind on one target do not overlap: [t_start, t_end) of each tag
    [~, iv_first] = unique(tab.Tag + "|" + tab.Target, "stable");
    iv_last = iv_first;
    for i = 1:numel(iv_first)
        iv_last(i) = find(tab.Tag == tab.Tag(iv_first(i)) & tab.Target == tab.Target(iv_first(i)), 1, "last");
    end
    sv_group = string(lv_fault(iv_first)) + "|" + tab.Target(iv_first);
    for s_group = reshape(unique(sv_group), 1, [])
        iv = find(sv_group == s_group);
        [rv_start, iv_ord] = sort(tab.Time(iv_first(iv)));
        iv = iv(iv_ord);
        rv_end = tab.Time(iv_last(iv));
        i_bad = find(rv_start(2:end) < rv_end(1:end-1), 1);
        if ~isempty(i_bad)
            ia = iv_first(iv(i_bad));
            ib = iv_first(iv(i_bad + 1));
            error(msg("GUILDA:Scenario:OverlappingEvents", char(tab.Tag(ia)), char(tab.Tag(ib)), char(s_scenario), ...
                      char(tab.Target(ia)), mat2str([tab.Time(ia), rv_end(i_bad)]), ...
                      mat2str([tab.Time(ib), rv_end(i_bad + 1)])));
        end
    end
end
