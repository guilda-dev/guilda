function out = transTab(tab)
% Transpose a table: the variables become rows and the rows become variables.
%
% The row names of the output are the variable names of the input.
    trans_Tab = rows2vars(tab);
    trans_Tab.Properties.RowNames = trans_Tab.OriginalVariableNames;
    out = trans_Tab(:,2:end);
end