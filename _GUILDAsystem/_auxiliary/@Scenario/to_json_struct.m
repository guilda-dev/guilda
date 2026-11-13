function sct = to_json_struct(obj)
% Content of the file scenario/<tag>.json written by net.export.
%
% Fields: Format ("GUILDAscenario"), version (2), Description, Time, and Event, Offset and
% Input: one object per row of tab_event, tab_offset and tab_input with the column names
% as fields; an empty table, and empty fields of Offset and Input, are left out. Lists
% are cells, so that jsonencode writes an array also for one element. A constant
% InputValue is an array of numbers; a time series is an object with Time (since t_start)
% and Value (one array per point), and its interpolation is InputMethod. The tag of the
% scenario is the file name only.
    arguments (Input)
        obj
    end
    arguments (Output)
        sct (1,1) struct   % Struct for jsonencode.
    end
    sct = struct("Format", "GUILDAscenario", "version", 2, "Description", obj.Description, ...
                 "Time", {num2cell(obj.Time)});
    tab = obj.tab_event;
    if height(tab) > 0
        sct.Event = num2cell(table2struct(tab).');
    end
    for c_part = {"Offset", obj.tab_offset; "Input", obj.tab_input}.'
        tab = c_part{2};
        if height(tab) == 0
            continue
        end
        c_row = cell(1, height(tab));
        for k = 1:height(tab)
            d = get_record(tab, k);
            e = struct("Tag", d.Tag, "TimeSpan", {num2cell(tab.TimeSpan(k,:))});
            for s_name = string(tab.Properties.VariableNames(3:end))
                val = d.(s_name);
                if isempty(val) || (isstring(val) && isscalar(val) && val == "")
                    continue
                end
                if s_name == "InputValue" && d.InputMethod ~= ""
                    % time series [t, v_1, ..., v_n]: one array per point
                    val = struct("Time", {num2cell(val(:,1).')}, ...
                                 "Value", {arrayfun(@(i) num2cell(val(i,2:end)), 1:size(val,1), 'UniformOutput', false)});
                elseif ismember(s_name, ["OffsetState", "InputName"])
                    val = cellstr(val(:).');
                elseif isnumeric(val)
                    val = num2cell(val(:).');
                end
                e.(s_name) = val;
            end
            c_row{k} = e;
        end
        sct.(c_part{1}) = c_row;
    end
end
