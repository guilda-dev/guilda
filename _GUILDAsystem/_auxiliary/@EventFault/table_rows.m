function tab = table_rows(obj)
% Rows of tab_event: per target (t_start, Status, Point) and (t_end, "none", Point).
    arguments (Input)
        obj
    end
    arguments (Output)
        tab table  % Tag, Target, Time, Status, Point.
    end
    n = numel(obj.sv_target);
    tab = table(repmat(obj.s_tag, 2*n, 1), repelem(obj.sv_target, 2, 1), repmat(obj.rr_time(:), n, 1), ...
                repmat([obj.s_status; "none"], n, 1), repmat(obj.r_point, 2*n, 1), ...
                'VariableNames', ["Tag","Target","Time","Status","Point"]);
end
