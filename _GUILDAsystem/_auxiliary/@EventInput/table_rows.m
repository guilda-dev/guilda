function tab = table_rows(obj)
% Row of tab_input: (Tag, TimeSpan, InputUnit, InputName, InputValue, InputMethod).
    arguments (Input)
        obj
    end
    arguments (Output)
        tab table  % One row.
    end
    tab = table(obj.s_tag, obj.rr_time, obj.s_unit, {obj.sv_name}, {obj.rm_value}, obj.s_method, ...
                'VariableNames', ["Tag","TimeSpan","InputUnit","InputName","InputValue","InputMethod"]);
end
