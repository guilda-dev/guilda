classdef Txt3Bus < PowerNetwork
 
    properties(Constant)
        ver = 1
    end

    methods
        function obj = Txt3Bus()
            str_filepath = mfilename("fullpath");
            str_dirpath  = fileparts(str_filepath);
            PowerNetwork.import_csv(str_dirpath, Network=obj);
        end
    end
end
