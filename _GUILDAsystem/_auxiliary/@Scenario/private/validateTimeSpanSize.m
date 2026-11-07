function validateTimeSpanSize(p)
    arguments (Input)
        p  % [s] Value of TimeSpan to check (one or two elements).
    end
    isRow = @(x) mustBeRow(x);
    is1x2 = @(x) mustBeMember(numel(x), [1,2]);

    isRow(p);
    is1x2(p);
end