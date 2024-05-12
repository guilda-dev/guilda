function shutdown()

    % 旧バージョンの場合version_supportをパスに追加
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    list = dir(fullfile(tools.pwd,'_GUILDAsystem','_version_support'));
    nowpath = path;

    for i = 1:numel(list)
        name = list(i).name;
        folderpath = fullfile(tools.pwd,'_GUILDAsystem','_version_support',name);
        if contains(name,'ver') && list(i).isdir && contains(nowpath,string(folderpath))
            rmpath(folderpath)    
        end
    end


    disp(newline);
    disp('Shut down GUILDA.');
    disp('==========================================================================================');
    disp(newline)
end