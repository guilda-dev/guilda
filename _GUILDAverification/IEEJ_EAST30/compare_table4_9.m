function [tab, r_agree] = compare_table4_9(opt)
% Compare the transient stability verdicts of IEEJ report table 4.9 with GUILDA on IEEJ_EAST30.
% Table 4.9 lists the Y-method results of the EAST 30-machine model for a three-phase
% ground fault on one or two circuits of a line, cleared after 70 ms by opening the
% faulted circuits (3LG-O). `table4_9_scenarios.csv` in this folder holds its 55 cases as
% scenarios (Scenario.export_csv format, one scenario per case: a fault and the opening of
% the faulted circuits until the end, Time [0, 21] s), and `table4_9_report.csv` the
% report's result of each scenario. See README.md for the sequence, the criterion and the
% modelling differences.
%
% For each section the network is built (network.IEEJ_EAST30 with Section and Governor),
% the scenarios are imported into it with Scenario.import_csv(..., Network=net), and each
% selected scenario is simulated and judged by Scenario.out_of_step with the reference
% SG1B3010 (G18, the slack) and the threshold 360 degrees. A simulation that stops early
% without an out-of-step ("incomplete") is run again with the relative tolerance
% RetryTolerance; if it is incomplete again the case does not agree.
%
% ```matlab
% run("_GUILDAverification/IEEJ_EAST30/compare_table4_9.m")   % governors on, all cases
% cd _GUILDAverification/IEEJ_EAST30
% [tab, r_agree] = compare_table4_9(Governor=false);
% tab = compare_table4_9(Sections="night", Circuits=2);
% ```
%
% See also network.IEEJ_EAST30, Scenario, Scenario.out_of_step, PowerNetwork.simulate
    arguments
        opt.Governor  (1,1) logical = true % true for the default network with governors; false for exciters only.
        opt.Sections  (1,:) string {mustBeMember(opt.Sections, ["peak","night"])} = ["peak","night"] % Sections to run.
        opt.Circuits  (1,:) double {mustBeMember(opt.Circuits, [1,2])} = [1,2] % Numbers of faulted circuits to run.
        opt.Cases     (1,:) string = string.empty % Scenario tags to run (empty for all).
        opt.TimeLimit (1,1) double {mustBePositive} = 300 % [s] Wall-clock limit of each simulation.
        opt.RetryTolerance (1,1) double {mustBePositive} = 1e-5 % Relative tolerance of the rerun of an incomplete case.
        opt.Plot      (1,1) logical = false % true to plot the angles from G18 of each case.
        opt.Verbose   (1,1) logical = true % true to print each case and the agreement.
    end
    arguments (Output)
        tab table % One row per case: the report's and GUILDA's verdicts and their agreement.
        r_agree (1,2) double % [number of agreeing cases, number of cases].
    end
    str_dir = fileparts(mfilename("fullpath"));
    if isempty(which("GUILDA"))   % GUILDA root (with @GUILDA) on the path, for runs after cd here
        addpath(fileparts(fileparts(str_dir)));
    end
    str_csv = fullfile(str_dir, "table4_9_scenarios.csv");
    o = detectImportOptions(fullfile(str_dir, "table4_9_report.csv"), "Delimiter", ",", "TextType", "string");
    o = setvartype(o, setdiff(o.VariableNames, ["Card","Circuits"]), "string");
    tab_rep = readtable(fullfile(str_dir, "table4_9_report.csv"), o);
    tab_rep.ReportGenerator = fillmissing(tab_rep.ReportGenerator, "constant", "");

    l_run = ismember(tab_rep.Section, opt.Sections) & ismember(tab_rep.Circuits, opt.Circuits);
    if ~isempty(opt.Cases)
        l_run = l_run & ismember(tab_rep.Scenario, opt.Cases);
    end
    tab = tab_rep(l_run, :);
    n = height(tab);
    tab.Verdict   = strings(n,1);
    tab.Time      = nan(n,1);
    tab.Generator = strings(n,1);
    tab.Tolerance = nan(n,1);
    tab.Agree     = false(n,1);

    str_ref = "SG1B3010";   % G18, the slack bus B3010
    str_sec = "";
    for k = 1:n
        if tab.Section(k) ~= str_sec
            str_sec = tab.Section(k);
            net = network.IEEJ_EAST30(Section=str_sec, Governor=opt.Governor);
            c_sc = Scenario.import_csv(str_csv, Network=net);
            sv_tag = cellfun(@(s) s.str_tag, c_sc);
        end
        sc = c_sc{sv_tag == tab.Scenario(k)};
        sc.Judge = @(r) Scenario.out_of_step(r, Reference=str_ref, Threshold=360);
        tab.Tolerance(k) = net.solver_ODE.RelativeTolerance;
        result = run_case(net, sc, opt);
        v = sc.judge(result);
        if v.Verdict == "incomplete" && opt.RetryTolerance < tab.Tolerance(k)
            tab.Tolerance(k) = opt.RetryTolerance;
            result = run_case(net, sc, opt, "Tolerance", opt.RetryTolerance);
            v = sc.judge(result);
        end
        [sv_gen, rv_t, rm_deg] = generators(result, str_ref);
        tab.Verdict(k) = v.Verdict;
        tab.Time(k) = v.Time;
        if v.Verdict == "out-of-step"
            i_step = find(rv_t == v.Time, 1);
            tab.Generator(k) = join(sv_gen(abs(rm_deg(i_step,:)) > v.Threshold), " ");
        elseif v.Verdict == "incomplete"
            tab.Time(k) = rv_t(end);
        end
        tab.Agree(k) = tab.Verdict(k) == tab.ReportVerdict(k);
        if opt.Verbose
            fprintf("%-16s report %-12s %-9s  GUILDA %-12s t=%5.2f %-12s tol=%-6g %s\n", tab.Scenario(k), ...
                    tab.Report(k), tab.ReportGenerator(k), tab.Verdict(k), tab.Time(k), tab.Generator(k), ...
                    tab.Tolerance(k), string(agree_mark(tab.Agree(k))));
        end
        if opt.Plot
            figure("Name", tab.Scenario(k));
            plot(rv_t, rm_deg);  grid on
            xlabel("t [s]");  ylabel("\delta - \delta_{G18} [deg]");
            title(tab.Scenario(k) + ": report " + tab.Report(k) + ", GUILDA " + tab.Verdict(k), "Interpreter", "none");
            legend(sv_gen, "Location", "eastoutside");
        end
    end
    r_agree = [nnz(tab.Agree), n];
    if opt.Verbose
        fprintf("Agreement (Governor=%d): %d / %d\n", opt.Governor, r_agree);
    end
end


function result = run_case(net, sc, opt, varargin)
% Simulate one scenario quietly: the solver warnings after an out-of-step are expected
    s_warn = warning("off", "all");
    c_clean = onCleanup(@() warning(s_warn));
    result = net.simulate(sc, "Progress", "none", "TimeLimit", opt.TimeLimit, varargin{:});
end


function [sv_gen, rv_t, rm_deg] = generators(result, str_ref)
% Rotor angles [deg] relative to the reference, with the report's generator names
% (generators in bus order: G1 to G8 are nodes 2001 to 2008, G9 to G30 nodes 3001 to 3022)
    tab_var = result.tab_variable;
    l_delta = tab_var.Kind == "x" & tab_var.Name == "delta";
    sv_owner = tab_var.Owner(l_delta);
    rv_t = result.rv_t(:);
    rm_delta = result.rm_variable(:, l_delta);
    rm_deg = (rm_delta - rm_delta(:, sv_owner == str_ref))*180/pi;
    sv_gen = "G" + string(1:numel(sv_owner));
end


function c = agree_mark(l)
% Text of the agreement column
    if l, c = "agree"; else, c = "DIFFERENT"; end
end
