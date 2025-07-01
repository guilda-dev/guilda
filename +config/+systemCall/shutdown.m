function shutdown()
    
    disp([newline,newline]);
    disp('Shut down GUILDA...');
    disp('==========================================================================================');
    disp(' ')

    
    % GUILDA用のパスの削除
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    disp('=== Remove path === ')
    pathlist = fileread(fullfile(config.pwd,"+config","data","PathList.txt"));
    pathlist = string( strsplit(pathlist) );
    GUILDApath   = fileparts(mfilename("fullpath"));
    FILEpath     = fullfile("+config","+systemCall");
    GUILDApath   = replace(GUILDApath,FILEpath,"");
    maxchar      = max(cellfun(@(c) numel(c), pathlist)) + 1;
    for i = 1:numel(pathlist)
        p  = pathlist{i};
        nc = max(1,maxchar-numel(p));
        fprintf(['︎>> ',p,repmat(' ',1,nc),'... '])
        try
            rmpath( fullfile(GUILDApath,replace(p,"/",filesep)) )
            disp('ok')
        catch
            disp('failed !!!')
        end
    end
    disp(' ')


    % 旧バージョンの場合version_supportをパスに追加しているため、これらのパスを削除
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % list = dir(fullfile(config.pwd,'_GUILDAsystem','_version_support'));
    % nowpath = path;
    % 
    % for i = 1:numel(list)
    %     name = list(i).name;
    %     folderpath = fullfile(config.pwd,'_GUILDAsystem','_version_support',name);
    %     if contains(name,'ver') && list(i).isdir && contains(nowpath,string(folderpath))
    %         rmpath(folderpath)    
    %     end
    % end
   
    disp('==========================================================================================');
    disp('See you again!!')
    disp([newline,newline]);
    
end