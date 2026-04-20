classdef CsvNetHandler < auxiliary

    methods(Static)
        net  = import(path, net, opt)
        path = export(net, ModelName, opt)
    end

end