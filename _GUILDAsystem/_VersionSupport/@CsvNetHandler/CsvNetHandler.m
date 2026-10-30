classdef CsvNetHandler < auxiliary
% v3 CSV import and export of networks (static methods only).
%
% The methods are wrappers of the v4 API and warn GUILDA:Deprecated:CsvNetHandlerImport
% or GUILDA:Deprecated:CsvNetHandlerExport:
%
% - `CsvNetHandler.import(path, net, Initialize=tf)` calls
%   `PowerNetwork.import_csv(path, Network=net, Initialize=tf)`
% - `CsvNetHandler.export(net, ModelName, savepath=d)` calls
%   `net.export_csv(fullfile(d, "@"+ModelName))`
%
% <@Examples>
% ```matlab
% net = CsvNetHandler.import(path);
% ```
%
% <@Deprecated>
% Use PowerNetwork.import_csv and net.export_csv instead.
%
% See also PowerNetwork.import_csv, PowerNetwork.export_csv

    methods(Static)
        net  = import(path, net, opt)
        path = export(net, ModelName, opt)
    end

end
