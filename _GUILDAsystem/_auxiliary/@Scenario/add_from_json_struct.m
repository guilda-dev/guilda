function add_from_json_struct(obj, sct)
% Set Time and Description and add the disturbances read from scenario/<tag>.json.
%
% sct is the decoded file after the checks of PowerNetwork.import (Format, version 2, known
% fields; Event as a cell of structs Tag, Target, Time, Status, Point; Offset and Input as
% cells of structs, a tag at most once in each). The rows of Event are added with
% their tags by add_events, the offsets and inputs by add_record (an offset and an input
% with one tag as one record), so they are checked against the network as when added by
% hand; a failing row stops with the error of the check.
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
    if isfield(sct, "Event") && ~isempty(sct.Event)
        obj.add_events(struct2table(vertcat(sct.Event{:}), "AsArray", true));
    end
    % Offsets and inputs: one record per tag
    c_row = cell(1, 0);
    for s_part = ["Offset", "Input"]
        if isfield(sct, s_part)
            c_row = [c_row, reshape(sct.(s_part), 1, [])]; %#ok<AGROW>
        end
    end
    sv_tag = string(cellfun(@(e) e.Tag, c_row, 'UniformOutput', false));
    for s_tag = unique(sv_tag, "stable")
        d = struct("Tag", s_tag);
        for e = c_row(sv_tag == s_tag)
            for s_name = setdiff(string(fieldnames(e{1})).', "Tag", "stable")
                val = e{1}.(s_name);
                switch s_name
                    case "TimeSpan"
                        val = reshape(double(val), 1, []);
                    case {"OffsetState", "InputName"}
                        val = reshape(string(val), [], 1);
                    case {"OffsetUnit", "InputUnit", "InputMethod"}
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
                if s_name == "TimeSpan" && isfield(d, "TimeSpan") && numel(d.TimeSpan) > numel(val)
                    continue        % the input's [t_start, t_end] over the offset's t_start
                end
                d.(s_name) = val;
            end
        end
        if ~isfield(d, "TimeSpan")
            d.TimeSpan = [0, 10];
        end
        obj.add_record(d, "");
    end
end
