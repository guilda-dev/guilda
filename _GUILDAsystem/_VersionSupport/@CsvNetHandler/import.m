function net = import(path, net, opt)
% Build a network from a CSV model folder (v3 wrapper of PowerNetwork.import_csv).
%
% v3 entry point of the CSV import (deprecated: warns GUILDA:Deprecated:CsvNetHandlerImport).
% Calls PowerNetwork.import_csv(path, Network=net, Initialize=opt.Initialize); without net
% a new network is built.
%
% <@Deprecated>
% Use PowerNetwork.import_csv(path, Network=net) instead.
%
% See also PowerNetwork.import_csv
    arguments
        path               (1,1) string   % Model folder.
        net                       = []   % Network to add the model to.
        opt.Initialize     (1,1) logical = true   % Run net.initialize() afterwards.
    end
    arguments (Output)
        net   % The built network.
    end
    Deprecated("CsvNetHandlerImport");
    net = PowerNetwork.import_csv(path, Network=net, Initialize=opt.Initialize);
end
