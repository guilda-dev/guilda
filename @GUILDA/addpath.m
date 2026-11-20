function addpath()
% Add paths for use of this software
% The root folder (".") comes first: it holds @GUILDA, so GUILDA.config and
% the other GUILDA methods work from any current folder.
% The developer folder _GUILDAsystem/_admin is added only when the setting
% Startup.DeveloperPath is true and the folder exists; otherwise it is removed
% from the path, so a change of the setting applies at the next call.

    GUILDApath = GUILDA.pwd;
    pathlist = fileread(fullfile(GUILDApath,"@GUILDA","config","ListPath.txt"));
    pathlist = [".", string( strsplit(strtrim(pathlist)) )];
    s_admin  = "_GUILDAsystem/_admin";
    flag_warning = false;
    maxchar      = max(cellfun(@(c) numel(c), [pathlist, s_admin])) + 1;

    fprintf('\n === Add path for GUILDA === \n')
    for i = 1:numel(pathlist)
        p  = pathlist{i};
        nc = max(1,maxchar-numel(p));
        fprintf(['︎  addpath: ',p,repmat(' ',1,nc),'... '])
        try
            if p == "."
                addpath( GUILDApath )
            else
                addpath( fullfile(GUILDApath,replace(p,"/",filesep)) )
            end
            disp('ok')
        catch
            disp('failed !!!')
            flag_warning = true;
        end
    end
    if flag_warning
        disp('Failed to add the required folder path to GUILDA. This may cause a functional failure.')
    end

    % developer folder: read the setting after the folders above are on the path
    % (GUILDA.config may show INFO with show_msg of _GUILDAsystem/_auxiliary)
    s_admin_path = fullfile(GUILDApath,replace(s_admin,"/",filesep));
    if GUILDA.config("Startup","DeveloperPath") && isfolder(s_admin_path)
        fprintf(['︎  addpath: ',char(s_admin),repmat(' ',1,max(1,maxchar-strlength(s_admin))),'... '])
        addpath( s_admin_path )
        disp('ok')
    elseif ismember(s_admin_path, strsplit(path,pathsep))
        rmpath( s_admin_path )
    end
end
