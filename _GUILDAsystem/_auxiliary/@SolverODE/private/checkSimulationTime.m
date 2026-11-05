function evnt = checkSimulationTime(t,y,start,timeout)
% Event function of the time limit: crosses zero when timeout seconds have passed since start.
    arguments (Input)
        t        (1,1) double  %#ok<INUSA> [s] Time of the solver.
        y        (:,1) double  %#ok<INUSA> State vector of the solver.
        start    (1,1) uint64  % Value returned by tic at the start of the run.
        timeout  (1,1) double  % [s] Limit of the computation time.
    end
    arguments (Output)
        evnt     (1,1) double  % [s] Remaining computation time.
    end
    evnt = timeout - toc(start);    
end