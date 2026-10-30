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
    sv_old = ["Reporter", "RelativeTolerance"];
    sv_new = ["Progress", "Tolerance"];
    for k = 1:2:numel(c_nv)
        x = c_nv{k};
        if ~((ischar(x) && isrow(x)) || (isstring(x) && isscalar(x)))
            continue
        end
        idx = find(strcmpi(x, sv_old), 1);
        if ~isempty(idx)
            Deprecated("SimulateOptionName", sv_old(idx), sv_new(idx));
            c_nv{k} = sv_new(idx);
        end
    end
end
