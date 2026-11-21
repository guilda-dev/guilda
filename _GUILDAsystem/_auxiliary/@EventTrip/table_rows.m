function tab = table_rows(obj)
% Rows of tab_event: per unit (t, "open", NaN).
    arguments (Input)
        obj
    end
    arguments (Output)
        tab table  % Tag, Target, Time, Status, Point.
    end
    n = numel(obj.sv_unit);
    tab = table(repmat(obj.s_tag, n, 1), obj.sv_unit, repmat(obj.r_time, n, 1), ...
                repmat("open", n, 1), NaN(n, 1), ...
                'VariableNames', ["Tag","Target","Time","Status","Point"]);
end
