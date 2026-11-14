function sa_file = read_scenarios(path)
% Read and check the files scenario/*.json of a model folder (PowerNetwork.import).
%
% The files are read in the order of their names, before the network changes. A file that
% is not JSON, has no Format "GUILDAscenario", a version other than 2 (version 1 is no
% longer read), a wrong Time or Description, an Event row without Tag, Target, Time or
% Status or with a Tag other than Fault or Parallel followed by digits, an Offset or Input
% row without Tag, a Tag twice in Offset or in Input, or an offset and an input of one tag
% that start at different times stops with GUILDA:PowerNetwork:ScenarioJson. Unknown
% fields give the warning GUILDA:PowerNetwork:UnknownScenarioField and are removed. The
% Event rows are returned with the five fields of tab_event (Point NaN when missing). The
% values of the disturbances are checked when they are added
% (Scenario.add_from_json_struct).
    arguments (Input)
        path (1,1) string   % Model folder.
    end
    arguments (Output)
        sa_file (:,1) struct   % One per file: s_tag (file name), s_file and sct (Event, Offset and Input as cells).
    end
    sa_file = struct("s_tag", cell(0,1), "s_file", cell(0,1), "sct", cell(0,1));
    s_dir = fullfile(path, "scenario");
    if ~isfolder(s_dir)
        return
    end
    sv_name = sort(string({dir(fullfile(s_dir, "*.json")).name}));
    sr_top  = ["Format", "version", "Description", "Time", "Event", "Offset", "Input"];
    sr_event = ["Tag", "Target", "Time", "Status", "Point"];
    sr_part  = ["Tag", "TimeSpan", Scenario.sr_field];
    for s_name = sv_name
        s_file = fullfile(s_dir, s_name);
        try
            sct = jsondecode(fileread(s_file));
        catch ME
            error(msg("GUILDA:PowerNetwork:ScenarioJson", s_file, ME.message));
        end
        if ~isstruct(sct) || ~isscalar(sct)
            error(msg("GUILDA:PowerNetwork:ScenarioJson", s_file, "the file is not one JSON object"));
        end
        if ~isfield(sct, "Format") || ~is_text(sct.Format) || string(sct.Format) ~= "GUILDAscenario"
            error(msg("GUILDA:PowerNetwork:ScenarioJson", s_file, "Format is not ""GUILDAscenario"""));
        end
        if ~isfield(sct, "version") || ~(isnumeric(sct.version) && isscalar(sct.version))
            error(msg("GUILDA:PowerNetwork:ScenarioJson", s_file, "version is not a number"));
        end
        if sct.version > 2
            error(msg("GUILDA:PowerNetwork:ScenarioJson", s_file, "version " + sct.version + " is newer than this GUILDA reads (2)"));
        end
        if sct.version == 1
            error(msg("GUILDA:PowerNetwork:ScenarioJson", s_file, "version 1 (Disturbances) is no longer read; " + ...
                      "make the scenario again with add_fault, add_trip, add_open_branch, add_offset and add_input, and write it with net.export"));
        end
        if sct.version ~= 2
            error(msg("GUILDA:PowerNetwork:ScenarioJson", s_file, "version " + sct.version + " is not 2"));
        end
        sct = drop_unknown(sct, sr_top, s_file, "");
        if isfield(sct, "Time") && ~(isnumeric(sct.Time) && numel(sct.Time) == 2)
            error(msg("GUILDA:PowerNetwork:ScenarioJson", s_file, "Time is not [t0, tend]"));
        end
        if isfield(sct, "Description") && ~is_text(sct.Description)
            error(msg("GUILDA:PowerNetwork:ScenarioJson", s_file, "Description is not text"));
        end
        for s_part = ["Event", "Offset", "Input"]
            if ~isfield(sct, s_part)
                continue
            end
            c_row = sct.(s_part);
            if isstruct(c_row)
                c_row = num2cell(c_row(:).');      % jsondecode joins objects with the same fields
            elseif isempty(c_row)
                c_row = cell(1, 0);
            end
            if ~iscell(c_row) || ~all(cellfun(@(e) isstruct(e) && isscalar(e), c_row))
                error(msg("GUILDA:PowerNetwork:ScenarioJson", s_file, s_part + " is not an array of objects"));
            end
            for k = 1:numel(c_row)
                s_row = s_part + "(" + k + ")";
                if s_part == "Event"
                    e = drop_unknown(c_row{k}, sr_event, s_file, s_row + ".");
                    if ~all(isfield(e, ["Tag", "Target", "Time", "Status"])) || ~is_text(e.Tag) ...
                            || ~is_text(e.Target) || ~is_text(e.Status) || ~(isnumeric(e.Time) && isscalar(e.Time))
                        error(msg("GUILDA:PowerNetwork:ScenarioJson", s_file, s_row + " needs Tag, Target and Status (text) and Time (a number)"));
                    end
                    if ~matches(string(e.Tag), ["Fault", "Parallel"] + digitsPattern)
                        error(msg("GUILDA:PowerNetwork:ScenarioJson", s_file, "the Tag """ + string(e.Tag) + """ of " + s_row + ...
                                  " is not Fault or Parallel followed by digits"));
                    end
                    point = NaN;
                    if isfield(e, "Point") && isnumeric(e.Point) && isscalar(e.Point)
                        point = double(e.Point);
                    end
                    c_row{k} = struct("Tag", string(e.Tag), "Target", string(e.Target), "Time", double(e.Time), ...
                                      "Status", string(e.Status), "Point", point);
                    continue
                end
                e = drop_unknown(c_row{k}, sr_part, s_file, s_row + ".");
                if ~isfield(e, "Tag") || ~is_text(e.Tag)
                    error(msg("GUILDA:PowerNetwork:ScenarioJson", s_file, s_row + " has no Tag"));
                end
                if isfield(e, "InputValue") && isstruct(e.InputValue)
                    e.InputValue = drop_unknown(e.InputValue, ["Time", "Value"], s_file, s_row + ".InputValue.");
                    if ~all(isfield(e.InputValue, ["Time", "Value"]))
                        error(msg("GUILDA:PowerNetwork:ScenarioJson", s_file, "the time series InputValue of " + s_row + " needs Time and Value"));
                    end
                end
                c_row{k} = e;
            end
            if s_part ~= "Event"
                sv_tag = string(cellfun(@(e) e.Tag, c_row, 'UniformOutput', false));
                if numel(unique(sv_tag)) < numel(sv_tag)
                    error(msg("GUILDA:PowerNetwork:ScenarioJson", s_file, s_part + " has a Tag more than once"));
                end
            end
            sct.(s_part) = c_row;
        end
        % An offset and an input with one tag start at the same time (add_disturbance)
        if isfield(sct, "Offset") && isfield(sct, "Input")
            for e = sct.Offset
                c_in = sct.Input(cellfun(@(x) string(x.Tag) == string(e{1}.Tag), sct.Input));
                if ~isempty(c_in) && isfield(e{1}, "TimeSpan") && isfield(c_in{1}, "TimeSpan") ...
                        && double(e{1}.TimeSpan(1)) ~= double(c_in{1}.TimeSpan(1))
                    error(msg("GUILDA:PowerNetwork:ScenarioJson", s_file, "the offset and the input """ + string(e{1}.Tag) + ...
                              """ start at different times; give them different tags"));
                end
            end
        end
        sa_file(end+1, 1) = struct("s_tag", extractBefore(s_name, strlength(s_name) - 4), ...
                                   "s_file", s_file, "sct", sct); %#ok<AGROW>
    end
end

function sct = drop_unknown(sct, sr_known, s_file, s_prefix)
    sv_field   = string(fieldnames(sct)).';
    sv_unknown = sv_field(~ismember(sv_field, sr_known));
    if ~isempty(sv_unknown)
        show_msg("warning", "GUILDA:PowerNetwork:UnknownScenarioField", s_file, ...
                 join(s_prefix + sv_unknown, ", "), join(sr_known, ", "));
        sct = rmfield(sct, cellstr(sv_unknown));
    end
end

function l = is_text(x)
    l = (ischar(x) && (isrow(x) || isempty(x))) || (isstring(x) && isscalar(x));
end
