function s_file = Export(obj, filename)
% Write the PV-curve path to a table file.
%
% Writes the path (tab_path: lambda, then V_<bus> and Varg_<bus> of each bus, one row per
% point) to a CSV or Excel file. The format follows the extension of filename (.csv,
% .txt, .xlsx, .xls). A relative filename is relative to the current folder.
% calculate_continuation_powerflow(..., Export=filename) calls it.
    arguments (Input)
        obj
        filename (1,1) string = string(datetime("now","Format","uuMMdd_HHmmss")) + "_CPF.csv" % Output file; its extension selects the format.
    end
    arguments (Output)
        s_file % Path of the written file.
    end
    s_file = filename;
    [~, ~, s_ext] = fileparts(s_file);

    switch lower(s_ext)
        case {".csv", ".txt", ".xlsx", ".xls"}
            writetable(obj.tab_path, s_file);
        otherwise
            error(msg("GUILDA:ResultCPF:ExportFormat", char(s_ext)));
    end
end
