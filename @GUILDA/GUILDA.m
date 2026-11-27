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
% >> GUILDA.setting()    : Launch settings window (GUI launches); GUILDA.setting(Category, Name=Value) changes settings
% >> GUILDA.tutorial()   : open Tutorial
% >> GUILDA.doc()        : open documentation on browser
% >> GUILDA.publish_doc(): publish reference and developer docs to gh-pages (local commit)
% >> GUILDA.newclass()   : Create a new class (GUI launches)
% >> GUILDA.dictionary() : Search classes implemented in this software
% >> GUILDA.keymap()    : Model keys of a category and the names of their classes
% >> GUILDA.update_keymap(): Rebuild the model key map from the classes on the path
% >> GUILDA.launch_gui() : Start the GUILDA app (build, analyze and export a script; GUI launches)
%
% Major Folders within the @GUILDA Directory
% <WARNING> DO NOT modify the files inside the following folders, as they are read and written by the system
% - @GUILDA/private  : Contains functions used exclusively within the @GUILDA class methods.
% - @GUILDA/config   : Stores configuration values used during guilda startup and internal analysis.
% - @GUILDA/user     : Manages user-defined settings and tags for instantiated objects.
%
% <@Constructor> 
% >> GUILDA;
% There are no input arguments for the constructor. However, it performs several startup operations, such as displaying the GUILDA logo, adding necessary paths, checking version requirements, updating the model key map, and launching the tutorial. These operations can be customized.
% To customize the startup behavior, change the "Startup" settings using the "setting" method.
% >> GUILDA.setting;
% >> GUILDA.setting("Startup", UpdateKeyMap="silent")

    methods
        function obj = GUILDA
            % This constructor also serves as the GUILDA startup preparation.
            % The following operations are executed:
            %
            %   o Print the GUILDA logo
            %   x Add paths (also _GUILDAverification and _GUILDAtextbook when they exist, and the folders of ModelFolder; the log only when PrintPathLog is true)
            %   o Check version requirements
            %   o Update the documentation database
            %   o Update the model key map (UpdateKeyMap: "none", "silent" or "disp")
            %   o Launch the tutorial
            %
            % If any of the above startup operations are not required, modify the Startup settings via GUILDA.setting. 
            % Only items marked with 'o' can be skipped. Items marked with 'x' cannot be skipped.
            arguments (Output)
                obj  % GUILDA utility object.
            end

            GUILDApath = fullfile(obj.pwd,"@GUILDA","config");
            has_desktop = usejava('desktop');   % false in -batch / -nodisplay
            [cf_all, sv_reset, sm_invalid] = get_config();
            cf         = cf_all.Startup;
            set_config(cf_all);
            % disp GUILDA LOGO
            if cf.PrintLogo.Value
                cellfun(@(c)disp(c),readlines(fullfile(GUILDApath,"GUILDAstring.txt")))
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
            % update key map: "none" skips it, "silent" hides the list of the keys
            switch cf.UpdateKeyMap.Value
                case "disp"
                    GUILDA.update_keymap;
                case "silent"
                    evalc("GUILDA.update_keymap;");
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
        addpath()
        rmpath() 
        doc(option)
        publish_doc()
        dic        = keymap(category)
        update_keymap(opt)
        h          = launch_gui(net)
    end
end
