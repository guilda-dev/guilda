function tab = compare_table4_3(opt)
% Compare network.IEEJ_EAST10 with table 4.3 of the IEEJ report (44 fault cases).
%
% Each report case is one scenario of `table4_3_scenarios.csv` (in this folder): a
% three-phase fault at the From end of a line card for 70 ms (0 to 0.07 s), then the
% opening of 1 or 2 circuits of that card until the end (20 s). The verdict of the report
% for each scenario is in `table4_3_report.csv`. The function builds the network of each
% section, imports the scenarios into it (Scenario.import_csv with Network), simulates
% the scenarios of that section, judges each result with ResultODE.judge_out_of_step (reference:
% the slack generator, G3 at peak and G6 at night; threshold 360 degrees) and compares
% the verdict with the report. The report's "sustained oscillation" (peak, card 36)
% counts as stable. See README.md in this folder.
%
% The solver tolerance is `Tolerance` (1e-6, relative and absolute) instead of the
% default 1e-4: with 1e-4, ode15s stops early in some large-swing cases. It is stored in
% the Options of each scenario, as Options are not saved in the CSV.
%
% Use (this folder is not on the MATLAB path; run GUILDA first). When the current folder
% is not the GUILDA root, the root is added to the path for the run and removed after it:
%
% ```matlab
% run(fullfile(GUILDA.pwd, "_GUILDAverification", "IEEJ_EAST10", "compare_table4_3.m"))
% cd(fullfile(GUILDA.pwd, "_GUILDAverification", "IEEJ_EAST10"))
% tab = compare_table4_3(Governor=false, Sections="peak");
% ```
%
% See also network.IEEJ_EAST10, Scenario, ResultODE.judge_out_of_step
    arguments (Input)
        opt.Governor (1,1) logical = true % true for the governors of the network (its default).
        opt.Sections (1,:) string {mustBeMember(opt.Sections,["peak","night"])} = ["peak","night"] % Sections to run.
        opt.Cases (1,:) double = [] % Row numbers of table4_3_report.csv to run; [] for all the rows of Sections.
        opt.Tolerance (1,1) double {mustBePositive} = 1e-6 % Relative and absolute tolerance of the solver.
        opt.Plot (1,1) logical = false % true to plot the relative rotor angles of each case.
        opt.Display (1,1) logical = true % true to print each case and the agreement.
    end
    arguments (Output)
        tab table % The cases with the report and GUILDA verdicts and their agreement.
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
    s_scenario = fullfile(s_dir, "table4_3_scenarios.csv");
    tab_report = readtable(fullfile(s_dir, "table4_3_report.csv"), TextType="string", Delimiter=",");

    lv_run = ismember(tab_report.Section, opt.Sections);
    if ~isempty(opt.Cases)
        lv_run = lv_run & ismember((1:height(tab_report)).', opt.Cases);
    end
    tab = tab_report(lv_run, ["Scenario","Section","Card","Circuits","Report","ReportVerdict"]);
    n_case = height(tab);
    tab.Verdict       = strings(n_case,1);
    tab.Agree         = false(n_case,1);
    tab.OutOfStep     = strings(n_case,1);  % out-of-step generators
    tab.TimeOutOfStep = nan(n_case,1);      % [s] first time beyond the threshold
    tab.MaxAngle      = zeros(n_case,1);    % [deg] largest relative angle
    tab.Flag          = zeros(n_case,1);    % flag of net.simulate

    sct_tolerance = struct("Tolerance", opt.Tolerance, "AbsoluteTolerance", opt.Tolerance);
    for s = intersect(opt.Sections, tab.Section.', "stable")
        net  = network.IEEJ_EAST10(Section=s, Governor=opt.Governor);
        c_sc = Scenario.import_csv(s_scenario, Network=net);
        sv_tag = cellfun(@(sc) sc.s_tag, c_sc);
        for k = find(tab.Section == s).'
            sc = c_sc{sv_tag == tab.Scenario(k)};
            sc.Options = sct_tolerance;
            [result, flag] = net.simulate(sc, Progress="none");
            verdict = result.judge_out_of_step();

            tab.Verdict(k)       = verdict.Verdict;
            tab.Agree(k)         = verdict.Verdict == tab.ReportVerdict(k);
            tab.OutOfStep(k)     = strjoin(verdict.Units.', " ");
            tab.TimeOutOfStep(k) = verdict.Time;
            tab.MaxAngle(k)      = verdict.MaxAngle;
            tab.Flag(k)          = flag;

            if opt.Display
                fprintf("%-5s card %3d, %d cct: report %-11s GUILDA %-11s %s\n", s, tab.Card(k), ...
                        tab.Circuits(k), tab.ReportVerdict(k), tab.Verdict(k), tab.OutOfStep(k));
            end
            if opt.Plot
                plot_angles(result, verdict.Reference, sc.Description + ": " + verdict.Verdict);
            end
        end
    end

    if opt.Display
        for s = intersect(opt.Sections, tab.Section.', "stable")
            lv = tab.Section == s;
            fprintf("%s: %d of %d agree\n", s, nnz(tab.Agree(lv)), nnz(lv));
        end
        fprintf("total: %d of %d agree (Governor=%d)\n", nnz(tab.Agree), n_case, opt.Governor);
    end
end


function plot_angles(result, s_ref, s_title)
% Rotor angles of the generators relative to the reference generator
    arguments (Input)
        result     % Simulation result (ResultODE).
        s_ref      % Tag of the reference generator.
        s_title    % Title of the figure.
    end
    tab_var = result.tab_variable;
    lv_d    = tab_var.Kind == "x" & tab_var.Name == "delta";
    sv_unit = tab_var.Owner(lv_d);
    m_delta = result.rm_variable(:, lv_d);
    m_rel   = m_delta - m_delta(:, sv_unit == s_ref);
    figure("Name", s_title);
    plot(result.rv_t, m_rel*180/pi);
    xlabel("t [s]"); ylabel("rotor angle - " + s_ref + " [deg]");
    legend(sv_unit, Location="eastoutside", Interpreter="none");
    title(s_title, Interpreter="none");
end
