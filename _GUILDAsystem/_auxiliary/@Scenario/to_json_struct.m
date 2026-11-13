function sct = to_json_struct(obj)
% Content of the file scenario/<tag>.json written by net.export.
%
% Fields: Format ("GUILDAscenario"), version, Description, Time and Disturbances, one
% struct per row of tab_disturbance with the names of the add_disturbance options (Tag,
% TimeSpan, FaultBus, ...); empty fields are left out. Lists are cells, so that jsonencode
% writes an array also for one element. A constant InputValue is an array of numbers; a
% time series is a struct with Time (since t_start) and Value (one array per point), and
% its interpolation is InputMethod. The tag of the scenario is the file name only.
    arguments (Input)
        obj
    end
    arguments (Output)
        sct (1,1) struct   % Struct for jsonencode.
    end
    tab = obj.tab_disturbance;
    c_dist = cell(1, height(tab));
    for k = 1:height(tab)
        d = Scenario.record(tab, k);
        e = struct("Tag", d.Tag);
        rv_ts = d.TimeSpan;
        if rv_ts(1) == rv_ts(2)
            rv_ts = rv_ts(1);      % an offset at one time
        end
        e.TimeSpan = num2cell(rv_ts);
        for s_name = ["FaultBus", "TripUnit", "OpenBranch", "OffsetUnit", "OffsetState", ...
                      "OffsetValue", "InputUnit", "InputName", "InputValue", "InputMethod"]
            val = d.(s_name);
            if isempty(val) || (isstring(val) && isscalar(val) && val == "")
                continue
            end
            if s_name == "InputValue" && d.InputMethod ~= ""
                % time series [t, v_1, ..., v_n]: one array per point
                val = struct("Time", {num2cell(val(:,1).')}, ...
                             "Value", {arrayfun(@(i) num2cell(val(i,2:end)), 1:size(val,1), 'UniformOutput', false)});
            elseif isstring(val) && ~isscalar(val) || ismember(s_name, ["FaultBus", "TripUnit", "OpenBranch", "OffsetState", "InputName"])
                val = cellstr(val(:).');
            elseif isnumeric(val)
                val = num2cell(val(:).');
            end
            e.(s_name) = val;
        end
        c_dist{k} = e;
    end
    sct = struct("Format", "GUILDAscenario", "version", 1, "Description", obj.Description, ...
                 "Time", {num2cell(obj.Time)}, "Disturbances", {c_dist});
end
