function [tab, summary] = run_table4_5(opt)
% Run the cases of table 4.5 of the IEEJ report on network.IEEJ_WEST10 and compare.
% Each case of table4_5.csv (in this folder) is simulated from the equilibrium of its
% section, judged stable or not, and compared with the verdict of the report (the
% Y-method of CRIEPI, `NLT = 2` constant-current loads).
%
% Cases (as in the dynamic input data of the report):
%
% - A to L: a three-phase ground fault on one circuit of a two-circuit line, at the line
%   end on `FaultBus`, from `TimeStart` (0.1 s) for `FaultDuration` (70 ms); the faulted
%   circuit `OpenBranch` is then opened for good (both ends at once, no reclosing). The
%   fault is a fault at the bus, and each circuit of the network is its own branch, so
%   only the faulted circuit is opened.
% - G8: the generator G8 trips at 0.1 s (`TripBus`). The report opens its transformer;
%   here the generator is tripped, which leaves the rest of the network the same.
%
% Verdict (the definition of the report, and of the comparison made when the model was
% built, so the results stay comparable):
%
% - "out-of-step": the angle of a generator from G10 (`B030`), `|delta_i - delta_G10|`,
%   exceeds 360 degrees in the simulated time.
% - otherwise "growing" when the peak-to-peak spread of these angles over the last 5 s
%   is larger than over 0.2 s to 5 s, and "stable" when it is not.
% - "stopped": the simulation stopped early (flag ~= 1) before an angle passed 360
%   degrees. It counts as a disagreement.
%
% `Period` is the period of the swing of G1 from G10, from its upward crossings of its
% mean after 2 s (NaN when out-of-step or with fewer than two crossings); the report
% gives the period read from its waveforms.
%
% Differences from the report: the loads are load-impedance models (the report: constant
% current `P` with a change to constant impedance below 0.7 pu, constant-impedance `Q`
% and 3.33 %/Hz of `P`), and the armature time constant and the saturation are not
% modelled (see network.IEEJ_WEST10).
%
% `tab` has a row per case: Section, Case, Report (verdict of the report), GUILDA,
% Agree, TimeOutOfStep and ReportTimeOutOfStep [s], Period and ReportPeriod [s],
% MaxAngle [deg] (largest `|delta_i - delta_G10|`), Flag (of simulate). `summary` has the
% agreement per section. Both are printed.
%
% With the default solver settings one case per run stops the solver before its angles
% pass 360 degrees: E at peak with governors (it is out-of-step at 11.7 s with
% `Tolerance` 1e-6 and `AbsoluteTolerance` 1e-8, which then stop G at peak instead), and
% the G8 trip at night without them (at 125 degrees, also with the tighter tolerances).
% `SimulateOptions` passes other settings to simulate.
%
% <@Examples>
% MATLAB does not run files inside a class folder, also with the folder on the path or as
% the current folder. Copy the folder and run the copy:
%
% ```matlab
% str_dir = tempname;
% copyfile(fullfile(fileparts(which("network.IEEJ_WEST10")), "scenario"), str_dir);
% addpath(str_dir);
% tab = run_table4_5();                                   % governors on (default)
% tab = run_table4_5(Governor=false, Sections="peak", Cases=["A","L"], Plot=true);
% rmpath(str_dir);
% ```
%
% See also network.IEEJ_WEST10, ODEevent, PowerNetwork.simulate
    arguments
        opt.Governor (1,1) logical = true % Network option Governor (true: the report's LPT = 1 governors).
        opt.Sections (1,:) string {mustBeMember(opt.Sections,["peak","night"])} = ["peak","night"] % Sections to run.
        opt.Cases (1,:) string = string.empty % Case ids to run (e.g. ["A","G8"]); empty for all.
        opt.TimeEnd (1,1) double {mustBeGreaterThan(opt.TimeEnd,5.2)} = 20 % [s] End of the simulation (the report: 20 s).
        opt.Plot (1,1) logical = false % true to plot the angles from G10 of each case.
        opt.Display (1,1) logical = true % true to print the table and the agreement.
        opt.SimulateOptions (1,:) cell = {} % Name-Value options of simulate, e.g. {"Tolerance", 1e-6}.
    end
    arguments (Output)
        tab % Table of the cases with the verdicts of the report and GUILDA.
        summary % Agreement per section (Section, Cases, Agree).
    end

    tab_case = readtable(fullfile(fileparts(mfilename("fullpath")), "table4_5.csv"), ...
                         "TextType", "string", "Delimiter", ",");
    tab_case = tab_case(ismember(tab_case.Section, opt.Sections), :);
    if ~isempty(opt.Cases)
        tab_case = tab_case(ismember(tab_case.Case, opt.Cases), :);
    end

    c_sim = [{"Progress", "none"}, opt.SimulateOptions];
    n = height(tab_case);
    c_verdict = strings(n,1);  rv_toos = nan(n,1);  rv_per = nan(n,1);
    rv_max = nan(n,1);  rv_flag = nan(n,1);
    for str_sec = unique(tab_case.Section, "stable").'
        net = network.IEEJ_WEST10(Section=str_sec, Governor=opt.Governor);
        for k = find(tab_case.Section == str_sec).'
            [c_verdict(k), rv_toos(k), rv_per(k), rv_max(k), rv_flag(k), s_traj] = run_case(net, tab_case(k,:), opt.TimeEnd, c_sim);
            if opt.Plot
                figure("Name", str_sec + " " + tab_case.Case(k));
                plot(s_traj.t, s_traj.angle);
                xlabel("time [s]");  ylabel("angle from G10 [deg]");
                title(sprintf("%s %s: %s (report: %s)", str_sec, tab_case.Case(k), c_verdict(k), tab_case.Verdict(k)));
                legend("G" + (1:size(s_traj.angle,2)), "Location", "eastoutside");
            end
        end
    end

    tab = table(tab_case.Section, tab_case.Case, tab_case.Verdict, c_verdict, tab_case.Verdict == c_verdict, ...
                rv_toos, tab_case.TimeOutOfStep, rv_per, tab_case.Period, rv_max, rv_flag, ...
                'VariableNames', ["Section","Case","Report","GUILDA","Agree","TimeOutOfStep", ...
                                  "ReportTimeOutOfStep","Period","ReportPeriod","MaxAngle","Flag"]);
    c_sec = unique(tab.Section, "stable");
    summary = table(c_sec, arrayfun(@(s) nnz(tab.Section == s), c_sec), ...
                    arrayfun(@(s) nnz(tab.Section == s & tab.Agree), c_sec), ...
                    'VariableNames', ["Section","Cases","Agree"]);
    if opt.Display
        disp(tab);
        fprintf("Agreement with table 4.5 (Governor=%d): %d of %d", opt.Governor, nnz(tab.Agree), height(tab));
        fprintf(" (%s)\n", strjoin(summary.Section + " " + summary.Agree + "/" + summary.Cases, ", "));
    end
end


function [str_verdict, r_toos, r_per, r_max, flag, s_traj] = run_case(net, row, t_end, opt_sim)
% Simulate one case and judge it
    t0 = row.TimeStart;
    c_ev = {};
    if strlength(row.FaultBus) > 0
        t1 = t0 + row.FaultDuration;
        c_ev{end+1} = ODEevent("fault", net, "TimeSpan", [t0, t1], "FaultBus", row.FaultBus);
        c_ev{end+1} = ODEevent("open", net, "TimeSpan", [t1, t_end], "OpenBranch", split(row.OpenBranch, ";"));
    end
    if strlength(row.TripBus) > 0
        comp = net.a_Bus{string(net.a_Bus) == row.TripBus}.a_Component{1};
        c_ev{end+1} = ODEevent("trip", net, "TimeSpan", [t0, t_end], "TripUnit", comp.str_tag);
    end

    % The run stops early (flag) rather than with a warning: an out-of-step case often
    % stops the solver once the angles have passed 360 degrees
    s_warn = warning("off", "all");
    o_restore = onCleanup(@() warning(s_warn));
    [sol, flag] = net.simulate([0, t_end], c_ev{:}, opt_sim{:});

    % Angles of the generators from G10 [deg]
    r = sol.odeResults;
    t = r.t(:);
    i_gen = find(cellfun(@(b) ~isempty(b.a_Component) && startsWith(b.a_Component{1}.key, "gen"), net.a_Bus(:)));
    m_delta = zeros(numel(t), numel(i_gen));
    for j = 1:numel(i_gen)
        m_delta(:,j) = r.Bus(i_gen(j)).Component(1).X.delta;
    end
    i_ref = find(string(net.a_Bus(i_gen)) == "B030");
    m_angle = (m_delta - m_delta(:,i_ref))*180/pi;
    s_traj = struct("t", t, "angle", m_angle);

    rv_abs = max(abs(m_angle), [], 2, "omitnan");
    r_max = max(rv_abs);
    i_oos = find(rv_abs > 360, 1);
    r_toos = NaN;  r_per = NaN;
    if ~isempty(i_oos)
        str_verdict = "out-of-step";
        r_toos = t(i_oos);
    elseif flag ~= 1
        str_verdict = "stopped";
    else
        rv_spread = max(m_angle, [], 2, "omitnan") - min(m_angle, [], 2, "omitnan");
        r_early = peak_to_peak(rv_spread(t > 0.2 & t < 5));
        r_late  = peak_to_peak(rv_spread(t > t(end) - 5));
        str_verdict = "stable";
        if r_late > r_early
            str_verdict = "growing";
        end
        rv_w = m_angle(t > 2, 1);  rv_tw = t(t > 2);
        i_up = find(rv_w(1:end-1) < mean(rv_w) & rv_w(2:end) >= mean(rv_w));
        if numel(i_up) > 1
            r_per = mean(diff(rv_tw(i_up(1:min(end,4)))));
        end
    end
end


function r = peak_to_peak(rv)
% Peak-to-peak value of a vector
    r = max(rv) - min(rv);
end
