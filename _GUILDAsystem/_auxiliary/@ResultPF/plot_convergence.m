function G = plot_convergence(obj, opt)
% Plot the convergence of the power flow calculation.
%
% Draws the largest residual of the power equations at each iterate stored in
% cm_Vhistory, on a log scale, against rv_step: the iteration number, or the virtual time
% for Solver "dynamic". The iteration axis has integer ticks only. The residuals are those the solver checks against Tolerance
% (private power_equation of SolverPF): P, or the angle at the slack bus; Q, or |V| at PV
% and slack buses. They are computed from the stored power flow conditions
% (tab_PFcondition) and admittance matrix (cm_Y). Tolerance is drawn as a dashed
% reference line. With Bus, a second panel shows |V| of those buses at each iterate. It
% reads only the stored result; a result without the conditions (e.g. one of initialize
% without a power flow) stops with GUILDA:ResultPF:NoHistory.
%
% It returns the chart G (GraphChart). Its elements (kind "line") are tagged:
%
% - "Residual": the largest residual (first panel);
% - the bus tag: |V| of the bus (second panel, with Bus).
%
% For Solver "dynamic" the panels are time panels over the virtual time (G.set_time
% draws a cursor).
%
% <@Examples>
% ```matlab
% res = network.IEEE14bus().calculate_powerflow(WarmStart=false);
% G = res.plot_convergence();
% G.set_style("Residual", Color="k", LineWidth=2);
% res.plot_convergence(Bus=["B001","B014"]);   % also |V| of two buses
% ```
%
% See also GraphChart, ResultPF.cm_Vhistory, ResultPF.rv_step, SolverPF
    arguments (Input)
        obj
        opt.Parent = []                      % Container (figure, uifigure, uipanel, uitab, uigridlayout), or axes/uiaxes without Bus; [] for a new figure.
        opt.Bus (1,:) string = strings(1,0)  % Tags of the buses whose |V| is also drawn; empty draws the residual only.
    end
    arguments (Output)
        G  % The chart (GraphChart): panels residual, then |V| when Bus is given.
    end
    if height(obj.tab_PFcondition) == 0 || isempty(obj.cm_Y) || isempty(obj.cm_Vhistory)
        error(msg("GUILDA:ResultPF:NoHistory"))
    end
    sv_bus = string(obj.tab_bus.Properties.RowNames);
    iv_bus = pick_rows(sv_bus, opt.Bus, "bus");
    rv_res = history_residual(obj.cm_Vhistory, obj.cm_Y, obj.tab_PFcondition);
    rv_x   = obj.rv_step;
    s_x    = "iteration";
    if isfield(obj.options, "Solver") && obj.options.Solver == "dynamic"
        s_x = "virtual time";
    end
    l_time = s_x == "virtual time";

    sct = struct("s_title", "Power flow convergence");
    sct.sct_panel = struct("s_xlabel", s_x, "s_ylabel", "largest residual [pu]", "s_yscale", "log", ...
                           "l_time", l_time, "s_legendLocation", "none");
    sct.sct_series = struct("i_panel", 1, "rv_x", rv_x, "rm_y", reshape(max(rv_res, realmin), [], 1), ...
                            "sv_tag", "Residual", "s_marker", "o", "r_markerSize", 4);
    if isfield(obj.options, "Tolerance")
        sct.sct_refline = struct("r_value", obj.options.Tolerance, "s_label", "Tolerance");
    end
    if ~isempty(opt.Bus)
        sct.sct_panel(2) = struct("s_xlabel", s_x, "s_ylabel", "|V| [pu]", "s_yscale", "linear", ...
                                  "l_time", l_time, "s_legendLocation", "best");
        sct.sct_series(2) = struct("i_panel", 2, "rv_x", rv_x, "rm_y", abs(obj.cm_Vhistory(iv_bus,:)).', ...
                                   "sv_tag", sv_bus(iv_bus), "s_marker", "o", "r_markerSize", 4);
    end
    if l_time
        sct.rv_t = reshape(rv_x, 1, []);
    end
    G = GraphChart(sct, Parent=opt.Parent);
    if ~l_time   % iterations are integers: at most about 10 integer ticks
        set(G.ax, "XTick", round(min(rv_x)):max(1, ceil((max(rv_x) - min(rv_x))/10)):round(max(rv_x)));
    end
end
