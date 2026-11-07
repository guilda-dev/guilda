function validateTimeSpanSize(p)
    arguments (Input)
        p  % [s] Value of TimeSpan to check (a row of one or two elements).
    end
    if ~isrow(p)
        error("MATLAB:validators:mustBeRow", "Value must be a row vector.");
    end
    mustBeMember(numel(p), [1,2]);
end
