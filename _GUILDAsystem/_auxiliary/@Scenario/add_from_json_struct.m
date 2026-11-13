function add_from_json_struct(obj, sct)
% Set Time and Description and add the disturbances read from scenario/<tag>.json.
%
% sct is the decoded file after the checks of PowerNetwork.import (Format, version, known
% fields; Disturbances as a cell of structs). Each disturbance is added by add_disturbance
% with its fields as the options, so it is checked against the network as when added by
% hand, and a failing disturbance stops with the error of add_disturbance.
    arguments (Input)
        obj
        sct (1,1) struct      % Decoded content of the file (see to_json_struct).
    end
    if isfield(sct, "Time")
        obj.Time = reshape(double(sct.Time), 1, []);
    end
    if isfield(sct, "Description")
        obj.Description = string(sct.Description);
    end
    if ~isfield(sct, "Disturbances")
        return
    end
    for k = 1:numel(sct.Disturbances)
        e = sct.Disturbances{k};
        s_tag = string(e.Tag);
        c_nv = cell(1, 0);
        for s_name = setdiff(string(fieldnames(e)).', "Tag", "stable")
            c_nv = [c_nv, {s_name, json_value(e.(s_name), s_name)}]; %#ok<AGROW>
        end
        obj.add_disturbance(s_tag, c_nv{:});
    end
end


function val = json_value(val, s_name)
% Value of an add_disturbance option from its decoded JSON value
    switch s_name
        case "TimeSpan"
            val = reshape(double(val), 1, []);
        case ["FaultBus", "TripUnit", "OpenBranch", "OffsetState", "InputName"]
            val = reshape(string(val), [], 1);
        case ["OffsetUnit", "InputUnit", "InputMethod"]
            val = string(val);
        case "OffsetValue"
            val = reshape(double(val), [], 1);
        case "InputValue"
            if isstruct(val)
                rv_t = reshape(double(val.Time), [], 1);
                rm_v = double(val.Value);
                if size(rm_v, 1) ~= numel(rv_t) && isvector(rm_v)
                    rm_v = reshape(rm_v, numel(rv_t), []);   % one point: jsondecode gives a column
                end
                val = [rv_t, rm_v];
            else
                val = reshape(double(val), [], 1);
            end
    end
end
