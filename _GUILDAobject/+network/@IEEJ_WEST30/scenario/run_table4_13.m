function [tab, c_sol] = run_table4_13(opt)
% Run the fault cases of table 4.13 of the report on network.IEEJ_WEST30.
% Each case of `table4_13.csv` (next to this file) is a three-phase ground fault at a
% bus at the end of a line, cleared by opening the faulted circuits for good (3LG-O):
% the fault lasts `FaultDuration` from `FaultStart`, and the branch `OpenBranch` opens
% when the fault is cleared and stays open to the end. The network is built per section
% with network.IEEJ_WEST30 and the options here, then simulated with net.simulate from
% its equilibrium, with an ODEevent "fault" and an ODEevent "open".
%
% Cases (sequence of the report: fault at 0.10 s, cleared by opening at 0.17 s):
%
% - A to D: 1-circuit 3LG-O. The line of the fault has two cards of one circuit in the
%   data, so each card is one branch here and `OpenBranch` opens that circuit exactly.
% - E and F: 2-circuit 3LG-O (route outage). The card is one branch of two circuits,
%   which opens as a whole.
% - The fault bus is the end of the card at the fault point of fig. 4.22 of the report.
%
% Criterion: as in the note of table 4.13, a generator is out of step when the absolute
% difference of its rotor angle `delta` from that of the reference machine G15 (bus
% B3150, the slack) exceeds 360 degrees. A case is unstable when a generator is out of
% step within `[0, TimeEnd]`, and stable when the simulation reaches `TimeEnd` without
% it. The report's cases "out of step" and "divergent oscillation" are unstable. A
% simulation that stops early without an out-of-step generator is "stopped" and does not
% agree with the report.
%
% Modelling differences from the report: the loads are load-impedance (P and Q constant
% impedance) and not the constant-current P load of NLT = 2, with no frequency
% dependence; armature resistance and saturation are not modeled. The report shows that
% constant impedance loads change a stable case to unstable (its fig. 4.28).
%
% Use: MATLAB does not run a file in a folder inside a class folder, with addpath, cd
% or run, so copy the folder out first; the copy reads `table4_13.csv` next to it:
%
% ```matlab
% str_dir = fullfile(tempdir, "IEEJ_WEST30_scenario");
% copyfile(fullfile(fileparts(which("network.IEEJ_WEST30")), "scenario"), str_dir);
% addpath(str_dir);
% tab = run_table4_13();                    % governors on (the default of the network)
% tab = run_table4_13(Governor=false, Sections="night", Cases=["A","D"], Plot=true);
% ```
%
% Name-Value options:
%
% - `Governor` — true for the governors of the report (default true).
% - `Sections` — "peak", "night" or both (default both).
% - `Cases` — Case ids "A" to "F" to run (default all).
% - `TimeEnd` — [s] End of the simulation (default 20, the report's cut-off time).
% - `TimeLimit` — [s] TimeLimit of net.simulate per case (default Inf).
% - `Plot` — true to plot the angle differences from G15 of each case (default false).
% - `Display` — true to print a line per case and the agreement (default true).
%
% Outputs: `tab` has one row per case: Section, Case, FaultBus, OpenBranch, Report,
% ReportStable, Verdict ("stable", "unstable" or "stopped"), Agree, MaxAngle [deg]
% (largest difference from G15), TimeOutOfStep [s] (first time over 360 deg, NaN
% if none), OutOfStep (machines over 360 deg at that time), Flag (of net.simulate) and
% Elapsed [s]. `c_sol` holds the ODEresult of each case (only when requested).
%
% See also network.IEEJ_WEST30, ODEevent, PowerNetwork.simulate
    arguments
        opt.Governor  (1,1) logical = true % true for the governors of the report.
        opt.Sections  (1,:) string {mustBeMember(opt.Sections, ["peak","night"])} = ["peak","night"] % Sections to run.
        opt.Cases     (1,:) string {mustBeMember(opt.Cases, ["A","B","C","D","E","F"])} = ["A","B","C","D","E","F"] % Case ids to run.
        opt.TimeEnd   (1,1) double {mustBePositive} = 20 % [s] End of the simulation.
        opt.TimeLimit (1,1) double {mustBePositive} = Inf % [s] TimeLimit of net.simulate per case.
        opt.Plot      (1,1) logical = false % true to plot the angle differences from G15.
        opt.Display   (1,1) logical = true % true to print the cases and the agreement.
    end
    arguments (Output)
        tab   % Table of the cases, the report verdict and the GUILDA verdict.
        c_sol % ODEresult of each case (cell, rows of tab).
    end
    r_limit = 360;                     % [deg] out-of-step angle of the report
    str_ref = "B3150";                 % bus of the reference machine G15

    str_dir  = fileparts(mfilename("fullpath"));
    tab_case = readtable(fullfile(str_dir, "table4_13.csv"), TextType="string", Delimiter=",");
    tab_case = tab_case(ismember(tab_case.Section, opt.Sections) & ismember(tab_case.Case, opt.Cases), :);

    n_case = height(tab_case);
    sv_verdict = strings(n_case,1);  rv_max = nan(n_case,1);  rv_toos = nan(n_case,1);
    sv_oos = strings(n_case,1);      rv_flag = nan(n_case,1); rv_time = nan(n_case,1);
    c_sol = cell(n_case,1);

    for str_sec = opt.Sections
        lv_sec = find(tab_case.Section == str_sec).';
        if isempty(lv_sec), continue, end
        net = network.IEEJ_WEST30(Section=str_sec, Governor=opt.Governor);
        sv_bus = string(net.a_Bus);
        sv_br  = string(net.a_Branch);
        i_ref  = find(sv_bus == str_ref);
        lv_gen = cellfun(@(b) ~isempty(b.a_Component) && isa(b.a_Component{1}, "component.generator.park"), net.a_Bus);
        iv_gen = find(lv_gen(:)).';

        for k = lv_sec
            row = tab_case(k,:);
            sv_open = split(row.OpenBranch, ";");
            check_branch(net, sv_br, sv_open, row.FromBus, row.ToBus);
            t_clear = row.FaultStart + row.FaultDuration;
            ev_f = ODEevent("fault", net, "TimeSpan", [row.FaultStart, t_clear], "FaultBus", row.FaultBus);
            ev_o = ODEevent("open",  net, "TimeSpan", [t_clear, opt.TimeEnd], "OpenBranch", sv_open);

            t_run = tic;
            [sol, flag] = net.simulate([0, opt.TimeEnd], ev_f, ev_o, Progress="none", TimeLimit=opt.TimeLimit);
            rv_time(k) = toc(t_run);
            rv_flag(k) = flag;

            r  = sol.odeResults;
            rv_t = r.t(:);
            rm_delta = zeros(numel(rv_t), numel(iv_gen));
            for j = 1:numel(iv_gen)
                rm_delta(:,j) = r.Bus(iv_gen(j)).Component(1).X.delta(:);
            end
            rm_diff = abs(rm_delta - rm_delta(:, iv_gen == i_ref)) * 180/pi;
            rv_max(k) = max(rm_diff, [], "all");
            i_t = find(any(rm_diff > r_limit, 2), 1);
            if ~isempty(i_t)
                sv_verdict(k) = "unstable";
                rv_toos(k)    = rv_t(i_t);
                sv_oos(k)     = join("G" + iv_gen(rm_diff(i_t,:) > r_limit), ",");   % G<n> is at bus n
            elseif flag == 1
                sv_verdict(k) = "stable";
            else
                sv_verdict(k) = "stopped";
            end
            if nargout > 1
                c_sol{k} = sol;
            end
            if opt.Plot
                figure("Name", "IEEJ_WEST30 " + str_sec + " case " + row.Case);
                plot(rv_t, (rm_delta - rm_delta(:, iv_gen == i_ref))*180/pi);
                xlabel("t [s]"); ylabel("\delta - \delta_{G15} [deg]");
                title(sprintf("%s %s: %s (report: %s)", str_sec, row.Case, sv_verdict(k), row.Report));
                grid on
            end
            if opt.Display
                fprintf("%-5s %s  report %-8s GUILDA %-8s  max %7.0f deg  t360 %5.2f s  [%s]  (%.0f s)\n", ...
                        str_sec, row.Case, verdict_of(row.ReportStable), sv_verdict(k), rv_max(k), rv_toos(k), sv_oos(k), rv_time(k));
            end
        end
    end

    lv_agree = sv_verdict == arrayfun(@verdict_of, tab_case.ReportStable);
    tab = [tab_case(:, ["Section","Case","FaultBus","OpenBranch","Report","ReportStable"]), ...
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
% Verdict string of the report: "stable" or "unstable"
    if l_stable
        str = "stable";
    else
        str = "unstable";
    end
end


function check_branch(net, sv_br, sv_open, str_from, str_to)
% Error when an opened branch does not join the buses of the case
    for str = sv_open(:).'
        br = net.a_Branch{sv_br == str};
        sv_end = [string(br.a_Bus{1}), string(br.a_Bus{2})];
        if ~isequal(sort(sv_end), sort([str_from, str_to]))
            error("Branch %s joins %s and not %s-%s.", str, join(sv_end, "-"), str_from, str_to);
        end
    end
end
