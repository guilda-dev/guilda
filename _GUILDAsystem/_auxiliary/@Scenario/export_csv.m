function path = export_csv(path, scenarios, opt)
% Write scenarios to one CSV file that Scenario.import_csv reads back.
%
% One row per disturbance; a scenario without disturbances has one row with its own
% columns only. The columns (see import_csv): Scenario, Description, ScenarioTimeStart,
% ScenarioTimeEnd (the Time of the scenario, repeated on its rows), Tag, TimeStart, TimeEnd
% (empty for an offset at one time), FaultBus, TripUnit, OpenBranch, OffsetUnit, OffsetState,
% OffsetValue, InputUnit, InputName, InputValue. A list is written as its elements separated
% by ";" (e.g. EL003;EL004), and numbers with the digits that read back the same double.
% A cell of numbers in InputValue is written as numbers. A function handle in InputValue
% cannot be written and stops with GUILDA:Scenario:CsvFunctionHandle before the file is
% written. A Judge other than the default is not saved; the warning
% GUILDA:Scenario:CsvNotSaved names it. An existing file is an error unless Overwrite=true.
%
% <@Examples>
% ```matlab
% s_file = Scenario.export_csv(fullfile(tempdir, "cases.csv"), net.a_Scenario, Overwrite=true);
% c_sc = Scenario.import_csv(s_file);
% ```
%
% See also Scenario.import_csv, PowerNetwork.export_csv
    arguments (Input)
        path (1,1) string          % CSV file to write.
        scenarios                  % Scenario or cell of Scenario objects (e.g. net.a_Scenario).
        opt.Overwrite (1,1) logical = false % Replace an existing file.
    end
    arguments (Output)
        path % The written file.
    end
    if ~iscell(scenarios)
        scenarios = {scenarios};
    end
    if ~all(cellfun(@(s) isa(s, "Scenario") && isscalar(s), scenarios))
        error(msg("GUILDA:Scenario:CsvNotScenario"));
    end
    if isfile(path) && ~opt.Overwrite
        error(msg("GUILDA:Scenario:CsvFileExists", char(path)));
    end

    sr_col = ["Scenario","Description","ScenarioTimeStart","ScenarioTimeEnd","Tag","TimeStart","TimeEnd", ...
              "FaultBus","TripUnit","OpenBranch","OffsetUnit","OffsetState","OffsetValue", ...
              "InputUnit","InputName","InputValue"];
    sm = strings(0, numel(sr_col));
    for i = 1:numel(scenarios)
        sc = scenarios{i};
        if ~strcmp(func2str(sc.Judge), "Scenario.out_of_step")
            show_msg("warning", "GUILDA:Scenario:CsvNotSaved", char(sc.s_tag), "Judge");
        end
        rv_head = [sc.s_tag, sc.Description, strings(1,2)];
        if ~isempty(sc.Time)
            rv_head(3:4) = [num2text(sc.Time(1)), num2text(sc.Time(2))];
        end
        tab = sc.tab_disturbance;
        if height(tab) == 0
            sm(end+1,:) = [rv_head, strings(1, numel(sr_col)-4)]; %#ok<AGROW>
        end
        for k = 1:height(tab)
            d = Scenario.record(tab, k);
            ts = d.TimeSpan;
            s_te = num2text(ts(2));
            if ts(1) == ts(2)
                s_te = "";
            end
            sm(end+1,:) = [rv_head, d.Tag, num2text(ts(1)), s_te, list2text(d.FaultBus), ...
                           list2text(d.TripUnit), list2text(d.OpenBranch), d.OffsetUnit, ...
                           list2text(d.OffsetState), list2text(num2text(d.OffsetValue)), d.InputUnit, ...
                           list2text(d.InputName), value2text(d.InputValue, d.Tag, sc.s_tag)]; %#ok<AGROW>
        end
    end
    tab_out = array2table(sm, "VariableNames", sr_col);
    writetable(tab_out, path, "QuoteStrings", "minimal");
end


function str = list2text(sv)
    if isempty(sv)
        str = "";
    else
        str = join(string(sv(:)).', ";");
    end
end

function sv = num2text(rv)
% Shortest text that reads back the same double
    sv = strings(size(rv));
    for k = 1:numel(rv)
        sv(k) = sprintf("%.15g", rv(k));
        if str2double(sv(k)) ~= rv(k) && ~isnan(rv(k))
            sv(k) = sprintf("%.17g", rv(k));
        end
    end
end

function str = value2text(val, s_tag, s_scenario)
    if isa(val, "function_handle") || (iscell(val) && any(cellfun(@(v) isa(v, "function_handle"), val)))
        error(msg("GUILDA:Scenario:CsvFunctionHandle", char(s_tag), char(s_scenario)));
    end
    if iscell(val)
        val = vertcat(zeros(0,1), val{:});
    end
    str = list2text(num2text(val));
end
