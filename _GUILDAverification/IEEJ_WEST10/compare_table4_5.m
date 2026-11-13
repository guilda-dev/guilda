function [tab, summary] = compare_table4_5(opt)
% Compare network.IEEJ_WEST10 with the transient stability results of table 4.5 of the IEEJ report.
% The scenarios of table4_5_scenarios.csv (one per case of the report) are simulated
% from the equilibrium of their section, judged with judge_table4_5 (below), and compared
% with the verdicts of the report in table4_5_report.csv. See README.md in this folder for
% the source, the cases, the criterion and the modelling differences.
%
% `tab` has a row per case: Section, Case, Report (verdict of the report), GUILDA,
% Agree, TimeOutOfStep and ReportTimeOutOfStep [s], Period and ReportPeriod [s],
% MaxAngle [deg] (largest `|delta_i - delta_G10|`), Flag (of simulate). `summary` has the
% agreement per section. Both are printed when Display is true.
%
% Use (this folder is not on the MATLAB path; run GUILDA first). When the current folder
% is not the GUILDA root, the root is added to the path for the run and removed after it:
%
% ```matlab
% run(fullfile(GUILDA.pwd, "_GUILDAverification", "IEEJ_WEST10", "compare_table4_5.m"))
% cd(fullfile(GUILDA.pwd, "_GUILDAverification", "IEEJ_WEST10"))
% tab = compare_table4_5(Governor=false, Sections="peak", Cases=["A","L"], Plot=true);
% ```
%
% See also network.IEEJ_WEST10, Scenario, PowerNetwork.add_scenario, PowerNetwork.simulate
    arguments (Input)
        opt.Governor (1,1) logical = true % Network option Governor (true: the report's LPT = 1 governors).
        opt.Sections (1,:) string {mustBeMember(opt.Sections,["peak","night"])} = ["peak","night"] % Sections to run.
        opt.Cases (1,:) string = string.empty % Case ids to run (e.g. ["A","G8"]); empty for all.
        opt.Plot (1,1) logical = false % true to plot the angles from G10 of each case.
        opt.Display (1,1) logical = true % true to print the table and the agreement.
        opt.SimulateOptions (1,:) cell = {} % Name-Value options of simulate, e.g. {"Tolerance", 1e-6}.
    end
    arguments (Output)
        tab % Table of the cases with the verdicts of the report and GUILDA.
        summary % Agreement per section (Section, Cases, Agree).
    end

    s_dir = fileparts(mfilename("fullpath"));
    % GUILDA (the repository root) is found through the current folder only; add the root
    % for this run when it is neither the current folder nor on the path (after cd, or
    % inside run). which("GUILDA") is not empty there once the class has been loaded.
    s_root = fileparts(fileparts(s_dir));
    if ~any(strcmp(s_root, [string(pwd), split(string(path), pathsep).']))
        addpath(s_root);
        obj_cleanup = onCleanup(@() rmpath(s_root));
    end
    tab_rep = readtable(fullfile(s_dir, "table4_5_report.csv"), "TextType", "string", "Delimiter", ",");
    tab_rep = tab_rep(ismember(tab_rep.Section, opt.Sections), :);
    if ~isempty(opt.Cases)
        tab_rep = tab_rep(ismember(tab_rep.Case, opt.Cases), :);
    end

    c_sim = [{"Progress", "none"}, opt.SimulateOptions];
    n = height(tab_rep);
    sv_verdict = strings(n,1);  rv_toos = nan(n,1);  rv_per = nan(n,1);
    rv_max = nan(n,1);  rv_flag = nan(n,1);
    for s_sec = unique(tab_rep.Section, "stable").'
        net = network.IEEJ_WEST10(Section=s_sec, Governor=opt.Governor);
        c_sc = add_csv_scenarios(fullfile(s_dir, "table4_5_scenarios.csv"), net);
        sv_tag = cellfun(@string, c_sc);
        for k = find(tab_rep.Section == s_sec).'
            sc = c_sc{sv_tag == tab_rep.Scenario(k)};
            % The run stops early (flag) rather than with a warning: an out-of-step case
            % often stops the solver once the angles have passed 360 degrees
            sct_warn = warning("off", "all");
            o_restore = onCleanup(@() warning(sct_warn));
            [result, rv_flag(k)] = net.simulate(sc.s_tag, c_sim{:});
            clear o_restore

            v = judge_table4_5(result);
            sv_verdict(k) = v.Verdict;  rv_toos(k) = v.Time;
            rv_per(k) = v.Period;       rv_max(k) = v.MaxAngle;
            if opt.Plot
                figure("Name", sc.s_tag);
                plot(v.t, v.Angle);
                xlabel("time [s]");  ylabel("angle from G10 [deg]");
                title(sprintf("%s: %s (report: %s)", sc.s_tag, v.Verdict, tab_rep.Verdict(k)));
                legend("G" + (1:size(v.Angle,2)), "Location", "eastoutside");
            end
        end
    end

    tab = table(tab_rep.Section, tab_rep.Case, tab_rep.Verdict, sv_verdict, tab_rep.Verdict == sv_verdict, ...
                rv_toos, tab_rep.TimeOutOfStep, rv_per, tab_rep.Period, rv_max, rv_flag, ...
                'VariableNames', ["Section","Case","Report","GUILDA","Agree","TimeOutOfStep", ...
                                  "ReportTimeOutOfStep","Period","ReportPeriod","MaxAngle","Flag"]);
    sv_sec = unique(tab.Section, "stable");
    summary = table(sv_sec, arrayfun(@(s) nnz(tab.Section == s), sv_sec), ...
                    arrayfun(@(s) nnz(tab.Section == s & tab.Agree), sv_sec), ...
                    'VariableNames', ["Section","Cases","Agree"]);
    if opt.Display
        disp(tab);
        fprintf("Agreement with table 4.5 (Governor=%d): %d of %d", opt.Governor, nnz(tab.Agree), height(tab));
        fprintf(" (%s)\n", strjoin(summary.Section + " " + summary.Agree + "/" + summary.Cases, ", "));
    end
end


function v = judge_table4_5(result)
% Judge of the comparison: out-of-step, stopped, growing or stable (see README.md)
%
% - "out-of-step": result.judge_out_of_step with the slack generator G10 (B030) as the
%   reference and 360 degrees.
% - "stopped": the simulation stopped early (flag ~= 1) before an angle passed 360 degrees
%   (the "incomplete" of judge_out_of_step).
% - otherwise "growing" when the peak-to-peak spread of the angles from G10 over the last
%   5 s is larger than over 0.2 s to 5 s, and "stable" when it is not.
%
% Period: the period of the swing of G1 from G10, from its upward crossings of its mean
% after 2 s (mean of up to three periods; NaN when out-of-step, stopped or with fewer than
% two crossings).
    arguments (Input)
        result  % Simulation result (ResultODE).
    end
    arguments (Output)
        v  % Verdict of judge_out_of_step with the fields t, Angle and Period added.
    end
    v = result.judge_out_of_step();

    % Angles of the generators (G1 to G10 in the order of their buses) from G10 [deg]
    tab_var = result.tab_variable;
    sv_cp = vertcat(strings(0,1), result.c_component{:});
    iv_d = find(tab_var.Kind == "x" & tab_var.Name == "delta" & ismember(tab_var.Owner, sv_cp));
    [~, iv_ord] = sort(tab_var.Bus(iv_d));
    iv_d = iv_d(iv_ord);
    m_delta = result.rm_variable(:, iv_d);
    i_ref = find(tab_var.Bus(iv_d) == "B030");
    m_angle = (m_delta - m_delta(:,i_ref))*180/pi;
    t = result.rv_t(:);
    v.t = t;
    v.Angle = m_angle;
    v.Period = NaN;

    switch v.Verdict
        case "out-of-step"
            return
        case "incomplete"
            v.Verdict = "stopped";
            return
    end
    rv_spread = max(m_angle, [], 2, "omitnan") - min(m_angle, [], 2, "omitnan");
    r_early = peak_to_peak(rv_spread(t > 0.2 & t < 5));
    r_late  = peak_to_peak(rv_spread(t > t(end) - 5));
    if r_late > r_early
        v.Verdict = "growing";
    end
    rv_w = m_angle(t > 2, 1);  rv_tw = t(t > 2);
    i_up = find(rv_w(1:end-1) < mean(rv_w) & rv_w(2:end) >= mean(rv_w));
    if numel(i_up) > 1
        v.Period = mean(diff(rv_tw(i_up(1:min(end,4)))));
    end
end


function r = peak_to_peak(rv)
% Peak-to-peak value of a vector
    arguments (Input)
        rv  % Vector.
    end
    arguments (Output)
        r  % Peak-to-peak value of rv.
    end
    r = max(rv) - min(rv);
end

function c_sc = add_csv_scenarios(s_file, net)
% Add the scenarios of a CSV file (one row per disturbance) to net and return them.
%
% The rows with the same Scenario form one scenario, in the order of their first rows:
% Description and Time [ScenarioTimeStart, ScenarioTimeEnd] from its first row, and one
% disturbance per row with Tag, TimeSpan [TimeStart, TimeEnd] and the tags in FaultBus,
% TripUnit and OpenBranch (several separated by ";"). The other columns of the file are
% empty and not read.
    arguments (Input)
        s_file (1,1) string   % CSV file.
        net PowerNetwork      % Network to add the scenarios to.
    end
    arguments (Output)
        c_sc (:,1) cell       % The added scenarios, in the order of the file.
    end
    o = detectImportOptions(s_file, "Delimiter", ",", "TextType", "string");
    o = setvartype(o, o.VariableNames, "string");
    tab = readtable(s_file, o);
    for s_col = string(tab.Properties.VariableNames)
        tab.(s_col)(ismissing(tab.(s_col))) = "";
    end
    sv_sc = unique(tab.Scenario, "stable");
    c_sc  = cell(numel(sv_sc), 1);
    for i = 1:numel(sv_sc)
        tab_i = tab(tab.Scenario == sv_sc(i), :);
        sc = net.add_scenario(sv_sc(i), Description=tab_i.Description(1), ...
                              Time=double([tab_i.ScenarioTimeStart(1), tab_i.ScenarioTimeEnd(1)]));
        for r = 1:height(tab_i)
            c_nv = cell(1, 0);
            for s_col = ["FaultBus", "TripUnit", "OpenBranch"]
                if tab_i.(s_col)(r) ~= ""
                    c_nv = [c_nv, {s_col, strip(split(tab_i.(s_col)(r), ";"))}]; %#ok<AGROW>
                end
            end
            sc.add_disturbance(tab_i.Tag(r), "TimeSpan", double([tab_i.TimeStart(r), tab_i.TimeEnd(r)]), c_nv{:});
        end
        c_sc{i} = sc;
    end
end
