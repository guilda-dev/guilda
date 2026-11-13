function [tab_phase, sct_event] = compile(obj, sct_dae, time)
% Build the phases of one run of the scenario (called by PowerNetwork.build_simulation_data).
%
% Checks the disturbances against the network as it is now (validate) and splits the
% simulation time into phases in which the set of active disturbances does not change.
% Each point after the first of a time series input with InputMethod "zoh" is also a
% phase boundary, so that the input is constant within a phase. Without any disturbance,
% the run has one disturbance "NoAction" at t0. The disturbances do not change the time.
%
% tab_phase is output.phases: t1, t2 and one logical column per disturbance (its tag), plus
% NoAction<k> for a phase k without any active disturbance:
%
%      t1 | t2 | fault | open | NoAction3
%     ----+----+-------+------+----------
%      0  |  1 |   0   |   0  |    0       <- NoAction1 when no disturbance is active
%      1  | .. |   1   |   0  |    0
%
% sct_event(k) holds what phase k applies, as positions in the data of the run sct_dae
% (the tags are matched here, the solver matches none):
%   t1, t2          [s] start and end of the phase
%   iv_tripComp     tripped components (positions in sct_dae.c_comp)
%   iv_tripGC       tripped global controllers (positions in sct_dae.c_gc)
%   iv_faultBus     faulted buses (positions in sct_dae.sv_bus)
%   iv_openBranch   open branches (positions in sct_dae.sv_branch, ascending)
%   iv_offset, rv_offset  the state offsets added at the start of the phase: rows x of
%                   sct_dae.tab_variable and their values (offsets of the disturbances that
%                   start there; all active offsets in the first phase)
%   c_input         one row {iv_row, rv_t, rm_v, s_method} per active input disturbance:
%                   the rows u of tab_variable, the times from the start of the phase
%                   (increasing), the values (one row per time, one column per row) and the
%                   interpolation ("foh", "spline"; "zoh" and a constant value: one point,
%                   the value of the phase)
%   sr_event        tags of the active disturbances
    arguments (Input)
        obj                     % Scenario (checked against its network).
        sct_dae (1,1) struct    % Data of the run: tab_variable, sv_bus, sv_branch, sv_comp, sv_gc.
        time    (1,2) double    % [s] Simulation time [t0, tend].
    end
    arguments (Output)
        tab_phase table           % Phase table (output.phases).
        sct_event (:,1) struct    % Data of each phase (n_phase x 1).
    end
    obj.validate();

    c_dist = cell(1,0);
    tab = obj.tab_disturbance;
    for r = 1:height(tab)
        d = Scenario.record(tab, r);
        d.Scenario = obj.s_tag;
        c_dist{end+1} = d; %#ok<AGROW>
    end

    % Without disturbances: an empty one at t0, so that the time table is built as usual
    if isempty(c_dist)
        d = Scenario.blank("NoAction", time(1));
        d.Scenario = "";
        c_dist = {d};
    end

    [tab_phase, c_dist] = phase_table(c_dist, time);
    sct_event = phase_data(tab_phase, c_dist, sct_dae);
end


