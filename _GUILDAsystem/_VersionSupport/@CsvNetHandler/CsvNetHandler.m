classdef CsvNetHandler < auxiliary
% <@Desc>
% v3 CSV import/export of networks (deprecated). The methods are wrappers of the v4 API:
%   CsvNetHandler.import(path, net, Initialize=tf)  ->  PowerNetwork.import_csv(path, Network=net, Initialize=tf)
%   CsvNetHandler.export(net, ModelName, savepath=d) ->  net.export_csv(fullfile(d, "@"+ModelName))
% They warn GUILDA:Deprecated:CsvNetHandlerImport / GUILDA:Deprecated:CsvNetHandlerExport.
% <@Role> Compatibility
% <@Constructor> None (static methods only)

    methods(Static)
        net  = import(path, net, opt)
        path = export(net, ModelName, opt)
    end

end
