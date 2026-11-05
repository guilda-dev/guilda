function tp = remove_column(tp)
% Remove the "base" column from a tab_parameter table.
%
% "base" is this view (a handle): an edit of comp.tab_parameter.base.Hz
% has already been forwarded to the network.
    arguments (Input)
        tp  % tab_parameter table.
    end
    arguments (Output)
        tp  % tab_parameter table without the "base" column.
    end
    if ismember("base", string(tp.Properties.VariableNames))
        tp = removevars(tp, "base");
    end
end
