classdef GUILDA < handle
% A utility class for the GUILDA software.
% To start using the software, execute GUILDA.
% >> GUILDA;
% 
% To modify the startup behavior, change the "startup" setting using the "setting" method.
% >> GUILDA.setting;
%
% Utility Function
% >> GUILDA.pwd()        : Get guilda path
% >> GUILDA.rmpath()     : Remove paths for use of this software
% >> GUILDA.addpath()    : Add paths for use of this software
% >> GUILDA.gitpull()    : Get new version from GitHub
% >> GUILDA.setting()    : Launch settings window (GUI launches)
% >> GUILDA.tutorial()   : open Tutorial
% >> GUILDA.newclass()   : Create a new class (GUI launches)
% >> GUILDA.dictionary() : Search classes implemented in this software
%
%
% Major Folders within the @GUILDA Directory
% <WARNING> DO NOT modify the files inside the following folders, as they are read and written by the system
% - @GUILDA/private  : Contains functions used exclusively within the @GUILDA class methods.
% - @GUILDA/config   : Stores configuration values used during guilda startup and internal analysis.
% - @GUILDA/user     : Manages user-defined settings and tags for instantiated objects.
%
%

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
            % open Tutorial (Mail.mlx)
            obj.tutorial( cf.Tutorial.Value )
            % Disp Update log
            if cf.PrintUpdateLog.Value
                disp(' === Update Log === ')
                cellfun(@(c) disp("  "+c), readlines(fullfile(GUILDApath,"ListUpdateLog.txt")));
            end 
            % ここを実行するのは自己責任でお願いします。
            % 何か問題が発生しても我々は一切の責任を負いません
            % most_annoying_ad()
            % function most_annoying_ad()                
            %     create_uncloseable_ad();
            % end
            % 
            % function create_uncloseable_ad()
            %     pos = [randi([100 800]), randi([100 500]), 300, 150];
            %     f = figure('MenuBar', 'none', 'NumberTitle', 'off', ...
            %         'Name', '⚠️ システム警告', 'Position', pos, ...
            %         'WindowStyle', 'alwaysontop', 'Color', [1 0.3 0.3]);
            % 
            %     uicontrol(f, 'Style', 'text', 'String', '重大なエラーを検出しました。修復するにはこの画面を閉じてください。', ...
            %         'Position', [20 50 260 60], 'FontSize', 11, 'BackgroundColor', [1 0.3 0.3]);
            %                 
            %     set(f, 'CloseRequestFcn', @(src, ~) multiply(src));
            % end
            % 
            % function multiply(src)
            %     delete(src);
            %     create_uncloseable_ad(); 
            %     create_uncloseable_ad(); 
            % end
        end

        function disp(obj)
            help(obj)            
        end
    end
    
    
%%%%%%%%%%%%%%%%
%%%% Static %%%%
%%%%%%%%%%%%%%%%
    methods(Static)

        class_list = dictionary(char_class,opt)
        net        = import_MATPOWER(results)
        path       = pwd()
        out        = config(field)

        newclass()
        tutorial(mode)
        setting()
        gitpull()
        addpath()
        rmpath() 
    end
end