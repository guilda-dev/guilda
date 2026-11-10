function f_step = live_pvcurve(PlotFcn, sv_bus, iv_V)
% Live display of the continuation power flow (PlotFcn), called at each point of the path.
%
% stop = f_step(xf, n_corr, k, state) takes the full point xf of the path ([|V|; angle V
% of each bus (and states); lambda], rows iv_V = w.rv_BusVi), the corrector iterations
% n_corr of the step, the step k (0 at the starting point) and state "init" (starting
% point), "iter" (each step) or "done" (after the last step, xf the last point).
%
% - "pvcurve": |V| of every bus against lambda, one line per bus, extended at each step.
%   One figure (Tag "GUILDA:PlotFcn:pvcurve") is reused; it is redrawn at most every
%   0.2 s and at the end (so that drawing does not slow the trace down).
% - A function handle is called at every point as stop = PlotFcn(x, optimValues, state)
%   with x the complex bus voltages and optimValues.iteration (step), .lambda and
%   .correctorIterations (of the step; 0 at the starting point).
    arguments (Input)
        PlotFcn                 % Display keys ("pvcurve") or a function handle (output of tools.check_plotfcn).
        sv_bus  (:,1) string    % Bus tags, in the bus order of the path.
        iv_V    (:,1) double    % Rows of |V| and angle V of each bus in the full point (w.rv_BusVi).
    end
    arguments (Output)
        f_step (1,1) function_handle  % stop = f_step(xf, n_corr, k, state).
    end
    f_user = [];
    if isa(PlotFcn, "function_handle")
        f_user = PlotFcn;
    end
    n_bus     = numel(sv_bus);
    rv_lambda = zeros(1,0);
    rm_V      = zeros(n_bus,0);
    a_line    = [];
    ax        = [];
    t_draw    = [];
    f_step    = @update;

    function stop = update(xf, n_corr, k, s_state)
        stop = false;
        rv_Vabs = xf(iv_V(1:2:end));
        if ~isempty(f_user)
            cv_V = rv_Vabs .* exp(1j*xf(iv_V(2:2:end)));
            sct  = struct("iteration", k, "lambda", xf(end), "correctorIterations", n_corr);
            stop = logical(f_user(cv_V, sct, char(s_state)));
            return
        end
        if s_state ~= "done"
            rv_lambda(end+1) = xf(end);
            rm_V(:,end+1)    = rv_Vabs;
        end
        if s_state == "init"
            create_figure();
        end
        if s_state == "iter" && ~isempty(t_draw) && toc(t_draw) < 0.2
            return
        end
        if isempty(a_line) || ~all(isgraphics(a_line))
            return               % the figure was closed
        end
        for i = 1:n_bus
            set(a_line(i), "XData", rv_lambda, "YData", rm_V(i,:));
        end
        title(ax, sprintf("PV curve - step %d, \\lambda = %.4g", k, rv_lambda(end)));
        if s_state == "done"
            drawnow
        else
            drawnow limitrate
        end
        t_draw = tic;
    end

    function create_figure()
        s_tag = "GUILDA:PlotFcn:pvcurve";
        fig = findobj(groot, "Type", "figure", "Tag", s_tag);
        if isempty(fig)
            fig = figure("Tag", s_tag, "Name", "Continuation power flow", "NumberTitle", "off");
        else
            fig = fig(1);
            clf(fig);
        end
        ax = axes(fig);
        a_line = plot(ax, rv_lambda, rm_V, "LineWidth", 1.2);
        xlabel(ax, "\lambda");
        ylabel(ax, "|V| [pu]");
        if n_bus <= 20
            legend(ax, sv_bus, "Location", "southwest", "AutoUpdate", "off");
        end
        grid(ax, "on");
    end
end
