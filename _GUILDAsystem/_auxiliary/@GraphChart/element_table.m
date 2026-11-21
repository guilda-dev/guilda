function tab = element_table(obj)
% Elements of the chart: one row per line, bar and marker set, in the order of the series.
    arguments (Input)
        obj
    end
    arguments (Output)
        tab table  % Tag, Kind ("line", "bar" or "marker") and Index (row in the Series* vectors).
    end
    Tag   = obj.tab_series.Tag;
    Kind  = obj.tab_series.Kind;
    Index = (1:height(obj.tab_series))';
    tab = table(Tag, Kind, Index);
end
