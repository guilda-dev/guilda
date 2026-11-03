function [tab, r_agree] = run_table4_9(opt)
% Run the transient stability cases of table 4.9 of the IEEJ report on IEEJ_EAST30.
% Table 4.9 lists the Y-method results of the EAST 30-machine model for a three-phase
% ground fault on one or two circuits of a line, cleared after 70 ms by opening the
% faulted circuits (3LG-O), with the exciter LAT=1 and the load NLT=2. `table4_9.csv` in
% this folder holds its 55 cases (peak and night, one and two circuits): the line card
% of the report (`Card`, `ReportBranch` as the table names it), the fault bus, the
% opened branches, the fault time and duration, and the report's result.
%
% Each case builds the network of its section and simulates `[0, TimeEnd]` with two
% events: a fault at `FaultBus` from `FaultStart` for `FaultDuration`, and an
% `OpenBranch` of the faulted circuits from the fault clearing to `TimeEnd`, so they stay
% open. The fault bus is the `NF` node of the card. The report's rows 2104-2105 and
% 2107-2108 are run on the cards 2104 and 2107. Each line card has two circuits, which
% are two parallel branches of the network data (`EL` + 2k-1 and `EL` + 2k for the k-th
% card), so opening one circuit opens one branch and the power flow is that of the data.
%
% Criterion (that of the report's table): a case is out of step ("unstable") when the
% absolute value of the rotor angle of a generator from that of G18 (bus `B3010`, the
% slack) exceeds 360 degrees at some time, and stable otherwise. `Time` [s] is then the
% first such simulation time (the fault starts at `FaultStart`) and `Generator` the
% generators beyond 360 degrees at that time, numbered as in the report (G1 to G8 are
% nodes 2001 to 2008, G9 to G30 nodes 3001 to 3022). A simulation that stops before
% `TimeEnd` without crossing 360 degrees is run again with the relative tolerance
% `RetryTolerance` (the network's default is 1e-4; `Tolerance` of the result gives the
% one used), and if it stops again the case is "failed" and does not agree. The report
% separates first-swing ("1-swing") and multi-swing ("N-swing") out-of-step; the
% agreement compares only stable against unstable.
%
% Differences from the report's model: the loads are load-impedance models (`P` varies
% with the square of the voltage, not linearly above 0.7 pu, and without frequency
% characteristics), and generator saturation is not represented (see network.IEEJ_EAST30).
%
% MATLAB does not run files in a subfolder of a class folder (`@IEEJ_EAST30`), even
% with `addpath` or `cd`, so copy the function to a folder on the path first. It reads
% `table4_9.csv` from the class folder wherever it is:
%
% ```matlab
% str_dir = fullfile(fileparts(which("network.IEEJ_EAST30")), "scenario");
% copyfile(fullfile(str_dir, "run_table4_9.m"), tempdir);  addpath(tempdir)
% [tab, r_agree] = run_table4_9();                   % governors on (the default network)
% tab = run_table4_9(Governor=false, Sections="night");
% ```
%
% See also network.IEEJ_EAST30, ODEevent, PowerNetwork.simulate
    arguments
        opt.Governor  (1,1) logical = true % true for the default network with governors; false for exciters only.
        opt.Sections  (1,:) string {mustBeMember(opt.Sections, ["peak","night"])} = ["peak","night"] % Sections to run.
        opt.Circuits  (1,:) double {mustBeMember(opt.Circuits, [1,2])} = [1,2] % Numbers of faulted circuits to run.
        opt.Cases     (1,:) string = string.empty % Case names of table4_9.csv to run (empty for all).
        opt.TimeEnd   (1,1) double {mustBePositive} = 21 % [s] End time of each simulation.
        opt.TimeLimit (1,1) double {mustBePositive} = 300 % [s] Wall-clock limit of each simulation.
        opt.RetryTolerance (1,1) double {mustBePositive} = 1e-5 % Relative tolerance of the rerun of a case whose solver stops early.
        opt.Plot      (1,1) logical = false % true to plot the angles from G18 of each case.
        opt.Verbose   (1,1) logical = true % true to print each case and the agreement.
    end
    arguments (Output)
        tab table % One row per case: the report's and GUILDA's verdicts and their agreement.
        r_agree (1,2) double % [number of agreeing cases, number of cases].
    end
    str_dir = fullfile(fileparts(which("network.IEEJ_EAST30")), "scenario");
    tab_case = readtable(fullfile(str_dir, "table4_9.csv"), "TextType", "string", "Delimiter", ",");
    l_run = ismember(tab_case.Section, opt.Sections) & ismember(tab_case.Circuits, opt.Circuits);
    if ~isempty(opt.Cases)
        l_run = l_run & ismember(tab_case.Case, opt.Cases);
    end
    tab_case.ReportGenerator = fillmissing(tab_case.ReportGenerator, "constant", "");
    iv_run = find(l_run);
    tab = tab_case(l_run, ["Section","Case","ReportBranch","Circuits","FaultBus","OpenBranch","Report","ReportGenerator","ReportVerdict"]);
    n = height(tab);
    tab.Verdict   = strings(n,1);
    tab.Time      = nan(n,1);
    tab.Generator = strings(n,1);
    tab.Tolerance = nan(n,1);
    tab.Agree     = false(n,1);

    str_sec = "";
    for k = 1:n
        if tab.Section(k) ~= str_sec
            str_sec = tab.Section(k);
            net = network.IEEJ_EAST30(Section=str_sec, Governor=opt.Governor);
        end
        row = tab_case(iv_run(k), :);
        r_clear = row.FaultStart + row.FaultDuration;
        ev = {ODEevent("fault", net, "TimeSpan", [row.FaultStart, r_clear], "FaultBus", row.FaultBus), ...
              ODEevent("open",  net, "TimeSpan", [r_clear, opt.TimeEnd], "OpenBranch", split(row.OpenBranch))};
        tab.Tolerance(k) = net.solver_ODE.RelativeTolerance;
        [sol, flag] = run_case(net, opt, ev);
        [tab.Verdict(k), tab.Time(k), tab.Generator(k), rv_t, rm_deg, sv_gen] = judge(sol, flag);
        if tab.Verdict(k) == "failed" && opt.RetryTolerance < tab.Tolerance(k)
            tab.Tolerance(k) = opt.RetryTolerance;
            [sol, flag] = run_case(net, opt, ev, "Tolerance", opt.RetryTolerance);
            [tab.Verdict(k), tab.Time(k), tab.Generator(k), rv_t, rm_deg, sv_gen] = judge(sol, flag);
        end
        tab.Agree(k) = tab.Verdict(k) == tab.ReportVerdict(k);
        if opt.Verbose
            fprintf("%-18s report %-12s %-9s  GUILDA %-8s t=%5.2f %-12s tol=%-6g %s\n", tab.Case(k), tab.Report(k), ...
                    tab.ReportGenerator(k), tab.Verdict(k), tab.Time(k), tab.Generator(k), tab.Tolerance(k), ...
                    string(agree_mark(tab.Agree(k))));
        end
        if opt.Plot
            figure("Name", tab.Case(k));
            plot(rv_t, rm_deg);  grid on
            xlabel("t [s]");  ylabel("\delta - \delta_{G18} [deg]");
            title(tab.Case(k) + ": report " + tab.Report(k) + ", GUILDA " + tab.Verdict(k), "Interpreter", "none");
            legend(sv_gen, "Location", "eastoutside");
        end
    end
    r_agree = [nnz(tab.Agree), n];
    if opt.Verbose
        fprintf("Agreement (Governor=%d): %d / %d\n", opt.Governor, r_agree);
    end
