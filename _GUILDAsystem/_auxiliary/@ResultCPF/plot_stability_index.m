function G = plot_stability_index(obj, opt)
% Plot the voltage stability index along the path and the weak buses at the nose.
%
% The upper panel draws rv_sigmaMin, the smallest singular value of the power flow
% Jacobian at each step, against lambda: it goes to 0 at the nose, which a dashed line
% marks (r_lambdaMax). The lower panel, when tab_weakbus has rows, draws the participation
% of the buses at the nose (largest 1) as bars, for the TopBus buses of tab_weakbus with
% the largest participation. The samples of the chart are the steps (rv_t = 1 ...
% n_step, named "Step"): G.set_time(k) puts a marker on the curve at step k, and G.link(G2)
% keeps it in step with plot_pvcurve, plot_diagram and the other plots of the steps. A
% result without rv_sigmaMin stops with GUILDA:ResultCPF:NoStepData.
%
% It returns the chart G (GraphChart): the line "sigmaMin" and one bar per bus (the bus
% tag).
%
% <@Examples>
% ```matlab
% res = net.calculate_continuation_powerflow(LoadBus=["B009","B014"]);
% G = res.plot_stability_index(TopBus=5);
% G.link(res.plot_pvcurve());
% ```
%
% See also ResultCPF.rv_sigmaMin, ResultCPF.tab_weakbus, ResultCPF.plot_pvcurve
    arguments (Input)
        obj
        opt.TopBus (1,1) double {mustBeInteger, mustBeNonnegative} = 10  % Number of weak buses drawn in the lower panel (0: no lower panel).
        opt.Parent = []  % Container (figure, uifigure, uipanel, uitab, uigridlayout), or axes/uiaxes when there is one panel; [] for a new figure.
    end
    arguments (Output)
        G  % The chart (GraphChart): the line "sigmaMin", then the bars of the weak buses.
    end
    check_step_data(obj, "plot_stability_index", "rv_sigmaMin");

    sct = step_sample(obj);
    sct.sct_panel = struct("s_title", "Voltage stability index", "s_xlabel", "\lambda", ...
        "s_ylabel", "\sigma_{min}", "l_time", true, "s_cursor", "marker", "s_legendLocation", "none");
    sct.sct_series = struct("rv_x", reshape(obj.rv_lambda, 1, []), "rm_y", obj.rv_sigmaMin(:), ...
        "sv_tag", "sigmaMin", "r_lineWidth", 1.2);
    sct.sct_refline = struct("i_panel", 1, "s_axis", "x", "r_value", obj.r_lambdaMax, ...
        "s_label", "\lambda_{max} = " + compose("%.4g", obj.r_lambdaMax), ...
        "rv_color", [0.15 0.15 0.15], "s_lineStyle", "--");
    n_top = min(opt.TopBus, height(obj.tab_weakbus));
    if n_top > 0
        tab = obj.tab_weakbus(1:n_top, :);
        sct.sct_panel(2) = struct("s_title", "Weak buses at the nose", "s_xlabel", "", ...
            "s_ylabel", "Participation", "l_time", false, "s_cursor", "line", "s_legendLocation", "none");
        sct.sct_series(2) = struct("rv_x", [], "rm_y", tab.Participation, "sv_tag", string(tab.Bus), "r_lineWidth", 1);
        [sct.sct_series.i_panel] = deal(1, 2);
        [sct.sct_series.s_type]  = deal("line", "bar");
        [sct.sct_series.sv_x]    = deal(strings(0, 1), string(tab.Bus));
    end
    G = GraphChart(sct, Parent=opt.Parent);
end