function [tab_phase, c_dist] = phase_table(c_dist, time)
% Time table of the phases (see compile)
    n_dist = numel(c_dist);
    times = zeros(n_dist,2);
    for k = 1:n_dist
        argi = c_dist{k}.TimeSpan;
        if isscalar(argi)
            times(k,:) = ones(1,2)*argi;
        else
            times(k,:) = argi;
        end
    end

    lv_out = times(:,2) < time(1) | times(:,1) > time(end);
    for k = find(lv_out(:))'
        ts = times(k,:);
        if ts(1) == ts(2)
            ts = ts(1);
        end
        show_msg("warning", "GUILDA:Scenario:OutsideTimeSpan", char(c_dist{k}.Tag), char(c_dist{k}.Scenario), ...
                mat2str(ts), mat2str(time([1,end]).'));
    end

    % The points of a "zoh" input are phase boundaries
    rv_zoh = zeros(0,1);
    for k = 1:n_dist
        d = c_dist{k};
        if d.InputMethod == "zoh"
            tb = d.TimeSpan(1) + d.InputValue(2:end,1);
            rv_zoh = [rv_zoh; tb(tb < d.TimeSpan(end))]; %#ok<AGROW>
        end
    end
    all_time = getTimeSpan([times(:); rv_zoh], time);

    vtab = size(all_time,1);
    rtab = size(times,1);

    varNames = cellfun(@(d) d.Tag, c_dist);
    tab = array2table(false(vtab,rtab), "VariableNames", varNames);
    for i = 1:vtab
        fti = all_time(i,1);
        eti = all_time(i,2);
        for j = 1:rtab
            ftj = times(j,1);
            etj = times(j,2);

            if (fti < etj) && (ftj < eti)
                tab{i,j} = true;
            elseif (fti == ftj) && (fti == etj)
                tab{i,j} = true;
            end
        end
    end

    for IT = 1:vtab
        if all( ~tab{IT,:} )
            lv_tab     = false(vtab,1);
            lv_tab(IT) = true;
            s_none     = "NoAction" + num2str(IT);
            tabInsert  = table(lv_tab, 'VariableNames', s_none);
            d          = Scenario.blank(s_none, all_time(IT,:));
            d.Scenario = "";

            tab    = [tab, tabInsert]; %#ok<AGROW>
            c_dist = [c_dist, {d}];    %#ok<AGROW>
        end
    end

    tab_phase = [array2table(all_time, "VariableNames", ["t1","t2"]), tab];
end


function sct_event = phase_data(tab_phase, c_dist, sct_dae)
% What each phase applies, as positions (see compile)
    tab = sct_dae.tab_variable;
    n_phase = height(tab_phase);
    c_s = cell(n_phase, 1);
    sv_name = string(tab_phase.Properties.VariableNames(3:end));
    for tp = 1:n_phase
        lv_act = tab_phase{tp,3:end};
        c_act  = c_dist(lv_act);
        s = struct();
        s.t1 = tab_phase{tp,"t1"};
        s.t2 = tab_phase{tp,"t2"};
        sv = tags(c_act, "TripUnit");
        s.iv_tripComp   = find(ismember(sct_dae.sv_comp, sv));
        s.iv_tripGC     = find(ismember(sct_dae.sv_gc, sv));
        s.iv_faultBus   = find(ismember(sct_dae.sv_bus, tags(c_act, "FaultBus")));
        s.iv_openBranch = find(ismember(sct_dae.sv_branch, tags(c_act, "OpenBranch")));
        [s.iv_offset, s.rv_offset] = phase_offsets(c_act(:), tab, s.t1, tp == 1);
        s.c_input  = phase_inputs(c_act(:), tab, s.t1);
        s.sr_event = sv_name(lv_act).';
        c_s{tp} = s;
    end
    sct_event = vertcat(c_s{:});
end


function sv = tags(c_act, s_field)
% Tags of one field over the active disturbances
    c  = cellfun(@(d) reshape(string(d.(s_field)), [], 1), c_act, 'UniformOutput', false);
    sv = vertcat(strings(0,1), c{:});
end

function [iv_offset, rv_offset] = phase_offsets(c_act, tab, t1, l_first)
% State offsets added at the start of a phase: those of the disturbances that start
% there (all active offsets in the first phase), summed per row in the order of the
% disturbances
    rv_acc = zeros(height(tab), 1);
    lv_set = false(height(tab), 1);
    for k = 1:numel(c_act)
        d = c_act{k};
        if strlength(d.OffsetUnit) == 0 || ~(l_first || d.TimeSpan(1) == t1)
            continue
        end
        iv_row = find(tab.Kind == "x" & tab.Owner == d.OffsetUnit);
        [lv_X, loc] = ismember(string(d.OffsetState), tab.Name(iv_row));
        rv_v = d.OffsetValue .* ones(size(d.OffsetState));
        iv = iv_row(loc(lv_X));
        rv_acc(iv) = rv_acc(iv) + reshape(rv_v(lv_X), [], 1);
        lv_set(iv) = true;
    end
    iv_offset = find(lv_set);
    rv_offset = rv_acc(iv_offset);
end

function c_input = phase_inputs(c_act, tab, t1)
% Input events of a phase: {iv_row, rv_t, rm_v, s_method} per active input disturbance
% (the times from the start of the phase; one point for a constant value and for "zoh")
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
                % point after the first starts a phase, see phase_table)
                i_pt = max(1, nnz(d.TimeSpan(1) + rv_t <= t1));
                c_in = {0, rm_v(i_pt,:), "zoh"};
            else
                c_in = {rv_t - (t1 - d.TimeSpan(1)), rm_v, d.InputMethod};
            end
        end
        c_input(end+1,:) = [{iv_row(loc(lv_N))}, c_in]; %#ok<AGROW>
    end
end
