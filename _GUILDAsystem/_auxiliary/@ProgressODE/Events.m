function [value,isterminal,direction] = Events(obj,~,~)
% Check whether the phase may continue (event function of the solver).
    arguments (Output)
        value       % Event value: true while the phase may continue.
        isterminal  % 1 (the event stops the integration).
        direction   % 0 (any direction).
    end
    % No input block: SolverODE calls this as odeProg.Events() without t and x.
    value = obj.ToBeContinue;
    isterminal = 1;
    direction  = 0;
end
