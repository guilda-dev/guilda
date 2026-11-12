function tab = rows_to_table(c_row)
% Violation table from the rows {Class, Object, Limit, [Value, Bound]}; 0 rows with the
% same columns when c_row is empty
    arguments (Input)
        c_row cell = cell(0,4)  % One row per violated limit.
    end
    arguments (Output)
        tab table               % Columns Class, Object, Limit, Value, Bound, Excess.
    end
    rm_val = reshape(cell2mat(c_row(:,4)), [], 2);
    tab = table(string(c_row(:,1)), string(c_row(:,2)), string(c_row(:,3)), rm_val(:,1), rm_val(:,2), ...
                abs(rm_val(:,1) - rm_val(:,2)), ...
                'VariableNames', ["Class","Object","Limit","Value","Bound","Excess"]);
end
