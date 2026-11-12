function error_unsupported(obj, s_method)
% Error for an unsupported method of the contract (export).
%
% Stops with GUILDA:ResultBase:Unsupported for a method of the export
% contract that this result class does not provide.
    arguments (Input)
        obj
        s_method % Name of the unsupported method ("export").
    end
    error(msg("GUILDA:ResultBase:Unsupported", char(s_method), class(obj)));
end
