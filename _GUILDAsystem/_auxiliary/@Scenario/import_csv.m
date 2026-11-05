function c_scenario = import_csv(path, opt)
% Read scenarios from a CSV file, one row per disturbance.
%
% The file may hold several scenarios: the rows with the same Scenario tag form one
% scenario, in the order of their first rows. Columns (only Scenario is required; a missing
% column or an empty value is empty):
%
% - `Scenario` — tag of the scenario.
% - `Description`, `ScenarioTimeStart`, `ScenarioTimeEnd` — Description and Time of the
%   scenario ([] when both times are empty). Give them on one row of the scenario, or the
%   same value on each row.
% - `Tag` — tag of the disturbance; empty for event<n>. A row with no Tag, time and
%   disturbance column gives no disturbance (a scenario without disturbances).
% - `TimeStart`, `TimeEnd` — [s] TimeSpan of the disturbance; TimeEnd empty for an offset at
%   one time.
% - `FaultBus`, `TripUnit`, `OpenBranch`, `OffsetState`, `InputName` — lists of tags or names
%   separated by ";" (e.g. EL003;EL004).
% - `OffsetUnit`, `InputUnit` — one component tag.
% - `OffsetValue`, `InputValue` — numbers separated by ";". Functions cannot be given.
%
% The disturbances are checked as in add_disturbance. With Network=net the scenarios are
% added to net (net.add_scenario), which checks their tags against it first: nothing is
% added when a check fails. An unknown column gives the warning
% GUILDA:Scenario:CsvUnknownColumn and is ignored. Options and Judge are not in the file
% (the defaults are used).
%
% <@Examples>
% ```matlab
% c_sc = Scenario.import_csv("cases.csv", Network=net);   % added to net
% for k = 1:numel(c_sc)
%     result  = net.simulate(c_sc{k});
%     verdict = c_sc{k}.judge(result);
% end
% ```
%
% See also Scenario.export_csv, PowerNetwork.add_scenario, PowerNetwork.import_csv
    arguments (Input)
        path (1,1) string   % CSV file (e.g. written by Scenario.export_csv).
        opt.Network = []    % Network to add the scenarios to; [] leaves them unattached.
    end
    arguments (Output)
        c_scenario (:,1) cell % The scenarios (Scenario objects), in the order of the file.
    end
    if ~isfile(path)
        error(msg("GUILDA:Scenario:CsvNotFound", char(path)));
    end
    if ~isempty(opt.Network) && ~(isa(opt.Network, "PowerNetwork") && isscalar(opt.Network))
        error(msg("GUILDA:Scenario:CsvInvalidNetwork", class(opt.Network)));
    end
    o = detectImportOptions(path, "Delimiter", ",", "VariableNamingRule", "preserve", "TextType", "string");
    o = setvartype(o, o.VariableNames, "string");
    tab = readtable(path, o);

    sv_col = ["Scenario","Description","ScenarioTimeStart","ScenarioTimeEnd","Tag","TimeStart","TimeEnd", ...
              "FaultBus","TripUnit","OpenBranch","OffsetUnit","OffsetState","OffsetValue", ...
              "InputUnit","InputName","InputValue"];
    sv_in = string(tab.Properties.VariableNames);
    if ~ismember("Scenario", sv_in)
        error(msg("GUILDA:Scenario:CsvMissingColumn", char(path)));
    end
    sv_unknown = setdiff(sv_in, sv_col, "stable");
    if ~isempty(sv_unknown)
        warning(msg("GUILDA:Scenario:CsvUnknownColumn", char(path), char(join(sv_unknown, ", "))));
    end
    n_row = height(tab);
    for str_col = sv_col
        if ismember(str_col, sv_in)
            x = strip(tab.(str_col));
            x(ismissing(x)) = "";
            tab.(str_col) = x;
        else
            tab.(str_col) = strings(n_row, 1);
        end
    end

    sv_sc = unique(tab.Scenario, "stable");
    c_scenario = cell(numel(sv_sc), 1);
    for i = 1:numel(sv_sc)
        iv_row = find(tab.Scenario == sv_sc(i));
        sc = Scenario(sv_sc(i));
        sc.Description = one_value(tab, iv_row, "Description", sv_sc(i), path);
        str_t0 = one_value(tab, iv_row, "ScenarioTimeStart", sv_sc(i), path);
        str_t1 = one_value(tab, iv_row, "ScenarioTimeEnd", sv_sc(i), path);
        if str_t0 ~= "" || str_t1 ~= ""
            sc.Time = [to_numbers(str_t0, iv_row(1), "ScenarioTimeStart", path), ...
                       to_numbers(str_t1, iv_row(1), "ScenarioTimeEnd", path)];
        end
        for r = iv_row(:).'
            if all(tab{r, sv_col(5:end)} == "")
                continue        % a row of the scenario only
            end
            rv_ts = to_numbers(tab.TimeStart(r), r, "TimeStart", path);
            if ~isscalar(rv_ts)
                error(msg("GUILDA:Scenario:CsvInvalidValue", string(r), char(path), "TimeStart", char(tab.TimeStart(r))));
            end
            if tab.TimeEnd(r) ~= ""
                rv_ts = [rv_ts, to_numbers(tab.TimeEnd(r), r, "TimeEnd", path)]; %#ok<AGROW>
            end
            d = Scenario.blank(tab.Tag(r), rv_ts);
            d.FaultBus    = to_list(tab.FaultBus(r));
            d.TripUnit    = to_list(tab.TripUnit(r));
            d.OpenBranch  = to_list(tab.OpenBranch(r));
            d.OffsetUnit  = tab.OffsetUnit(r);
            d.OffsetState = to_list(tab.OffsetState(r));
            d.OffsetValue = to_numbers(tab.OffsetValue(r), r, "OffsetValue", path);
            d.InputUnit   = tab.InputUnit(r);
            d.InputName   = to_list(tab.InputName(r));
            d.InputValue  = to_numbers(tab.InputValue(r), r, "InputValue", path);
            sc.add_checked(d);
        end
        c_scenario{i} = sc;
    end

    if ~isempty(opt.Network)
        opt.Network.add_scenario(c_scenario);
    end
end


function str = one_value(tab, iv_row, str_col, str_scenario, path)
% The value of a scenario column: the same on every row that gives it
    sv = unique(tab.(str_col)(iv_row), "stable");
    sv = sv(sv ~= "");
    if numel(sv) > 1
        error(msg("GUILDA:Scenario:CsvConflict", char(str_scenario), char(path), char(str_col)));
    end
    str = "";
    if ~isempty(sv)
        str = sv;
    end
end

function sv = to_list(str)
    sv = strings(0,1);
    if str ~= ""
        sv = strip(split(str, ";"));
    end
end

function rv = to_numbers(str, r, str_col, path)
    rv = zeros(0,1);
    if str == ""
        return
    end
    sv = strip(split(str, ";"));
    rv = str2double(sv);
    if any(isnan(rv) & ~strcmpi(sv, "NaN"))
        error(msg("GUILDA:Scenario:CsvInvalidValue", string(r), char(path), char(str_col), char(str)));
    end
end
