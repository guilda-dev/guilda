classdef CsvNetHandler < auxiliary
% <@Desc>
% Utility class for importing and exporting PowerNetwork configurations as CSV files.
% Provides static methods to read a network from CSV and to write a network to CSV.
% <@Role>
% auxiliary
% <@Constructor>
% No constructor needed; use static methods directly.
%  i.e.
%  >> net = CsvNetHandler.import(path)
%  >> CsvNetHandler.export(net, ModelName)

    methods(Static)
        net  = import(path, net, opt)
        path = export(net, ModelName, opt)
    end

end