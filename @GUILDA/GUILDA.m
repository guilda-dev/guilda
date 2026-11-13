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
% >> GUILDA.setting()    : Launch settings window (GUI launches); GUILDA.setting(Category, Name=Value) changes settings
% >> GUILDA.tutorial()   : open Tutorial
% >> GUILDA.doc()        : open documentation on browser
% >> GUILDA.publish_doc(): publish documentation to GitHub Pages (gh-pages)
% >> GUILDA.newclass()   : Create a new class (GUI launches)
% >> GUILDA.dictionary() : Search classes implemented in this software
% >> GUILDA.keymap()    : Model keys of a category and the names of their classes
% >> GUILDA.update_keymap(): Rebuild the model key map from the classes on the path
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
            arguments (Output)
                obj  % GUILDA utility object.
            end

            GUILDApath = fullfile(obj.pwd,"@GUILDA","config");
            has_desktop = usejava('desktop');   % false in -batch / -nodisplay
            [cf_all, sv_reset, sm_invalid] = get_config();
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
            % user settings reset by a new version of their defaults (show_msg needs the path)
            for s_reset = sv_reset'
                show_msg("info", "GUILDA:GUILDA:ConfigReset", s_reset)
            end
            for k = 1:size(sm_invalid, 1)
                show_msg("info", "GUILDA:GUILDA:ConfigValueReset", sm_invalid(k,1), sm_invalid(k,2), sm_invalid(k,3))
            end
            % check required Toolbox
            if cf.CheckRequirement.Value
                check_requirement
            end
            % update documentation database
            if cf.UpdateDoc.Value
                obj.doc('update',"auto",'open',false);
            end
            % update key map
            if cf.UpdateKeyMap.Value
                GUILDA.update_keymap;
            end
            % open Tutorial (Mail.mlx)
            if cf.Tutorial.Value
                if has_desktop
                    obj.tutorial;
                else
                    show_msg("info", "GUILDA:GUILDA:NoDesktopTutorial")
                end
            end
   
        end

        disp(~)
    end

%%%%%%%%%%%%%%%%
%%%% Static %%%%
%%%%%%%%%%%%%%%%
    methods(Static)

        class_list = dictionary(char_class,opt)
        path       = pwd()
        data       = config(category,parameter,option)

        newclass()
        tutorial(mode)
        setting(s_category, varargin)
        gitpull()
        addpath()
        rmpath() 
        doc(option)
        publish_doc(option)
        dic        = keymap(category)
        update_keymap(opt)
    end
end
