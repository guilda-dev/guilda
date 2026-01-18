function rmpath()
% Remove paths for use of this software

    GUILDApath = GUILDA.pwd;
    pathlist = fileread(fullfile(GUILDApath,"@GUILDA","config","ListPath.txt"));
    pathlist = string( strsplit(pathlist) );
    maxchar  = max(cellfun(@(c) numel(c), pathlist)) + 1;

    pathListMac = path;
    pathListMac = strsplit(pathListMac,':');

    for i = 1:numel(pathlist)
        p  = pathlist{i};
        nc = max(1,maxchar-numel(p));
        fprintf(['︎  >> rmpath: ',p,repmat(' ',1,nc),'... '])
        if ismember(fullfile(GUILDApath,p),pathListMac)
            rmpath( fullfile(GUILDApath,replace(p,"/",filesep)) )
            disp('ok')
        else
            disp('already removed.')
        end
    end
end