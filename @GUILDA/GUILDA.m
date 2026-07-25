classdef GUILDA < handle
% <@Role> Utility
% <@Desc> A utility class for the GUILDA software.
% To start using the software, execute GUILDA.
% >> GUILDA;
%
% Utility Function
% >> GUILDA.pwd()        : Get guilda path
% >> GUILDA.rmpath()     : Remove paths for use of this software
% >> GUILDA.addpath()    : Add paths for use of this software
% >> GUILDA.gitpull()    : Get new version from GitHub
% >> GUILDA.setting()    : Launch settings window (GUI launches)
% >> GUILDA.tutorial()   : open Tutorial
% >> GUILDA.doc()        : open documentation on browser
% >> GUILDA.newclass()   : Create a new class (GUI launches)
% >> GUILDA.dictionary() : Search classes implemented in this software
%
% Major Folders within the @GUILDA Directory
% <WARNING> DO NOT modify the files inside the following folders, as they are read and written by the system
% - @GUILDA/private  : Contains functions used exclusively within the @GUILDA class methods.
% - @GUILDA/config   : Stores configuration values used during guilda startup and internal analysis.
% - @GUILDA/user     : Manages user-defined settings and tags for instantiated objects.
%
% <@Constructor> 
% >> GUILDA;
% There are no input arguments for the constructor. However, it performs several startup operations, such as displaying the GUILDA logo, performing a Git pull, adding necessary paths, checking version requirements, launching the tutorial, and displaying the update log. These operations can be customized.
% To customize the startup behavior, change the "startup" setting using the "setting" method.
% >> GUILDA.setting;

    methods
        function obj = GUILDA
            % This constructor also serves as the GUILDA startup preparation.
            % The following operations are executed:
            %
            %   o Print the GUILDA logo
            %   o Perform a Git pull
            %   x Add paths
            %   o Check version requirements
            %   o Launch the tutorial
            %   o Display the update log
            %
            % If any of the above startup operations are not required, modify the contents of the startup setting via GUILDA.setting. 
            % Only items marked with 'o' can be skipped. Items marked with 'x' cannot be skipped.

            GUILDApath = fullfile(obj.pwd,"@GUILDA","config");
            cf_all     = get_config();
            cf         = cf_all.EnvStartup;
            set_config(cf_all);
            % disp GUILDA LOGO
            if cf.PrintLogo.Value
                cellfun(@(c)disp(c),readlines(fullfile(GUILDApath,"GUILDAstring.txt")))
            end
            % git pull
            if cf.gitpull.Value
                obj.gitpull;
            end
            % add GUILDA path
            obj.addpath
            % check required Toolbox
            if cf.CheckRequirement.Value
                check_requirement
            end
            % update documentation database
            if cf.UpdateDoc.Value
                obj.doc('update',true);
            end
            % Disp Update log
            if cf.PrintUpdateLog.Value
                disp(' ')
                disp(' === Update Log === ')
                cell_log = readlines(fullfile(GUILDApath,"ListUpdateLog.txt"));
                cellfun(@(c) disp("  "+c), cell_log(7:end));
            end 
            % update key map
            if cf.UpdateKeyMap.Value
                update_class_signature;
            end
            % open Tutorial (Mail.mlx)
            if cf.Tutorial.Value
                obj.tutorial;
            end
   
        end

        function disp(~)
            fprintf( "  === @GUILDA Class Methods ===\n"+...
                     "  >> GUILDA.pwd()        : Get guilda path\n"+...
                     "  >> GUILDA.setting()    : Launch settings window (GUI launches)\n"+...
                     "  >> GUILDA.tutorial()   : open Tutorial\n"+...
                     "  >> GUILDA.doc()        : open documentation on browser\n"+...
                     "  >> GUILDA.newclass()   : Create a new class (GUI launches)\n"+...
                     "  >> GUILDA.dictionary() : Search classes implemented in this software"+...
                     "  >> GUILDA.rmpath()     : Remove paths for use of this software\n"+...
                     "  >> GUILDA.addpath()    : Add paths for use of this software\n"+...
                     "  >> GUILDA.gitpull()    : Get new version from GitHub\n\n")
        end
    end
    
    
%%%%%%%%%%%%%%%%
%%%% Static %%%%
%%%%%%%%%%%%%%%%
    methods(Static)

        class_list = dictionary(char_class,opt)
        net        = import_MATPOWER(results)
        path       = pwd()
        data       = config(category,parameter,option)

        newclass()
        tutorial(mode)
        setting()
        gitpull()
        addpath()
        rmpath() 
        document()
        doc()
    end
end
