function validateTimeSpanSize(p)
    isRow = @(x) mustBeRow(x);
    is1x2 = @(x) mustBeMember(numel(x), [1,2]);

    isRow(p);
    is1x2(p);
end