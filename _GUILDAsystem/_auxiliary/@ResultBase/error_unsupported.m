function error_unsupported(obj, s_method)
% Error for an unsupported Plot or Export.
%
% Stops with GUILDA:ResultBase:Unsupported for a method of the Plot / Export
% contract that this result class does not provide.
    arguments (Input)
        obj
        s_method % Name of the unsupported method ("Plot" or "Export").
    end
    error(msg("GUILDA:ResultBase:Unsupported", char(s_method), class(obj)));
end
