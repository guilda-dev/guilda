function str_file = Export(obj, filename, opt)
% <@Desc>
% Writes a table of the result to a CSV (.csv, .txt) or Excel (.xlsx, .xls) file, with
% the row names in the first column and phasors as complex numbers: the bus table
% (tab_bus), or with Table="cub" the connection table (tab_cub), or with Table="branch"
% the branch table (tab_branch). A relative filename is relative to the current folder.
% optimize_powerflow(..., Export=filename) calls it.
% <@Role> Export
% <@Summary> Write the bus, connection or branch table to a file.
% <@Signatures>
% [
%   "str_file = Export(result)",
%   "str_file = Export(result, filename)",
%   "str_file = Export(result, filename, Table=\"branch\")"
% ]
% <@Parameters>
% [
%   {"Name": "result", "Type": "OPFResult", "Description": "Result to write.", "Required": true, "Default": "-"},
%   {"Name": "filename", "Type": "string scalar", "Description": "Output file; its extension selects the format.", "Required": false, "Default": "\"<yyMMdd_HHmmss>_OPF.csv\""},
%   {"Name": "Table", "Type": "\"bus\" | \"cub\" | \"branch\"", "Description": "Table to write.", "Required": false, "Default": "\"bus\""}
% ]
% <@Returns>
% [
%   {"Name": "str_file", "Type": "string scalar", "Description": "Path of the written file."}
% ]
    arguments
        obj
        filename  (1,1) string = string(datetime("now","Format","uuMMdd_HHmmss")) + "_OPF.csv"
        opt.Table (1,1) string {mustBeMember(opt.Table,["bus","cub","branch"])} = "bus"
    end
    str_file = filename;
    [~, ~, str_ext] = fileparts(str_file);

    switch lower(str_ext)
        case {".csv", ".txt", ".xlsx", ".xls"}
            tab = obj.("tab_" + opt.Table);
            writetable(tab, str_file, "WriteRowNames", true);
        otherwise
            error('GUILDA:OPFResult:ExportFormat', '%s', ...
                  msg('GUILDA:OPFResult:ExportFormat', char(str_ext)));
    end
end
