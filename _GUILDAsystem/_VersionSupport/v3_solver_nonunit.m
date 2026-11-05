function rv_nonUnit = v3_solver_nonunit(rv_nonUnit)
% Warn that the retired property SolverLIN.NonUnit was set.
%
% v3 compatibility hook of SolverLIN.NonUnit: setting net.solver_LIN.NonUnit warns once
% (GUILDA:Deprecated:SolverLinNonUnit) and the value is kept, so later runs treat it as the
% retired option NonUnit of net.linearize (see v3_linearize_args). Reading it returns the
% stored value (no warning). An empty value lists no bus and does not warn: loading a
% network from a .mat file sets the property too.
%
% See also SolverLIN, v3_linearize_args
    arguments (Input)
        rv_nonUnit   % Value set to the property.
    end
    arguments (Output)
        rv_nonUnit   % Value to store.
    end
    if ~isempty(rv_nonUnit)
        Deprecated("SolverLinNonUnit");
    end
end
