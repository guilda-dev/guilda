function str_mode = v3_ode_reporter(val)
% Convert a value set to the old odeSimulator property Reporter.
%
% v3 compatibility hook of odeSimulator.Reporter: the property was renamed Progress.
% Setting net.solver_ODE.Reporter warns once (GUILDA:Deprecated:SimulatorReporter) and
% returns the value to store in Progress. Reading Reporter returns Progress (no warning).
%
% Name-Value options:
%
% - `val` — Value set to Reporter: "none", "disp" or "dialog".
%
% See also odeSimulator
    arguments (Output)
        str_mode   % Value for odeSimulator.Progress.
    end
    Deprecated("SimulatorReporter");
    str_mode = string(val);
end
