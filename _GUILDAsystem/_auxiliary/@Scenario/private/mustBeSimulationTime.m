function mustBeSimulationTime(time)
% [] or [t0, tend] with finite t0 < tend
    if isempty(time)
        return
    end
    if ~isreal(time) || numel(time) ~= 2 || ~all(isfinite(time)) || time(1) >= time(2)
        error(msg("GUILDA:Scenario:InvalidTime", mat2str(time)));
    end
end
