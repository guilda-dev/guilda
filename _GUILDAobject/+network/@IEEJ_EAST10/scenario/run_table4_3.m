function tab = run_table4_3(opt)
% Run the 44 fault cases of table 4.3 of the IEEJ report on network.IEEJ_EAST10.
% Each case of `table4_3.csv` (in this folder) is a three-phase fault at the From end
% of a line card (`FaultBus`) for `FaultDuration` (70 ms), then the opening of 1 or 2
% circuits of that card (`OpenBranch`) until the end of the simulation, from the
% equilibrium of the section. The result is judged stable or out-of-step and compared
% with the verdict of the report.
%
% Case data (`table4_3.csv`, one row per case):
%
% - `Section` "peak" or "night", `Card` the line card number of the Y-method data,
%   `From`, `To` its buses, `FaultBus` the tag of the From bus.
% - `Circuits` the number of opened circuits (1 or 2), `OpenBranch` their branch tags,
%   separated by spaces. Each circuit of a line card is one branch of the network
%   (the two circuits of card `k`, in the card order of the data, are `EL(2k-1)` and
%   `EL(2k)`), so a single circuit opens exactly. A card with a parallel card (for
%   example 18 and 118) keeps the parallel card when both of its circuits open.
% - `Report` the result of the report, `ReportVerdict` "stable" or "out-of-step". The
%   report's "sustained oscillation" (peak, card 36) has no out-of-step generator and
%   counts as stable.
%
% Criterion: as in the footnote of the report, a generator is out of step when the
% absolute value of its rotor angle relative to the reference generator (the slack
% generator: G3 at peak, G6 at night) exceeds 360 degrees at any time up to `TimeEnd`.
% A case is out-of-step when a generator is out of step, otherwise stable; when the
% solver stops early without an out-of-step generator, the verdict is "incomplete".
% The solver tolerance is `Tolerance` (1e-6) instead of the default 1e-4 of
% net.solver_ODE: with 1e-4, ode15s stops early in some large-swing cases (for example
% peak card 36 without governors at about 3.7 s).
%
% Modelling differences from the report (see network.IEEJ_EAST10):
%
% - Loads are load-impedance (constant impedance): the report's NLT=2 has
%   constant-current P above 0.7 pu and frequency characteristics.
% - The generators have no saturation, `Ta` is not used and `D = 0`.
% - Governors are the IEEJ_LPT1/IEEJ_LPT4 models with the constants of the report's
%   figures, or none with `Governor=false`.
%
% MATLAB does not run files in the subfolders of a class folder (`@IEEJ_EAST10`), so
% this folder cannot be added to the path: copy this file to a folder on the path
% first. It reads `table4_3.csv` from this folder wherever the copy is.
%
% <@Examples>
% Copy the script, run the table, then without governors at peak only:
%
% ```matlab
% str_dir = fullfile(fileparts(which("network.IEEJ_EAST10")), "scenario");
% copyfile(fullfile(str_dir, "run_table4_3.m"), tempdir); addpath(tempdir);
% tab = run_table4_3();
% tab = run_table4_3(Governor=false, Sections="peak");
% ```
%
% See also network.IEEJ_EAST10, ODEevent, controller.governor.IEEJ_LPT1
    arguments
        opt.Governor (1,1) logical = true % true for the governors of the network (its default).
        opt.Sections (1,:) string {mustBeMember(opt.Sections,["peak","night"])} = ["peak","night"] % Sections to run.
        opt.Cases (1,:) double = [] % Row numbers of table4_3.csv to run; [] for all the rows of Sections.
        opt.TimeEnd (1,1) double {mustBePositive} = 20 % [s] End of the simulation; the fault starts at 0.
        opt.Tolerance (1,1) double {mustBePositive} = 1e-6 % Relative and absolute tolerance of the solver.
        opt.Plot (1,1) logical = false % true to plot the relative rotor angles of each case.
        opt.Display (1,1) logical = true % true to print each case and the agreement.
    end
    arguments (Output)
        tab % Table of the cases with the report and GUILDA verdicts and their agreement.
    end
    str_csv  = fullfile(fileparts(which("network.IEEJ_EAST10")), "scenario", "table4_3.csv");
    tab_case = readtable(str_csv, ...
                         TextType="string", Delimiter=",");
    lv_run = ismember(tab_case.Section, opt.Sections);
    if ~isempty(opt.Cases)
        lv_run = lv_run & ismember((1:height(tab_case)).', opt.Cases);
    end
    tab = tab_case(lv_run, ["Section","Card","Circuits","OpenBranch","Report","ReportVerdict"]);
    n_case = height(tab);
    tab.Verdict       = strings(n_case,1);
    tab.Agree         = false(n_case,1);
    tab.OutOfStep     = strings(n_case,1);  % out-of-step generators
    tab.TimeOutOfStep = inf(n_case,1);      % [s] first time beyond 360 degrees
    tab.MaxAngle      = zeros(n_case,1);    % [deg] largest relative angle
    tab.MaxVfield     = zeros(n_case,1);    % [pu] largest field voltage
    tab.MinVfield     = zeros(n_case,1);    % [pu] smallest field voltage

    s_net = struct();
    for s = intersect(opt.Sections, tab.Section.', "stable")
        s_net.(s) = network.IEEJ_EAST10(Section=s, Governor=opt.Governor);
    end
    i_ref = struct("peak", 3, "night", 6);    % reference (slack) generator

    c_case = tab_case(lv_run, :);
    for k = 1:n_case
        s   = tab.Section(k);
        net = s_net.(s);
        r_tf = c_case.FaultDuration(k);
        ev_fault = ODEevent("fault", net, "TimeSpan", [0, r_tf], "FaultBus", c_case.FaultBus(k));
        ev_open  = ODEevent("open",  net, "TimeSpan", [r_tf, opt.TimeEnd], ...
                            "OpenBranch", split(c_case.OpenBranch(k)));
        [sol, flag] = net.simulate([0, opt.TimeEnd], ev_fault, ev_open, Progress="none", ...
                                   Tolerance=opt.Tolerance, AbsoluteTolerance=opt.Tolerance);
        r = sol.odeResults;

        n_gen  = 10;
        m_delta = zeros(numel(r.t), n_gen);
        m_vfld  = zeros(numel(r.t), n_gen);
        for i = 1:n_gen
            m_delta(:,i) = r.Bus(i).Component(1).X.delta;
            m_vfld(:,i)  = r.Bus(i).Component(1).U.Vfield;
        end
        m_rel  = abs(m_delta - m_delta(:, i_ref.(s)));
        lv_out = any(m_rel > 2*pi, 1);
        for i = find(lv_out)
            tab.TimeOutOfStep(k) = min(tab.TimeOutOfStep(k), r.t(find(m_rel(:,i) > 2*pi, 1)));
        end
        tab.OutOfStep(k) = strjoin("G" + string(find(lv_out)), " ");
        tab.MaxAngle(k)  = max(m_rel, [], "all")*180/pi;
        tab.MaxVfield(k) = max(m_vfld, [], "all");
        tab.MinVfield(k) = min(m_vfld, [], "all");
        if any(lv_out)
            tab.Verdict(k) = "out-of-step";
        elseif flag ~= 1
            tab.Verdict(k) = "incomplete";
        else
            tab.Verdict(k) = "stable";
        end
        tab.Agree(k) = tab.Verdict(k) == tab.ReportVerdict(k);

        if opt.Display
            fprintf("%-5s card %3d, %d cct: report %-11s GUILDA %-11s %s\n", s, tab.Card(k), ...
                    tab.Circuits(k), tab.ReportVerdict(k), tab.Verdict(k), tab.OutOfStep(k));
        end
        if opt.Plot
            figure("Name", sprintf("%s card %d, %d circuit(s)", s, tab.Card(k), tab.Circuits(k)));
            plot(r.t, (m_delta - m_delta(:, i_ref.(s)))*180/pi);
            xlabel("t [s]"); ylabel("rotor angle - reference [deg]");
            legend("G" + string(1:n_gen), Location="eastoutside");
            title(sprintf("%s card %d, %d circuit(s): %s", s, tab.Card(k), tab.Circuits(k), tab.Verdict(k)));
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
