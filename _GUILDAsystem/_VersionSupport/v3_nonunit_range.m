function v3_nonunit_range(s_options, n_bus)
% Reject a bus that does not exist in the retired option NonUnit.
%
% v3 compatibility hook of odeLinearizer.solve: stops with GUILDA:odeLinearizer:NonUnit.
%
% Inputs:
%
% - `s_options` — Effective settings; the field NonUnit exists only when buses are listed.
% - `n_bus` — Number of buses of the network.
%
% See also v3_linearize_args, odeLinearizer.solve
    if isfield(s_options, "NonUnit") && any(s_options.NonUnit > n_bus)
        error("GUILDA:odeLinearizer:NonUnit", ...
              "NonUnit = [%s] names a bus that does not exist; give indices of net.a_Bus (1 to %d).", ...
              num2str(s_options.NonUnit), n_bus)
    end
end
