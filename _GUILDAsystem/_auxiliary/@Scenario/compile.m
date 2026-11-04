function [tab_phase, s_phase] = compile(c_scenario, net, time)
% Build the phases of one run from its scenarios (called by SolverODE.solve).
%
% Checks the scenarios against net (each belongs to it, and the tags of its disturbances
% exist in it now), combines their disturbances and splits the simulation time into phases
% in which the set of active disturbances does not change. Without any disturbance, the
% run has one disturbance "NoAction" at t0 (t0 = 0 without a time), so that time = []
% gives [0, 10].
%
% tab_phase is output.phases: t1, t2 and one logical column per disturbance (its tag), plus
% NoAction<k> for a phase k without any active disturbance:
%
%      t1 | t2 | fault | open | NoAction3
%     ----+----+-------+------+----------
%      0  |  1 |   0   |   0  |    0       <- NoAction1 when no disturbance is active
%      1  | .. |   1   |   0  |    0
%
% s_phase(k) holds what phase k applies, built once here: t1, t2, sv_event (tags of the
% active disturbances), sv_fault, sv_trip, sv_open (tags), and c_Xoffset, c_Uoffset with one
% cell per component in the order of the buses and their components: the state offset
% added at the start of the phase (offsets of the disturbances that start there; all active
% offsets in the first phase) and the input function u(t) of the phase, t from the start
% of the phase ([] without an input).
    arguments
        c_scenario cell                 % Scenarios of the run.
        net                             % Network being simulated.
        time (:,1) double = []          % [s] [t0; tend], or [] for the time span of the disturbances.
    end
    arguments (Output)
        tab_phase table   % Phase table (output.phases).
        s_phase   struct  % Data of each phase (n_phase x 1).
    end

    % Each scenario: a scalar of this network, with its tags in the network now
    if ~all(cellfun(@(s) isa(s, "Scenario") && isscalar(s), c_scenario))
        error(msg("GUILDA:Scenario:ScenarioArray"));
    end
    for k = 1:numel(c_scenario)
        sc = c_scenario{k};
        if isempty(sc.a_PowerNetwork) || sc.a_PowerNetwork ~= net
            str_owner = "no network";
            if ~isempty(sc.a_PowerNetwork)
                str_owner = "network """ + sc.a_PowerNetwork.str_tag + """";
            end
            error(msg("GUILDA:Scenario:OtherNetwork", char(sc.str_tag), char(net.str_tag), char(str_owner)));
        end
        sc.validate(net);
    end

    % Disturbances of all the scenarios, in the order of the scenarios
    c_dist = cell(1,0);
    for k = 1:numel(c_scenario)
        tab = c_scenario{k}.tab_disturbance;
        for r = 1:height(tab)
            d = Scenario.record(tab, r);
            d.Scenario = c_scenario{k}.str_tag;
            c_dist{end+1} = d; %#ok<AGROW>
        end
    end
    sv_tag = string(cellfun(@(d) d.Tag, c_dist, 'UniformOutput', false));
    [~, iv_first] = unique(sv_tag, 'stable');
    if numel(iv_first) < numel(sv_tag)
        str_dup = sv_tag(setdiff(1:numel(sv_tag), iv_first));
        str_dup = str_dup(1);
        sv_sc   = cellfun(@(d) d.Scenario, c_dist(sv_tag == str_dup));
        error(msg("GUILDA:Scenario:DuplicateRunTag", char(str_dup), char(join(unique(sv_sc, 'stable'), ", "))));
    end

    % Without disturbances: an empty one at t0, so that the time table is built as usual
    if isempty(c_dist)
        t_start = 0;
        if ~isempty(time)
            t_start = time(1);
        end
        d = Scenario.blank("NoAction", t_start);
        d.Scenario = "";
        c_dist = {d};
    end

    [tab_phase, c_dist] = phase_table(c_dist, time);
    s_phase = phase_data(tab_phase, c_dist, net);
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

    if numel(time) >= 2
        lv_out = times(:,2) < time(1) | times(:,1) > time(end);
        for k = find(lv_out(:))'
            ts = times(k,:);
            if ts(1) == ts(2)
                ts = ts(1);
            end
            warning(msg("GUILDA:Scenario:OutsideTimeSpan", char(c_dist{k}.Tag), char(c_dist{k}.Scenario), ...
                    mat2str(ts), mat2str(time([1,end]).')));
        end
    end

    all_time = getTimeSpan(times, time);

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
            str_none   = "NoAction" + num2str(IT);
            tabInsert  = table(lv_tab, 'VariableNames', str_none);
            d          = Scenario.blank(str_none, all_time(IT,:));
            d.Scenario = "";

            tab    = [tab, tabInsert]; %#ok<AGROW>
            c_dist = [c_dist, {d}];    %#ok<AGROW>
        end
    end

    tab_phase = [array2table(all_time, "VariableNames", ["t1","t2"]), tab];
end


function s_phase = phase_data(tab_phase, c_dist, net)
% What each phase applies (see compile)
    c_comp = cellfun(@(b) b.a_Component, net.a_Bus, 'UniformOutput', false);
    c_comp = vertcat(cell(0,1), c_comp{:});
    n_phase = height(tab_phase);
    c_s = cell(n_phase, 1);
    sv_name = string(tab_phase.Properties.VariableNames(3:end));
    for tp = 1:n_phase
        lv_act = tab_phase{tp,3:end};
        c_act  = c_dist(lv_act);
        s = struct();
        s.t1       = tab_phase{tp,"t1"};
        s.t2       = tab_phase{tp,"t2"};
        s.sv_event = sv_name(lv_act).';
        c = cellfun(@(d) d.FaultBus, c_act, 'UniformOutput', false);
        s.sv_fault = vertcat(strings(0,1), c{:});
        c = cellfun(@(d) d.TripUnit, c_act, 'UniformOutput', false);
        s.sv_trip  = vertcat(strings(0,1), c{:});
        c = cellfun(@(d) d.OpenBranch, c_act, 'UniformOutput', false);
        s.sv_open  = unique(vertcat(strings(0,1), c{:}));
        [s.c_Xoffset, s.c_Uoffset] = phase_offsets(c_act(:), c_comp, [s.t1, s.t2], tp);
        c_s{tp} = s;
    end
    s_phase = vertcat(c_s{:});
end


function [c_Xoffset, c_Uoffset] = phase_offsets(odeEvents, c_comp, TimePhase, Iteration)
% State offsets and input functions of each component in one phase.
% Offsets and inputs are matched by name and summed over the disturbances, in their order.
    c_Xoffset = cell(size(c_comp));
    c_Uoffset = cell(size(c_comp));

    osU = cellfun(@(c) c.OffsetUnit,  odeEvents);
    % An offset is applied only once, in the phase where its disturbance starts.
    lv_osStart = cellfun(@(c) c.TimeSpan(1) == TimePhase(1), odeEvents) | Iteration == 1;
    osU(~lv_osStart) = "";
    osX = cellfun(@(c) c.OffsetState, odeEvents, 'UniformOutput', false);
    osV = cellfun(@(c) c.OffsetValue, odeEvents, 'UniformOutput', false);

    inU = cellfun(@(c) c.InputUnit,  odeEvents);
    inN = cellfun(@(c) c.InputName,  odeEvents, 'UniformOutput', false);
    inV = cellfun(@(c) c.InputValue, odeEvents, 'UniformOutput', false);

    for j = 1:numel(c_comp)
        comp  = c_comp{j};
        c_tag = comp.str_tag;
        l_osU = ismember(osU, c_tag);
        l_inU = ismember(inU, c_tag);

        rv_Xoffset = zeros(size(comp.sv_x(:)));
        for k = find(l_osU(:))'
            [lv_X, loc] = ismember(osX{k}, comp.sv_x);
            osVk = osV{k} .* ones(size(osX{k}));
            rv_Xoffset(loc(lv_X)) = rv_Xoffset(loc(lv_X)) + osVk(lv_X);
        end
        c_Xoffset{j} = rv_Xoffset;

        ini = repmat({@(t) 0}, size(comp.sv_u(:)));
        lv_set = false(size(ini));
        for k = find(l_inU(:))'
            [lv_N, loc] = ismember(inN{k}, comp.sv_u);

            exV = inV{k};
            if ~iscell(exV)
                if isa(exV, 'function_handle')
                    exV = {exV};
                else
                    exV = num2cell(exV);
                end
            end
            if isscalar(exV)
                exV = repmat(exV, size(inN{k}));
            end

            for ni = find(lv_N(:))'
                f1 = event2fhandle(exV{ni}, odeEvents{k}, TimePhase);
                if lv_set(loc(ni))
                    f0 = ini{loc(ni)};
                    ini{loc(ni)} = @(t) f0(t) + f1(t);
                else
                    ini{loc(ni)} = f1;
                    lv_set(loc(ni)) = true;
                end
            end
        end
        % Without an input, empty: the right-hand side skips it
        if any(lv_set)
            c_Uoffset{j} = @(t) cellfun(@(f) f(t), ini);
        else
            c_Uoffset{j} = [];
        end
    end
end

function exV = event2fhandle(exV, oev, TimePhase)
% A value as a function of the time since the start of the phase
    if isa(exV, 'double')
        exV = @(t) exV;
    elseif isa(exV, 'function_handle')
        if nargin(exV) ~= 1
            error(msg("GUILDA:Scenario:InvalidNargin", char(oev.Tag), char(oev.Scenario)))
        end
        % t of each phase starts at 0; the function takes the time since the disturbance start.
        ts = TimePhase(1) - oev.TimeSpan(1);
        exV = @(t) exV(t+ts);
    else
        error(msg("GUILDA:Scenario:InvalidInputType", char(oev.Tag), char(oev.Scenario), class(exV)))
    end
end
