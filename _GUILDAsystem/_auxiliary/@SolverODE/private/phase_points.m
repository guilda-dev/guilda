function sol = phase_points(res, f_sol, tv)
% Times and values of the solution of a phase, up to a terminal event.
%
% Without f_sol, the steps of the solver (solve(o, t0, tf)): with a terminal event, the
% event is the last step. With f_sol and tv (SampleTime), the solver takes its own steps
% over [0, tv(end)] (solutionFcn) and the values at the output times tv up to the time
% the integration stopped come from its interpolant; a time that is a step of the solver
% keeps the value of that step, and when the integration stopped before tv(end), that
% time and value are appended, so that the last time is the time it stopped.
    arguments (Input)
        res           % ODEResults of solve or solutionFcn.
        f_sol = []    % Interpolant of the solution (solutionFcn); empty for the steps of the solver.
        tv    = []    % [s] Output times from the start of the phase (1 x n, increasing; with f_sol).
    end
    arguments (Output)
        sol (1,1) struct  % Time (1 x n), Solution (n_x x n), EventIndex (indices of the events that occurred).
    end
    sol = struct("Time", res.Time, "Solution", res.Solution, "EventIndex", res.EventIndex);
    if isempty(f_sol)
        return
    end
    t_end = res.Time(end);
    tq    = tv(tv <= t_end);
    rm_x  = f_sol(tq);
    [lv_step, iv_step] = ismember(tq, res.Time);
    rm_x(:, lv_step) = res.Solution(:, iv_step(lv_step));
    if tq(end) < t_end
        tq(end+1)     = t_end;
        rm_x(:,end+1) = res.Solution(:,end);
    end
    sol.Time     = tq;
    sol.Solution = rm_x;
end
