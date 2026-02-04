function addpath()
% Add paths for use of this software

    GUILDApath = GUILDA.pwd;
    pathlist = fileread(fullfile(GUILDApath,"@GUILDA","config","ListPath.txt"));
    pathlist = string( strsplit(pathlist) );
    flag_warning = false;
    maxchar      = max(cellfun(@(c) numel(c), pathlist)) + 1;
    
    fprintf('\n === Add path for GUILDA === \n')
    for i = 1:numel(pathlist)
        p  = pathlist{i};
        nc = max(1,maxchar-numel(p));
        fprintf(['︎  addpath: ',p,repmat(' ',1,nc),'... '])
        try
            addpath( fullfile(GUILDApath,replace(p,"/",filesep)) )
            disp('ok')
        catch
            disp('failed !!!')
            flag_warning = true;
        end
    end
    if flag_warning
        disp('Failed to add the required folder path to GUILDA. This may cause a functional failure.')
    end
end