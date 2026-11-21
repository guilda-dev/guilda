function tab = table_rows(obj)
% Rows of tab_event: per branch (t, Status, NaN).
    arguments (Input)
        obj
    end
    arguments (Output)
        tab table  % Tag, Target, Time, Status, Point.
    end
    n = numel(obj.sv_branch);
    tab = table(repmat(obj.s_tag, n, 1), obj.sv_branch, repmat(obj.r_time, n, 1), ...
                repmat(obj.s_status, n, 1), NaN(n, 1), ...
                'VariableNames', ["Tag","Target","Time","Status","Point"]);
end
