function sa_file = read_scenarios(path)
% Read and check the files scenario/*.json of a model folder (PowerNetwork.import).
%
% The files are read in the order of their names, before the network changes. A file that
% is not JSON, has no Format "GUILDAscenario", a version above 1, a wrong Time or
% Description, or a disturbance without Tag stops with GUILDA:PowerNetwork:ScenarioJson.
% Unknown fields (such as Judge of older files) give the warning
% GUILDA:PowerNetwork:UnknownScenarioField and are removed. The values of the disturbances
% are checked when they are added (Scenario.add_from_json_struct).
    arguments (Input)
        path (1,1) string   % Model folder.
    end
    arguments (Output)
        sa_file (:,1) struct   % One per file: s_tag (file name), s_file and sct (Disturbances as a cell).
    end
    sa_file = struct("s_tag", cell(0,1), "s_file", cell(0,1), "sct", cell(0,1));
    s_dir = fullfile(path, "scenario");
    if ~isfolder(s_dir)
        return
    end
    sv_name = sort(string({dir(fullfile(s_dir, "*.json")).name}));
    sr_top  = ["Format", "version", "Description", "Time", "Disturbances"];
    sr_dist = ["Tag", "TimeSpan", Scenario.sr_field];
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
        sct = drop_unknown(sct, sr_top, s_file, "");
        if ~isfield(sct, "Format") || ~is_text(sct.Format) || string(sct.Format) ~= "GUILDAscenario"
            error(msg("GUILDA:PowerNetwork:ScenarioJson", s_file, "Format is not ""GUILDAscenario"""));
        end
        if ~isfield(sct, "version") || ~(isnumeric(sct.version) && isscalar(sct.version))
            error(msg("GUILDA:PowerNetwork:ScenarioJson", s_file, "version is not a number"));
        end
        if sct.version > 1
            error(msg("GUILDA:PowerNetwork:ScenarioJson", s_file, "version " + sct.version + " is newer than this GUILDA reads (1)"));
        end
        if isfield(sct, "Time") && ~(isnumeric(sct.Time) && numel(sct.Time) == 2)
            error(msg("GUILDA:PowerNetwork:ScenarioJson", s_file, "Time is not [t0, tend]"));
        end
        if isfield(sct, "Description") && ~is_text(sct.Description)
            error(msg("GUILDA:PowerNetwork:ScenarioJson", s_file, "Description is not text"));
        end
        c_dist = cell(1, 0);
        if isfield(sct, "Disturbances")
            c_dist = sct.Disturbances;
            if isstruct(c_dist)
                c_dist = num2cell(c_dist(:).');      % jsondecode joins objects with the same fields
            elseif isempty(c_dist)
                c_dist = cell(1, 0);
            end
            if ~iscell(c_dist) || ~all(cellfun(@(e) isstruct(e) && isscalar(e), c_dist))
                error(msg("GUILDA:PowerNetwork:ScenarioJson", s_file, "Disturbances is not an array of objects"));
            end
            for k = 1:numel(c_dist)
                e = drop_unknown(c_dist{k}, sr_dist, s_file, "Disturbances(" + k + ").");
                if ~isfield(e, "Tag") || ~is_text(e.Tag)
                    error(msg("GUILDA:PowerNetwork:ScenarioJson", s_file, "Disturbances(" + k + ") has no Tag"));
                end
                if isfield(e, "InputValue") && isstruct(e.InputValue)
                    e.InputValue = drop_unknown(e.InputValue, ["Time", "Value"], s_file, "Disturbances(" + k + ").InputValue.");
                    if ~all(isfield(e.InputValue, ["Time", "Value"]))
                        error(msg("GUILDA:PowerNetwork:ScenarioJson", s_file, "the time series InputValue of Disturbances(" + k + ") needs Time and Value"));
                    end
                end
                c_dist{k} = e;
            end
        end
        sct.Disturbances = c_dist;
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
