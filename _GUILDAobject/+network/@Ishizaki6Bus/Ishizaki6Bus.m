classdef Ishizaki6Bus < PowerNetwork

 
    properties(Constant)
        ver = 1
    end

    methods
        function obj = Ishizaki6Bus(alpha,opt)
            arguments
                alpha (1,1) double = 1;               
                opt.line {mustBeMember(opt.line, {'L23','L46','Both','None'})} = 'Both'
            end            
            str_filepath = mfilename("fullpath");

            new_path = replace(str_filepath,[filesep,'Ishizaki6Bus'],'');
            bra_path = [new_path,[filesep,'branch',filesep,'parameter.csv']];

            tab_branch = readtable(bra_path);

            tab_branch.R = tab_branch.X * alpha;
            tab_branch{1:4,"R"} = 0;
            FromTo = tab_branch{:,["From","To"]};            
    
            switch opt.line
                case 'L23'
                    lv_FT = ismember(FromTo,[2,3],"rows");
                    tab_branch = tab_branch(~lv_FT,:);
                case 'L46'
                    lv_FT = ismember(FromTo,[4,6],"rows");
                    tab_branch = tab_branch(~lv_FT,:);
                case 'Both'
                    lv_FT = ismember(FromTo,[2,3;4,6],"rows");
                    tab_branch = tab_branch(~lv_FT,:);
                case 'None'
            end

            writetable(tab_branch,bra_path);

            str_dirpath  = fileparts(str_filepath);           
            CsvNetHandler.import(str_dirpath, obj);
        end
    end
end
