function net = import(path, net, opt)
% <@Desc>
% v3 entry point of the CSV import (deprecated: warns GUILDA:Deprecated:CsvNetHandlerImport).
% Calls PowerNetwork.import_csv(path, Network=net, Initialize=opt.Initialize); without net
% a new network is built.
% <@Role> Compatibility
% <@Summary> v3 wrapper of PowerNetwork.import_csv.
% <@Signatures>
% [
%   "net = CsvNetHandler.import(path)",
%   "net = CsvNetHandler.import(path, net, Initialize=tf)"
% ]
% <@Parameters>
% [
%   {"Name": "path", "Type": "string scalar", "Description": "Model folder.", "Required": true, "Default": "-"},
%   {"Name": "net", "Type": "PowerNetwork", "Description": "Network to add the model to.", "Required": false, "Default": "a new PowerNetwork"},
%   {"Name": "Initialize", "Type": "logical scalar", "Description": "Run net.initialize() afterwards.", "Required": false, "Default": "true"}
% ]
% <@Returns>
% [
%   {"Name": "net", "Type": "PowerNetwork", "Description": "The built network."}
% ]
    arguments
        path               (1,1) string
        net                       = []
        opt.Initialize     (1,1) logical = true
    end
    Deprecated("CsvNetHandlerImport");
    net = PowerNetwork.import_csv(path, Network=net, Initialize=opt.Initialize);
end
