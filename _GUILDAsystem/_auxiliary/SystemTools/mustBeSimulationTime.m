function mustBeSimulationTime(time)
% Validate a simulation time [t0, tend]: two finite real values with t0 < tend.
%
% Used by Scenario.Time and PowerNetwork.add_scenario. An invalid time stops with
% GUILDA:mustBeSimulationTime:InvalidTime.
%
% <@Examples>
% ```matlab
% mustBeSimulationTime([0, 10]);   % passes
% ```
    arguments (Input)
        time   % [s] Value to check.
    end
    if ~isnumeric(time) || ~isreal(time) || numel(time) ~= 2 || ~all(isfinite(time)) || time(1) >= time(2)
        s_time = class(time);
        if isnumeric(time)
            s_time = mat2str(time);
        end
        error(msg("GUILDA:mustBeSimulationTime:InvalidTime", s_time));
    end
end
