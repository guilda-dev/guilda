function mustBeHandleOrEmpty(f)
% Validate a user term of the OPF (Cost, Constraint): a function handle, or [] for none.
    arguments (Input)
        f   % Value to check.
    end
    if ~(isempty(f) || isa(f, "function_handle"))
        error(msg("GUILDA:PowerNetwork:InvalidOpfHandle"))
    end
end
