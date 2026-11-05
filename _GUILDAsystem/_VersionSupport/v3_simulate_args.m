function c_nv = v3_simulate_args(c_nv)
% Convert old option names of simulate.
%
% v3 compatibility hook of PowerNetwork.simulate: rewrites the old names of the solver
% settings, given as Name-Value options, into the v4 option names.
%   Reporter          -> Progress
%   RelativeTolerance -> Tolerance
% Each old name warns once (GUILDA:Deprecated:SimulateOptionName). Other arguments are
% returned unchanged.
%
% Name-Value options:
%
% - `c_nv` — Name-Value options of simulate (after the events).
%
% See also PowerNetwork.simulate
    arguments (Output)
        c_nv   % Name-Value options with the v4 names.
    end
    sr_old = ["Reporter", "RelativeTolerance"];
    sr_new = ["Progress", "Tolerance"];
    for k = 1:2:numel(c_nv)
        x = c_nv{k};
        if ~((ischar(x) && isrow(x)) || (isstring(x) && isscalar(x)))
            continue
        end
        idx = find(strcmpi(x, sr_old), 1);
        if ~isempty(idx)
            Deprecated("SimulateOptionName", sr_old(idx), sr_new(idx));
            c_nv{k} = sr_new(idx);
        end
    end
end
