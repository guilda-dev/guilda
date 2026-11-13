classdef CsvNetHandler < auxiliary
% v3 CSV import and export of networks (static methods only).
%
% The methods are wrappers of the v4 API and warn GUILDA:Deprecated:CsvNetHandlerImport
% or GUILDA:Deprecated:CsvNetHandlerExport:
%
% - `CsvNetHandler.import(path, net, Initialize=tf)` calls
%   `PowerNetwork.import(path, Network=net, Initialize=tf)`
% - `CsvNetHandler.export(net, ModelName, savepath=d)` calls
%   `net.export(fullfile(d, "@"+ModelName))`
%
% <@Examples>
% ```matlab
% net = CsvNetHandler.import(path);
% ```
%
% <@Deprecated>
% Use PowerNetwork.import and net.export instead.
%
% See also PowerNetwork.import, PowerNetwork.export

    methods(Static)
        net  = import(path, net, opt)
        path = export(net, ModelName, opt)
    end

end
