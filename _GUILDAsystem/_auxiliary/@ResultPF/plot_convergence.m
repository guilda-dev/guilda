function fig = plot_convergence(obj, opt)
% Plot the convergence of the power flow calculation.
%
% Draws the largest residual of the power equations at each iterate stored in
% cm_Vhistory, on a log scale, against rv_step: the iteration number, or the virtual time
% for Solver "dynamic". The residuals are those the solver checks against Tolerance
% (private power_equation of SolverPF): P, or the angle at the slack bus; Q, or |V| at PV
% and slack buses. They are computed from the stored power flow conditions
% (tab_PFcondition) and admittance matrix (cm_Y). Tolerance is drawn as a dashed line
% (Tag "Tolerance"). With Bus, a second tile shows |V| of those buses at each iterate. It
% reads only the stored result; a result without the conditions (e.g. one of initialize
% without a power flow) stops with GUILDA:ResultPF:NoHistory.
%
% <@Examples>
% ```matlab
% res = network.IEEE14bus().calculate_powerflow(WarmStart=false);
% res.plot_convergence();
% res.plot_convergence(Bus=["B001","B014"]);   % also |V| of two buses
% ```
%
% See also ResultPF.cm_Vhistory, ResultPF.rv_step, SolverPF
    arguments (Input)
        obj
        opt.Parent = [] % Container to draw in. A new figure when empty.
        opt.Bus (1,:) string = strings(1,0) % Tags of the buses whose |V| is also drawn; empty draws the residual only.
    end
    arguments (Output)
        fig % Layout holding the axes (residual, then |V| when Bus is given).
    end
    if height(obj.tab_PFcondition) == 0 || isempty(obj.cm_Y) || isempty(obj.cm_Vhistory)
        error(msg("GUILDA:ResultPF:NoHistory"))
    end
    sv_bus = string(obj.tab_bus.Properties.RowNames);
    iv_bus = pick_rows(sv_bus, opt.Bus, "bus");
    if isempty(opt.Parent)
        opt.Parent = figure();
    end
    rv_res = history_residual(obj.cm_Vhistory, obj.cm_Y, obj.tab_PFcondition);
    rv_x   = obj.rv_step;
    s_x    = "iteration";
    if isfield(obj.options, "Solver") && obj.options.Solver == "dynamic"
        s_x = "virtual time";
    end

    fig = tiledlayout(opt.Parent, 1 + ~isempty(opt.Bus), 1, "TileSpacing", "compact");
    title(fig, "Power flow convergence");
    ax = nexttile(fig);
    semilogy(ax, rv_x, max(rv_res, realmin), "-o", "MarkerSize", 4, "Tag", "Residual");
    if isfield(obj.options, "Tolerance")
        yline(ax, obj.options.Tolerance, "--", "Tolerance", "Color", [0.85 0.33 0.10], "Tag", "Tolerance");
    end
    xlabel(ax, s_x);
    ylabel(ax, "largest residual [pu]");
    grid(ax, "on");
    if isempty(opt.Bus)
        return
    end
    ax = nexttile(fig);
    h = plot(ax, rv_x, abs(obj.cm_Vhistory(iv_bus,:)).', "-o", "MarkerSize", 4);
    set(h, {"DisplayName"}, cellstr(sv_bus(iv_bus)));
    set(h, "Tag", "V");
    legend(ax, "Location", "best");
    xlabel(ax, s_x);
    ylabel(ax, "|V| [pu]");
    grid(ax, "on");
end
