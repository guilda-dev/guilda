classdef Txt3Bus < PowerNetwork
 
    properties(Constant)
        ver = 1
    end

    methods
        function obj = Txt3Bus()
            str_filepath = mfilename("fullpath");
            str_dirpath  = fileparts(str_filepath);
            CsvNetHandler.import(str_dirpath, obj);
        end
    end
end
