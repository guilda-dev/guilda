function [tab, c_result] = compare_table4_13(opt)
% Compare network.IEEJ_WEST30 with table 4.13 of the IEEJ report (transient stability).
% The cases are the scenarios of `table4_13_peak.csv` and `table4_13_night.csv` (next to
% this file, Scenario.export_csv format), and the report verdicts are in
% `table4_13_report.csv` (Section, Scenario, ReportStable, Report and the case data).
% Each scenario is a three-phase ground fault at 0.10 s, cleared at 0.17 s by opening the
% faulted circuits until the end (3LG-O). The network is built per section, the scenarios
% are imported into it with Scenario.import_csv, simulated with net.simulate(sc) from the
% equilibrium and judged with sc.judge (Scenario.out_of_step: Reference="slack", the
% machine G15 at bus B3150, Threshold=360 deg).
%
% A case agrees when the GUILDA verdict matches the report: "out-of-step" for a report
% case "out of step" or "divergent oscillation", "stable" for a report case "stable". A
% simulation that stops early without an out-of-step machine is "incomplete" and does not
% agree. See README.md in this folder for the reference, the modelling differences and the
% measured agreement.
%
% Use (this folder is not on the MATLAB path; run GUILDA first). When the current folder
% is not the GUILDA root, the root is added to the path for the run and removed after it:
%
% ```matlab
% run(fullfile(GUILDA.pwd, "_GUILDAverification", "IEEJ_WEST30", "compare_table4_13.m"))
% cd(fullfile(GUILDA.pwd, "_GUILDAverification", "IEEJ_WEST30"))
% tab = compare_table4_13(Governor=false, Sections="night", Cases=["A","D"], Plot=true);
% ```
%
% Name-Value options:
%
% - `Governor` — true for the governors of the report (default true).
% - `Sections` — "peak", "night" or both (default both).
% - `Cases` — scenario tags "A" to "F" to run (default all).
% - `TimeEnd` — [s] end of the simulation, at most 20 (default 20, the report's cut-off).
% - `TimeLimit` — [s] TimeLimit of net.simulate per case (default Inf).
% - `Plot` — true to plot the rotor angles relative to G15 of each case (default false).
% - `Display` — true to print a line per case and the agreement (default true).
%
% Outputs: `tab` has one row per case: Section, Scenario, FaultBus, OpenBranch, Report,
% ReportStable, Verdict ("stable", "out-of-step" or "incomplete"), Agree, MaxAngle [deg],
% TimeOutOfStep [s] (NaN if none), OutOfStep (tags of the machines out of step), Flag (of
% net.simulate) and Elapsed [s]. `c_result` holds the ResultODE of each case (only when
% requested).
    arguments (Input)
        opt.Governor  (1,1) logical = true % true for the governors of the report.
        opt.Sections  (1,:) string {mustBeMember(opt.Sections, ["peak","night"])} = ["peak","night"] % Sections to run.
        opt.Cases     (1,:) string {mustBeMember(opt.Cases, ["A","B","C","D","E","F"])} = ["A","B","C","D","E","F"] % Scenario tags to run.
        opt.TimeEnd   (1,1) double {mustBePositive, mustBeLessThanOrEqual(opt.TimeEnd, 20)} = 20 % [s] End of the simulation.
        opt.TimeLimit (1,1) double {mustBePositive} = Inf % [s] TimeLimit of net.simulate per case.
        opt.Plot      (1,1) logical = false % true to plot the rotor angles relative to G15.
        opt.Display   (1,1) logical = true % true to print the cases and the agreement.
    end
    arguments (Output)
        tab      % Table of the cases, the report verdict and the GUILDA verdict.
        c_result % ResultODE of each case (cell, rows of tab).
    end
    str_dir = fileparts(mfilename("fullpath"));
    % GUILDA (the repository root) is found through the current folder only; add the root
    % for this run when it is neither the current folder nor on the path (after cd, or
    % inside run). which("GUILDA") is not empty there once the class has been loaded.
    str_root = fileparts(fileparts(str_dir));
    if ~any(strcmp(str_root, [string(pwd), split(string(path), pathsep).']))
        addpath(str_root);
        obj_cleanup = onCleanup(@() rmpath(str_root));
    end
    tab_rep = readtable(fullfile(str_dir, "table4_13_report.csv"), TextType="string", Delimiter=",");
    tab_rep = tab_rep(ismember(tab_rep.Section, opt.Sections) & ismember(tab_rep.Scenario, opt.Cases), :);

    n_case = height(tab_rep);
    sv_verdict = strings(n_case,1);  rv_max = nan(n_case,1);  rv_toos = nan(n_case,1);
    sv_oos = strings(n_case,1);      rv_flag = nan(n_case,1); rv_time = nan(n_case,1);
    c_result = cell(n_case,1);

    for str_sec = opt.Sections
        lv_sec = find(tab_rep.Section == str_sec).';
        if isempty(lv_sec), continue, end
        net  = network.IEEJ_WEST30(Section=str_sec, Governor=opt.Governor);
        c_sc = Scenario.import_csv(fullfile(str_dir, "table4_13_" + str_sec + ".csv"), Network=net);
        sv_sc = cellfun(@(s) s.str_tag, c_sc);
        sv_br = string(net.a_Branch);

        for k = lv_sec
            row = tab_rep(k,:);
            sc  = c_sc{sv_sc == row.Scenario};
            check_case(net, sv_br, sc, row);
            sc.Time = [0, opt.TimeEnd];

            t_run = tic;
            [result, flag] = net.simulate(sc, Progress="none", TimeLimit=opt.TimeLimit);
            rv_time(k) = toc(t_run);
            rv_flag(k) = flag;

            v = sc.judge(result);
            sv_verdict(k) = v.Verdict;
            rv_max(k)     = v.MaxAngle;
            rv_toos(k)    = v.Time;
            sv_oos(k)     = strjoin(v.Units(:).', ",");
            if nargout > 1
                c_result{k} = result;
            end
            if opt.Plot
                plot_case(result, v, str_sec, row);
            end
            if opt.Display
                fprintf("%-5s %s  report %-11s GUILDA %-11s  max %7.0f deg  t360 %5.2f s  [%s]  (%.0f s)\n", ...
                        str_sec, row.Scenario, verdict_of(row.ReportStable), sv_verdict(k), rv_max(k), rv_toos(k), sv_oos(k), rv_time(k));
            end
        end
    end

    lv_agree = sv_verdict == arrayfun(@verdict_of, tab_rep.ReportStable);
    tab = [tab_rep(:, ["Section","Scenario","FaultBus","OpenBranch","Report","ReportStable"]), ...
           table(sv_verdict, lv_agree, rv_max, rv_toos, sv_oos, rv_flag, rv_time, ...
                 VariableNames=["Verdict","Agree","MaxAngle","TimeOutOfStep","OutOfStep","Flag","Elapsed"])];
    if opt.Display
        for str_sec = opt.Sections
            lv = tab.Section == str_sec;
            fprintf("%s: %d of %d agree\n", str_sec, nnz(tab.Agree(lv)), nnz(lv));
        end
        fprintf("Total (Governor=%d): %d of %d agree\n", opt.Governor, nnz(tab.Agree), height(tab));
    end
end


function str = verdict_of(l_stable)
% Verdict of Scenario.out_of_step that agrees with the report: "stable" or "out-of-step"
    arguments (Input)
        l_stable  % True when the report says the case is stable.
    end
    arguments (Output)
        str  % "stable" or "out-of-step".
    end
    if l_stable
        str = "stable";
    else
        str = "out-of-step";
    end
end


function check_case(net, sv_br, sc, row)
% Error when the scenario does not match the case data of the report CSV
    arguments (Input)
        net    % Power network.
        sv_br  % Tags of the branches of net.
        sc     % Scenario of the case.
        row    % Row of the report CSV for the case.
    end
    tab_d = sc.tab_disturbance;
    sv_fault = vertcat(strings(0,1), tab_d.FaultBus{:});
    sv_open  = vertcat(strings(0,1), tab_d.OpenBranch{:});
    if ~isequal(sv_fault, row.FaultBus) || ~isequal(sort(sv_open), sort(split(row.OpenBranch, ";")))
        error("Scenario %s of section %s does not match table4_13_report.csv.", row.Scenario, row.Section);
    end
    for str = sv_open(:).'
        br = net.a_Branch{sv_br == str};
        sv_end = [string(br.a_Bus{1}), string(br.a_Bus{2})];
        if ~isequal(sort(sv_end), sort([row.FromBus, row.ToBus]))
            error("Branch %s joins %s and not %s-%s.", str, join(sv_end, "-"), row.FromBus, row.ToBus);
        end
    end
end


function plot_case(result, v, str_sec, row)
% Rotor angles of the generators relative to the reference machine of the verdict
    arguments (Input)
        result   % Simulation result (ResultODE).
        v        % Judge of the scenario.
        str_sec  % Section ("peak" or "night").
        row      % Row of the report CSV for the case.
    end
    tab = result.tab_variable;
    lv_d = tab.Kind == "x" & tab.Name == "delta";
    m_delta = result.rm_variable(:, lv_d);
    rv_ref  = m_delta(:, tab.Owner(lv_d) == v.Reference);
    figure("Name", "IEEJ_WEST30 " + str_sec + " case " + row.Scenario);
    plot(result.rv_t, (m_delta - rv_ref)*180/pi);
    xlabel("t [s]"); ylabel("\delta - \delta_{ref} [deg]");
    title(sprintf("%s %s: %s (report: %s)", str_sec, row.Scenario, v.Verdict, row.Report));
    grid on
end
