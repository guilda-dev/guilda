function [tab_phase, sct_event] = compile(obj, sct_dae, time)
% Build the phases of one run of the scenario (called by PowerNetwork.build_simulation_data).
%
% Checks the disturbances against the network as it is now (validate) and splits the
% simulation time into phases in which the state of the disturbances does not change. The
% phase boundaries are t0, the times of the rows of tab_event, the times of the offsets,
% the start and end of the inputs, each point after the first of a time series input with
% InputMethod "zoh" (so that the input is constant within a phase) and tend; times outside
% (t0, tend) are not boundaries. Without any disturbance, the run has one disturbance
% "NoAction" at t0. The disturbances do not change the time.
%
% tab_phase is output.phases: t1, t2 and one logical column per tag (the tags of
% tab_event, then of tab_offset, then of tab_input; a tag of an offset and an input is one
% column), plus NoAction<k> for a phase k without any active disturbance:
%
%      t1 | t2 | Fault001 | Parallel001 | NoAction3
%     ----+----+----------+-------------+----------
%      0  |  1 |    0     |      0      |    0       <- NoAction1 when no disturbance is active
%      1  | .. |    1     |      0      |    0
%
% A tag of tab_event is active in a phase whose start t1 is in [first Time, last Time) of
% its rows. The state of a target in a phase is the Status of its last row with Time <= t1
% (faults and parallel events apart; at one time an end row before a start row).
%
% sct_event(k) holds what phase k applies, as positions in the data of the run sct_dae
% (the tags are matched here, the solver matches none):
%   t1, t2          [s] start and end of the phase
%   iv_tripComp     tripped components (positions in sct_dae.c_comp)
%   iv_tripGC       tripped global controllers (positions in sct_dae.c_gc)
%   iv_faultBus     faulted buses (positions in sct_dae.sv_bus)
%   iv_openBranch   branches opened with "6open" (positions in sct_dae.sv_branch, ascending)
%   iv_offset, rv_offset  the state offsets added at the start of the phase: rows x of
%                   sct_dae.tab_variable and their values (offsets that start there; all
%                   active offsets in the first phase)
%   c_input         one row {iv_row, rv_t, rm_v, s_method} per active input: the rows u of
%                   tab_variable, the times from the start of the phase (increasing), the
%                   values (one row per time, one column per row) and the interpolation
%                   ("foh", "spline"; "zoh" and a constant value: one point, the value of
%                   the phase)
%   sr_event        tags of the active disturbances
%
% Branch faults ("3LG", "6LG"), "3open" and trips of local controllers stop with
% GUILDA:Scenario:NotYetSupported.
    arguments (Input)
        obj                     % Scenario (checked against its network).
        sct_dae (1,1) struct    % Data of the run: tab_variable, sv_bus, sv_branch, sv_comp, sv_lc, sv_gc.
        time    (1,2) double    % [s] Simulation time [t0, tend].
    end
    arguments (Output)
        tab_phase table           % Phase table (output.phases).
        sct_event (:,1) struct    % Data of each phase (n_phase x 1).
    end
    obj.validate();
    s_sc   = obj.s_tag;
    tab_ev = obj.tab_event;

    % Events that the simulation does not handle yet
    lv_new = ismember(tab_ev.Status, ["3LG","6LG","3open"]) ...
           | (tab_ev.Status == "open" & ismember(tab_ev.Target, sct_dae.sv_lc));
    if any(lv_new)
        i = find(lv_new, 1);
        error(msg("GUILDA:Scenario:NotYetSupported", char(tab_ev.Tag(i)), char(s_sc), ...
                  char(tab_ev.Status(i)), char(tab_ev.Target(i))));
    end

    % One record per tag of tab_event (its span), per offset and per input
    c_dist = cell(1,0);
    for s_tag = reshape(unique(tab_ev.Tag, "stable"), 1, [])
        rv_t = tab_ev.Time(tab_ev.Tag == s_tag);
        c_dist{end+1} = blank_record(s_tag, [min(rv_t), max(rv_t)]); %#ok<AGROW>
    end
    for c_tab = {obj.tab_offset, obj.tab_input}
        for r = 1:height(c_tab{1})
            c_dist{end+1} = get_record(c_tab{1}, r); %#ok<AGROW>
        end
    end
    % Without disturbances: an empty one at t0, so that the time table is built as usual
    if isempty(c_dist)
        c_dist = {blank_record("NoAction", time(1))};
    end

    % Phases between consecutive switching times (see the help)
    n_dist = numel(c_dist);
    times  = zeros(n_dist, 2);
    rv_zoh = zeros(0,1);
    for k = 1:n_dist
        d = c_dist{k};
        times(k,:) = d.TimeSpan([1, end]);
        if d.InputMethod == "zoh"
            tb = d.TimeSpan(1) + d.InputValue(2:end,1);
            rv_zoh = [rv_zoh; tb(tb < d.TimeSpan(end))]; %#ok<AGROW>
        end
    end
    sv_dist = string(cellfun(@(d) d.Tag, c_dist, "UniformOutput", false));
    [sv_col, iv_first] = unique(sv_dist, "stable");
    for k = reshape(iv_first(times(iv_first,2) < time(1) | times(iv_first,1) > time(end)), 1, [])
        rv_ts = times(sv_dist == sv_dist(k), :);
        ts = [min(rv_ts(:,1)), max(rv_ts(:,2))];
        if ts(1) == ts(2)
            ts = ts(1);
        end
        show_msg("warning", "GUILDA:Scenario:OutsideTimeSpan", char(sv_dist(k)), char(s_sc), ...
                 mat2str(ts), mat2str(time([1,end]).'));
    end
    rv_switch = unique([time(1); times(:); rv_zoh; time(2)], "sorted", "first");
    rv_switch = rv_switch(rv_switch >= time(1) & rv_switch <= time(2));
    all_time  = [rv_switch(1:end-1), rv_switch(2:end)];
    n_phase   = size(all_time, 1);

    % Activity of each record, and of each tag (column): overlap, or an instant at t1
    lm_act = (all_time(:,1) < times(:,2).' & times(:,1).' < all_time(:,2)) ...
           | (all_time(:,1) == times(:,1).' & times(:,1).' == times(:,2).');
    lm_col = false(n_phase, numel(sv_col));
    for j = 1:numel(sv_col)
        lm_col(:,j) = any(lm_act(:, sv_dist == sv_col(j)), 2);
    end
    sv_none = "NoAction" + string(find(~any(lm_col, 2)));
    lm_col  = [lm_col, ~any(lm_col, 2) & (1:numel(sv_none)) == cumsum(~any(lm_col, 2))];
    sv_col  = [reshape(sv_col, 1, []), reshape(sv_none, 1, [])];
    tab_phase = [array2table(all_time, "VariableNames", ["t1","t2"]), ...
                 array2table(lm_col, "VariableNames", sv_col)];

    % Rows of tab_event in the order they apply: by time, an end row before a start row
    [~, iv_first] = unique(tab_ev.Tag + "|" + tab_ev.Target, "stable");
    lv_start = false(height(tab_ev), 1);
    lv_start(iv_first) = true;
    [~, iv_ord] = sortrows([tab_ev.Time, double(lv_start)]);
    sv_key = string(startsWith(tab_ev.Tag, "Fault")) + "|" + tab_ev.Target;

    % What each phase applies
    tab = sct_dae.tab_variable;
    c_s = cell(n_phase, 1);
    for tp = 1:n_phase
        s = struct();
        s.t1 = all_time(tp,1);
        s.t2 = all_time(tp,2);
        % State of each target: its last row at or before t1
        iv = iv_ord(tab_ev.Time(iv_ord) <= s.t1);
        [~, ia] = unique(sv_key(iv), "last");
        iv = iv(ia);
        sv_target = tab_ev.Target(iv);
        sv_status = tab_ev.Status(iv);
        s.iv_tripComp   = find(ismember(sct_dae.sv_comp, sv_target(sv_status == "open")));
        s.iv_tripGC     = find(ismember(sct_dae.sv_gc, sv_target(sv_status == "open")));
        s.iv_faultBus   = find(ismember(sct_dae.sv_bus, sv_target(sv_status == "BG")));
        s.iv_openBranch = find(ismember(sct_dae.sv_branch, sv_target(sv_status == "6open")));

        % State offsets added at the start of the phase: those that start there (all active
        % offsets in the first phase), summed per row in the order of tab_offset
        c_act  = c_dist(lm_act(tp,:));
        rv_acc = zeros(height(tab), 1);
        lv_set = false(height(tab), 1);
        for k = 1:numel(c_act)
            d = c_act{k};
            if strlength(d.OffsetUnit) == 0 || ~(tp == 1 || d.TimeSpan(1) == s.t1)
                continue
            end
            iv_row = find(tab.Kind == "x" & tab.Owner == d.OffsetUnit);
            [lv_X, loc] = ismember(string(d.OffsetState), tab.Name(iv_row));
            rv_v = d.OffsetValue .* ones(size(d.OffsetState));
            iv_x = iv_row(loc(lv_X));
            rv_acc(iv_x) = rv_acc(iv_x) + reshape(rv_v(lv_X), [], 1);
            lv_set(iv_x) = true;
        end
        s.iv_offset = find(lv_set);
        s.rv_offset = rv_acc(s.iv_offset);

        % Input events: {iv_row, rv_t, rm_v, s_method} per active input (the times from the
        % start of the phase; one point for a constant value and for "zoh")
        c_input = cell(0,4);
        for k = 1:numel(c_act)
            d = c_act{k};
            if strlength(d.InputUnit) == 0
                continue
            end
            iv_row = find(tab.Kind == "u" & tab.Owner == d.InputUnit);
            [lv_N, loc] = ismember(string(d.InputName), tab.Name(iv_row));
            if ~any(lv_N)
                continue
            end
            exV = d.InputValue;
            if d.InputMethod == ""
                rv_v = reshape(exV, 1, []) .* ones(1, numel(d.InputName));
                c_in = {0, rv_v(lv_N), "zoh"};
            else
                rv_t = exV(:,1);
                rm_v = exV(:, 1 + find(lv_N));
                if d.InputMethod == "zoh"
                    % The value of the last point at or before the start of the phase (a
                    % point after the first starts a phase)
                    i_pt = max(1, nnz(d.TimeSpan(1) + rv_t <= s.t1));
                    c_in = {0, rm_v(i_pt,:), "zoh"};
                else
                    c_in = {rv_t - (s.t1 - d.TimeSpan(1)), rm_v, d.InputMethod};
                end
            end
            c_input(end+1,:) = [{iv_row(loc(lv_N))}, c_in]; %#ok<AGROW>
        end
        s.c_input  = c_input;
        s.sr_event = sv_col(lm_col(tp,:)).';
        c_s{tp} = s;
    end
    sct_event = vertcat(c_s{:});
end
