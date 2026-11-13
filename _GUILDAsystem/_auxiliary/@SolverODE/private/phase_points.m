function sol = phase_points(res)
% Times and values of the solution of a phase, up to a terminal event.
%
% With output times (solve(o, tv)) and a terminal event, the ode object returns NaN at the
% times after the event and does not return the event itself: those times are removed and
% the event is appended, so that the last time is the time the integration stopped (as
% with solve(o, t0, tf), where the event is the last step).
    arguments (Input)
        res  % ODEResults of solve.
    end
    arguments (Output)
        sol (1,1) struct  % Time (1 x n), Solution (n_x x n), EventIndex (indices of the events that occurred).
    end
    sol = struct("Time", res.Time, "Solution", res.Solution, "EventIndex", res.EventIndex);
    lv_nan = any(isnan(sol.Solution), 1);
    if ~any(lv_nan)
        return
    end
    i_last = find(~lv_nan, 1, "last");
    if isempty(i_last)
        i_last = 0;
    end
    sol.Time     = sol.Time(1:i_last);
    sol.Solution = sol.Solution(:, 1:i_last);
    if ~isempty(res.EventTime) && (i_last == 0 || res.EventTime(end) > sol.Time(end))
        sol.Time(end+1)       = res.EventTime(end);
        sol.Solution(:,end+1) = res.EventSolution(:,end);
    end
end
