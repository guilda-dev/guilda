function TimeSpan = getTimeSpan(times, option)
    arguments (Input)
        times     % [s] Switching times of the disturbances.
        option    % [s] Simulation time [t0, tend].
    end
    arguments (Output)
        TimeSpan  % [s] Phases of the simulation, one [t_start, t_end] per row.
    end
    tcat = reshape(times,[],1);
    t0te = option;
    time = unique([t0te(1); tcat; t0te(2)], "sorted", "first");
    % Events outside the simulation time do not extend it
    time = time(time >= t0te(1) & time <= t0te(2));

    TimeSpan = [time(1:end-1), time(2:end)];
end
