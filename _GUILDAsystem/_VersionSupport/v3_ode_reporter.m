function s_mode = v3_ode_reporter(val)
% Convert a value set to the old SolverODE property Reporter.
%
% v3 compatibility hook of SolverODE.Reporter: the property was renamed Progress.
% Setting net.solver_ODE.Reporter warns once (GUILDA:Deprecated:SimulatorReporter) and
% returns the value to store in Progress. Reading Reporter returns Progress (no warning).
%
% See also SolverODE
    arguments (Input)
        val        % Value set to Reporter: "none", "disp" or "dialog".
    end
    arguments (Output)
        s_mode     % Value for SolverODE.Progress.
    end
    Deprecated("SimulatorReporter");
    s_mode = string(val);
end
