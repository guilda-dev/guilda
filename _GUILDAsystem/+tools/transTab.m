function out = transTab(tab)
    trans_Tab = rows2vars(tab);
    trans_Tab.Properties.RowNames = trans_Tab.OriginalVariableNames;
    out = trans_Tab(:,2:end);
end