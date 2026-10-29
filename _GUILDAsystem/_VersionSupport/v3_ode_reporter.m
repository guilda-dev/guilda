function str_mode = v3_ode_reporter(val)
% <@Desc>
% v3 compatibility hook of odeSimulator.Reporter: the property was renamed Progress.
% Setting net.solver_ODE.Reporter warns once (GUILDA:Deprecated:SimulatorReporter) and
% returns the value to store in Progress. Reading Reporter returns Progress (no warning).
% <@Role> Compatibility
% <@Summary> Convert a value set to the old property Reporter.
% <@Signatures>
% [
%   "str_mode = v3_ode_reporter(val)"
% ]
% <@Parameters>
% [
%   {"Name": "val", "Type": "string scalar", "Description": "Value set to Reporter: \"none\", \"disp\" or \"dialog\".", "Required": true, "Default": "-"}
% ]
% <@Returns>
% [
%   {"Name": "str_mode", "Type": "string scalar", "Description": "Value for odeSimulator.Progress."}
% ]
    Deprecated("SimulatorReporter");
    str_mode = string(val);
end
