function str_file = Export(obj, filename)
% <@Desc>
% Writes the path (tab_path: lambda, then V_<bus> and Varg_<bus> of each bus, one row per
% point) to a CSV or Excel file. The format follows the extension of filename (.csv,
% .txt, .xlsx, .xls). A relative filename is relative to the current folder.
% calculate_continuation_powerflow(..., Export=filename) calls it.
% <@Role> Export
% <@Summary> Write the PV-curve path to a table file.
% <@Signatures>
% [
%   "str_file = Export(result)",
%   "str_file = Export(result, filename)"
% ]
% <@Parameters>
% [
%   {"Name": "result", "Type": "CPFResult", "Description": "Result to write.", "Required": true, "Default": "-"},
%   {"Name": "filename", "Type": "string scalar", "Description": "Output file; its extension selects the format.", "Required": false, "Default": "\"<yyMMdd_HHmmss>_CPF.csv\""}
% ]
% <@Returns>
% [
%   {"Name": "str_file", "Type": "string scalar", "Description": "Path of the written file."}
% ]
    arguments
        obj
        filename (1,1) string = string(datetime("now","Format","uuMMdd_HHmmss")) + "_CPF.csv"
    end
    str_file = filename;
    [~, ~, str_ext] = fileparts(str_file);

    switch lower(str_ext)
        case {".csv", ".txt", ".xlsx", ".xls"}
            writetable(obj.tab_path, str_file);
        otherwise
            error('GUILDA:CPFResult:ExportFormat', '%s', ...
                  msg('GUILDA:CPFResult:ExportFormat', char(str_ext)));
    end
end