end


function [sol, flag] = run_case(net, opt, ev, varargin)
% Simulate one case quietly: the solver warnings after an out-of-step are expected
    s_warn = warning("off", "all");
    c_clean = onCleanup(@() warning(s_warn));
    [sol, flag] = net.simulate([0, opt.TimeEnd], ev{:}, "Progress", "none", "TimeLimit", opt.TimeLimit, varargin{:});
end


function [str_verdict, r_time, str_gen, rv_t, rm_deg, sv_gen] = judge(sol, flag)
% Verdict of one case from the rotor angles relative to G18 (bus B3010)
    tab_var = sol.tab_variable;
    l_delta = tab_var.Kind == "x" & tab_var.Name == "delta";
    sv_owner = tab_var.Owner(l_delta);
    rv_t = sol.rv_t(:);
    rm_delta = sol.rm_variable(:, tab_var.Index(l_delta));
    rm_deg = (rm_delta - rm_delta(:, sv_owner == "SG1B3010"))*180/pi;
    sv_gen = "G" + string(1:numel(sv_owner));   % generators in bus order: G1 = B2001, ..., G30 = B3022
    i_step = find(any(abs(rm_deg) > 360, 2), 1);
    if ~isempty(i_step)
        str_verdict = "unstable";
        r_time = rv_t(i_step);
        str_gen = join(sv_gen(abs(rm_deg(i_step,:)) > 360), " ");
    elseif flag == 1
        str_verdict = "stable";
        r_time = NaN;
        str_gen = "";
    else
        str_verdict = "failed";
        r_time = rv_t(end);
        str_gen = "";
    end
end


function c = agree_mark(l)
% Text of the agreement column
    if l, c = "agree"; else, c = "DIFFERENT"; end
end
