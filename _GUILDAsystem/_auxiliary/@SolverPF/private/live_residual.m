function f_iter = live_residual(PlotFcn, s_solver, f_res, tab, r_tol)
% Live display of the power flow (PlotFcn) as the f_iter of a Method class.
%
% f_iter(x, k, state) takes the iterate x of the method (the real form [Vre; Vim; ...] of
% "newton", "levenberg-marquardt" and "fsolve", [theta; V] of "gradient", the state
% [theta; omega; V; u] of "dynamic"), the iteration k (the virtual time for "dynamic") and
% state "init", "iter" or "done", and returns stop.
%
% - "residual": one bar per power equation (two per bus, in the order of f_res: P, or
%   the angle at the slack bus; Q, or |V| at PV and slack buses), with the height |F| of
%   the equation at the iterate (log scale, Tolerance as a dashed line). One figure (Tag
%   "GUILDA:PlotFcn:residual") is reused; it is redrawn at most every
%   0.2 s and at the end (so that drawing does not slow the iteration down).
% - A function handle is called at every iterate as stop = PlotFcn(x, optimValues, state)
%   with x the complex bus voltages and optimValues.iteration, .fval (F of the iterate),
%   .residual (largest |F|) and, for "dynamic", .time (virtual time; .iteration counts
%   the ODE steps).
    arguments (Input)
        PlotFcn                    % Display keys ("residual") or a function handle (output of tools.check_plotfcn).
        s_solver (1,1) string      % Solver of the power flow.
        f_res    (1,1) function_handle  % Residual F of the real form of the voltages (power_equation).
        tab      table             % Power flow conditions of the buses (RowNames: bus tags).
        r_tol    (1,1) double      % [pu] Tolerance, drawn as a line.
    end
    arguments (Output)
        f_iter (1,1) function_handle  % stop = f_iter(x, k, state).
    end
    n_bus  = height(tab);
    f_user = [];
    if isa(PlotFcn, "function_handle")
        f_user = PlotFcn;
    end
    r_floor = r_tol/100;          % bars below it are drawn at it (log scale)
    a_bar   = [];
    ax      = [];
    t_draw  = [];
    n_count = 0;
    f_iter  = @update;

    function stop = update(x, k, s_state)
        stop = false;
        if ~ismember(s_state, ["init","iter","done"])
            return
        end
        l_draw = s_state ~= "iter" || isempty(t_draw) || toc(t_draw) >= 0.2;
        if isempty(f_user) && ~l_draw
            return
        end
        cv_V = voltage(x);
        rv_F = f_res(reshape([real(cv_V), imag(cv_V)].', [], 1));
        if s_state == "iter"
            n_count = n_count + 1;
        end
        if ~isempty(f_user)
            sct = struct("iteration", k, "fval", rv_F, "residual", full(max(abs(rv_F))));
            if s_solver == "dynamic"
                sct.iteration = max(n_count - 1, 0);
                sct.time      = k;
            end
            stop = logical(f_user(cv_V, sct, char(s_state)));
            return
        end
        if s_state == "init"
            create_figure();
        end
        if isempty(a_bar) || ~all(isgraphics(a_bar))
            return               % the figure was closed
        end
        rm_F = reshape(max(abs(full(rv_F)), r_floor), 2, []).';
        a_bar(1).YData = rm_F(:,1);
        a_bar(2).YData = rm_F(:,2);
        ylim(ax, [r_floor, 10^ceil(log10(max([rm_F(:); 10*r_floor])))]);
        if s_solver == "dynamic"
            s_step = sprintf("virtual time %.4g", k);
        else
            s_step = sprintf("iteration %d", k);
        end
        title(ax, sprintf("Power flow (%s) - %s, max mismatch %.3e", s_solver, s_step, max(abs(rv_F))));
        if s_state == "done"
            drawnow
        else
            drawnow limitrate
        end
        t_draw = tic;
    end

    function cv_V = voltage(x)
        switch s_solver
            case "gradient"
                cv_V = x(n_bus+1:end) .* exp(1j*x(1:n_bus));
            case "dynamic"
                cv_V = x(2*n_bus+1:3*n_bus) .* exp(1j*x(1:n_bus));
            otherwise
                cv_V = x(1:2:end) + 1j*x(2:2:end);
        end
    end

    function create_figure()
        s_tag = "GUILDA:PlotFcn:residual";
        fig = findobj(groot, "Type", "figure", "Tag", s_tag);
        if isempty(fig)
            fig = figure("Tag", s_tag, "Name", "Power flow residuals", "NumberTitle", "off");
        else
            fig = fig(1);
            clf(fig);
        end
        sv_bus = string(tab.Properties.RowNames);
        ax = axes(fig);
        a_bar = bar(ax, categorical(sv_bus, sv_bus), r_floor*ones(n_bus, 2), "BaseValue", r_floor);
        set(ax, "YScale", "log");
        hold(ax, "on");
        yline(ax, r_tol, "--", "Tolerance", "HandleVisibility", "off");
        hold(ax, "off");
        ylabel(ax, "|residual| [pu]");
        legend(ax, ["P (angle at slack)", "Q (|V| at PV and slack)"], "Location", "northeast");
        grid(ax, "on");
    end
end
