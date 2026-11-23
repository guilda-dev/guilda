function [G, G_pv] = plot_stability_index(obj, opt)
% Plot the voltage stability index along the path and the weak buses at the nose.
%
% The index is rv_sigmaMin: at each step, the smallest singular value of the Jacobian J of
% the CPF equations with respect to the unknowns, without the lambda column,
%
%   sigma_min(J) = min over |v| = 1 of |J v|,   J = d f / d [|V|; theta; x]  (lambda fixed).
%
% The equations f are the P and Q mismatches of the buses [pu] (with UseInternalState,
% also the state equations of the components), and the unknowns are |V| and theta of the
% buses (with UseInternalState, also the states of the components), as the corrector
% solves them (SolverCPF; J by finite differences). At the saddle-node nose J is
% singular, so sigma_min = 0 there. The participation of a bus is the |V| part of the
% right singular vector of sigma_min, scaled to a largest value of 1 (tab_weakbus at the
% nose).
%
% How to read it: it has no physical unit and no absolute threshold. Near the nose it
% falls roughly like sqrt(lambda_max - lambda), so read it against its first value (the
% equilibrium), or read lambda_max - lambda instead. It jumps where Limits "Q" switches a
% PV bus to PQ (the equations change). When a "V" or "S" limit stops the path
% (tab_stop), it ends far from 0: the value at the stop.
%
% Sources: P.-A. Löf, T. Smed, G. Andersson, D. J. Hill, "Fast calculation of a voltage
% stability index", IEEE Trans. Power Systems 7(1), 1992; B. Gao, G. K. Morison,
% P. Kundur, "Voltage stability evaluation using modal analysis", IEEE Trans. Power
% Systems 7(4), 1992.
%
% The panel of the index draws rv_sigmaMin against lambda, with a dashed line at the nose
% (r_lambdaMax). The lower panel, when tab_weakbus has rows, draws the participation of
% the buses in the critical mode at the nose (largest 1) as bars, for the TopBus buses of
% tab_weakbus with the largest participation. The samples of the chart are the steps
% (rv_t = 1 ... n_step, named "Step"): G.set_time(k) puts a marker on the curve at step
% k, and G.link(G2) keeps it in step with plot_pvcurve, plot_diagram and the other plots
% of the steps. A result without rv_sigmaMin stops with GUILDA:ResultCPF:NoStepData.
%
% With PVCurve true (default), the PV curves of PVBus (|V| [pu] against lambda, as
% plot_pvcurve, with the nose line) are an extra panel on top of the chart: it shares the
% lambda axis (the x axes of the lambda panels are linked) and is a time panel with the
% marker cursor, so set_time(k) puts a marker on each PV curve at step k too. Its lines
% are tagged "V_" + bus tag (legend: the bus tag) and come after the elements above in
% tab_element, so their tags and rows stay. G_pv is then G. PVCurve false, or an axes or
% uiaxes Parent, draws the chart alone as before (G_pv []). A PVBus tag that is not in
% sv_bus stops with GUILDA:ResultCPF:UnknownBus.
%
% It returns the chart G (GraphChart): the line "sigmaMin", one bar per bus (the bus
% tag), then the PV curves ("V_" + bus tag).
%
% <@Examples>
% ```matlab
% res = net.calculate_continuation_powerflow(LoadBus=["B009","B014"]);
% G = res.plot_stability_index(TopBus=5);       % PV curves on top, index, weak buses
% res.plot_stability_index(PVCurve=false);      % the index and the weak buses only
% ```
%
% See also ResultCPF.rv_sigmaMin, ResultCPF.tab_weakbus, ResultCPF.plot_pvcurve
    arguments (Input)
        obj
        opt.TopBus (1,1) double {mustBeInteger, mustBeNonnegative} = 10  % Number of weak buses drawn in the lower panel (0: no lower panel).
        opt.PVCurve (1,1) logical = true  % Draw the PV curves with the plot (see the help); false: the plot alone.
        opt.PVBus {mustBeText} = ""       % Buses of the PV curves: "" those of plot_pvcurve (options.LoadBus; every bus when none), "all" every bus, or bus tags.
        opt.Parent = []  % Container (figure, uifigure, uipanel, uitab, uigridlayout), or axes/uiaxes when there is one panel; [] for a new figure.
    end
    arguments (Output)
        G     % The chart (GraphChart): the line "sigmaMin", then the bars of the weak buses (and the PV curves).
        G_pv  % The chart with the PV panel: G itself; [] with PVCurve false or an axes Parent.
    end
    check_step_data(obj, "plot_stability_index", "rv_sigmaMin");

    sct = step_sample(obj);
    sct.sct_panel = struct("s_title", "Voltage stability index: smallest singular value of the power flow Jacobian", ...
        "s_xlabel", "\lambda", "s_ylabel", "\sigma_{min}(J)  (0 at the nose)", "l_time", true, "s_cursor", "marker", "s_legendLocation", "none");
    sct.sct_series = struct("rv_x", reshape(obj.rv_lambda, 1, []), "rm_y", obj.rv_sigmaMin(:), ...
        "sv_tag", "sigmaMin", "r_lineWidth", 1.2);
    sct.sct_refline = struct("i_panel", 1, "s_axis", "x", "r_value", obj.r_lambdaMax, ...
        "s_label", "\lambda_{max} = " + compose("%.4g", obj.r_lambdaMax), ...
        "rv_color", [0.15 0.15 0.15], "s_lineStyle", "--");
    n_top = min(opt.TopBus, height(obj.tab_weakbus));
    if n_top > 0
        tab = obj.tab_weakbus(1:n_top, :);
        sct.sct_panel(2) = struct("s_title", "Bus participation in the critical mode at the nose", "s_xlabel", "", ...
            "s_ylabel", "Participation", "l_time", false, "s_cursor", "line", "s_legendLocation", "none");
        sct.sct_series(2) = struct("rv_x", [], "rm_y", tab.Participation, "sv_tag", string(tab.Bus), "r_lineWidth", 1);
        [sct.sct_series.i_panel] = deal(1, 2);
        [sct.sct_series.s_type]  = deal("line", "bar");
        [sct.sct_series.sv_x]    = deal(strings(0, 1), string(tab.Bus));
    end
    [G, G_pv] = pair_pvcurve(obj, opt, sct);
end
