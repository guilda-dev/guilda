function [value,isterminal,direction] = Events(obj,t)
% Check whether the phase may continue (event function of the solver).
%
% Stops the phase when the run exceeds timelimit, as time_keeper does, so that TimeLimit
% also works when the solver calls no OutputFcn (SolverODE.solve with SampleTime uses
% solutionFcn); the reason goes into message. Nothing is drawn here.
    arguments (Input)
        obj
        t (1,1) double = NaN  % [s] Time from the start of the phase (SolverODE calls odeProg.Events(t)); NaN: no check.
    end
    arguments (Output)
        value       % Event value: true while the phase may continue.
        isterminal  % 1 (the event stops the integration).
        direction   % 0 (any direction).
    end
    % The value is the one before the check, so the stop is found at the next call, after
    % a step (as with time_keeper): the solver does not stop on an event of its first step
    % found at its initial time. The start of the phase (t = 0) is not checked.
    value = obj.ToBeContinue;
    if value && t > 0 && toc(obj.start_time) >= obj.timelimit
        obj.ToBeContinue = false;
        obj.message = "|(timeout: t=" + (obj.timeoffset + t) + ")";
    end
    isterminal = 1;
    direction  = 0;
end
