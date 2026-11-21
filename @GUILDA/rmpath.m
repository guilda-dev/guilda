function rmpath()
% Remove paths for use of this software
% The root folder stays on the path: it holds @GUILDA, so GUILDA.addpath
% can still be called afterwards from any current folder. The optional
% folders _GUILDAverification and _GUILDAtextbook are removed too when they
% exist or are on the path.
% The log lines are printed in the Command Window while the setting
% Startup.PrintPathLog is true (default).

    GUILDApath = GUILDA.pwd;
    l_print  = GUILDA.config("Startup","PrintPathLog");   % read while the folders are on the path
    pathlist = fileread(fullfile(GUILDApath,"@GUILDA","config","ListPath.txt"));
    pathlist = string( strsplit(strtrim(pathlist)) );

    pathList = path;
    pathList = strsplit(pathList,pathsep);

    sv_optional = ["_GUILDAverification", "_GUILDAtextbook"];
    l_optional  = arrayfun(@(s) isfolder(fullfile(GUILDApath,s)) || ismember(fullfile(GUILDApath,s),pathList), sv_optional);
    pathlist = [pathlist, sv_optional(l_optional)];
    maxchar  = max(cellfun(@(c) numel(c), pathlist)) + 1;

    for i = 1:numel(pathlist)
        p  = pathlist{i};
        nc = max(1,maxchar-numel(p));
        if l_print
            fprintf(['︎  >> rmpath: ',p,repmat(' ',1,nc),'... '])
        end
        if ismember(fullfile(GUILDApath,replace(p,"/",filesep)),pathList)
            rmpath( fullfile(GUILDApath,replace(p,"/",filesep)) )
            s_msg = 'ok';
        else
            s_msg = 'already removed.';
        end
        if l_print
            disp(s_msg)
        end
    end
end
