function v3_nonunit_range(s_options, n_bus)
% Reject a bus that does not exist in the retired option NonUnit.
%
% v3 compatibility hook of LTIsolver.solve: stops with GUILDA:LTIsolver:NonUnit.
%
% Inputs:
%
% - `s_options` — Effective settings; the field NonUnit exists only when buses are listed.
% - `n_bus` — Number of buses of the network.
%
% See also v3_linearize_args, LTIsolver.solve
    if isfield(s_options, "NonUnit") && any(s_options.NonUnit > n_bus)
        error(msg("GUILDA:v3_nonunit_range:NonUnit", num2str(s_options.NonUnit), string(n_bus)))
    end
end
