function rmpath()
% Remove paths for use of this software

    GUILDApath = GUILDA.pwd;
    pathlist = fileread(fullfile(GUILDApath,"@GUILDA","config","ListPath.txt"));
    pathlist = string( strsplit(pathlist) );
    maxchar  = max(cellfun(@(c) numel(c), pathlist)) + 1;

    pathList = path;
    pathList = strsplit(pathList,pathsep);

    for i = 1:numel(pathlist)
        p  = pathlist{i};
        nc = max(1,maxchar-numel(p));
        fprintf(['︎  >> rmpath: ',p,repmat(' ',1,nc),'... '])
        if ismember(fullfile(GUILDApath,p),pathList)
            rmpath( fullfile(GUILDApath,replace(p,"/",filesep)) )
            disp('ok')
        else
            disp('already removed.')
        end
    end
end