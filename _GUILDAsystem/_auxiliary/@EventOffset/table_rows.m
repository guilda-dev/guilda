function tab = table_rows(obj)
% Row of tab_offset: (Tag, TimeSpan, OffsetUnit, OffsetState, OffsetValue).
    arguments (Input)
        obj
    end
    arguments (Output)
        tab table  % One row.
    end
    tab = table(obj.s_tag, obj.r_time, obj.s_unit, {obj.sv_state}, {obj.rv_value}, ...
                'VariableNames', ["Tag","TimeSpan","OffsetUnit","OffsetState","OffsetValue"]);
end
