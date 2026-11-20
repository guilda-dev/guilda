function rmpath()
% Remove paths for use of this software
% The root folder stays on the path: it holds @GUILDA, so GUILDA.addpath
% can still be called afterwards from any current folder. The developer
% folder _GUILDAsystem/_admin (setting Startup.DeveloperPath) is removed too.

    GUILDApath = GUILDA.pwd;
    pathlist = fileread(fullfile(GUILDApath,"@GUILDA","config","ListPath.txt"));
    pathlist = [string( strsplit(strtrim(pathlist)) ), "_GUILDAsystem/_admin"];
    maxchar  = max(cellfun(@(c) numel(c), pathlist)) + 1;

    pathList = path;
    pathList = strsplit(pathList,pathsep);

    for i = 1:numel(pathlist)
        p  = pathlist{i};
        nc = max(1,maxchar-numel(p));
        fprintf(['︎  >> rmpath: ',p,repmat(' ',1,nc),'... '])
        if ismember(fullfile(GUILDApath,replace(p,"/",filesep)),pathList)
            rmpath( fullfile(GUILDApath,replace(p,"/",filesep)) )
            disp('ok')
        else
            disp('already removed.')
        end
    end
end