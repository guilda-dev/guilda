classdef IEEE14bus < PowerNetwork
% <@Desc> 
% Made by CsvNetHandler.export (2026/04/20 05:43:59)
% <Model> IEEE14bus
% <Summary>
%  Bus       : 14
%  Branch    : 20
%  Component : 17
%   > SG     : 5
%   > Load   : 12
%   > Others : 0
% 
% <@Role> PowerNetwork COnstructor
% <@Constructor> 
%  net = IEEE14bus()
 
    properties(Constant)
        ver = 1
    end

    methods
        function obj = IEEE14bus(opt)
            arguments
                opt (1,1) logical = true
            end
            str_filepath = mfilename("fullpath");
            str_dirpath  = fileparts(str_filepath);
            CsvNetHandler.import(str_dirpath, obj, "Initialize", opt);
        end
    end
end
