function mustBeHandleOrEmpty(f)
% Validate the Cost and Constraint settings: a function handle or [] (none).
    arguments (Input)
        f   % Value of Cost or Constraint.
    end
    if ~(isempty(f) || isa(f, "function_handle"))
        error(msg("GUILDA:SolverOPF:InvalidHandle"))
    end
end
