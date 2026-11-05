function v3_nonunit_range(sct_options, n_bus)
% Reject a bus that does not exist in the retired option NonUnit.
%
% v3 compatibility hook of SolverLIN.solve: stops with GUILDA:v3_nonunit_range:NonUnit.
%
% Inputs:
%
% - `sct_options` — Effective settings; the field NonUnit exists only when buses are listed.
% - `n_bus` — Number of buses of the network.
%
% See also v3_linearize_args, SolverLIN.solve
    if isfield(sct_options, "NonUnit") && any(sct_options.NonUnit > n_bus)
        error(msg("GUILDA:v3_nonunit_range:NonUnit", num2str(sct_options.NonUnit), string(n_bus)))
    end
end
