function net = import(path, net, opt)
% Build a network from a CSV model folder (v3 wrapper of PowerNetwork.import).
%
% v3 entry point of the CSV import (deprecated: warns GUILDA:Deprecated:CsvNetHandlerImport).
% Calls PowerNetwork.import(path, Network=net, Initialize=opt.Initialize); without net
% a new network is built.
%
% <@Deprecated>
% Use PowerNetwork.import(path, Network=net) instead.
%
% See also PowerNetwork.import
    arguments (Input)
        path               (1,1) string   % Model folder.
        net                       = []   % Network to add the model to.
        opt.Initialize     (1,1) logical = true   % Run net.initialize() afterwards.
    end
    arguments (Output)
        net   % The built network.
    end
    Deprecated("CsvNetHandlerImport");
    net = PowerNetwork.import(path, Network=net, Initialize=opt.Initialize);
end
