function startup()
    cf_all = config.systemFunc.get();
    config.systemFunc.set(cf_all);

    cf = cf_all.startup;

    disp([newline,newline]);
    disp('Launching GUILDA...');
    disp('==========================================================================================');
    disp(' ')
   
     % 必要なパスの追加
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    disp('=== Add path === ')
    pathlist = fileread(fullfile(config.pwd,"+config","data","PathList.txt"));
    pathlist = string( strsplit(pathlist) );
    flag_warning = false;
    GUILDApath   = fileparts(mfilename("fullpath"));
    FILEpath     = fullfile("+config","+systemCall");
    GUILDApath   = replace(GUILDApath,FILEpath,"");
    maxchar      = max(cellfun(@(c) numel(c), pathlist)) + 1;
    for i = 1:numel(pathlist)
        p  = pathlist{i};
        nc = max(1,maxchar-numel(p));
        fprintf(['︎>> ',p,repmat(' ',1,nc),'... '])
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
    disp(' ')

    
    % 旧バージョンの場合version_supportをパスに追加
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % if cf.version_support.Value
    %     list = dir(fullfile(config.pwd,'_GUILDAsystem','_version_support'));
    %     for i = 1:numel(list)
    %         name = list(i).name;
    %         if contains(name,'ver') && list(i).isdir
    %             veri = str2double(replace(name,'ver',''));
    %             if ~isnan(veri) && veri>=data.version
    %                 addpath(fullfile(config.pwd,'_GUILDAsystem','_version_support',name))
    %             end
    %         end
    %     end
    % end
   
    
    % gitのプルの実行
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    isgit  = isfolder([config.pwd,filesep,'.git']);
    if isgit && cf.gitpull.Value
        disp('=== Git pull === ')
        config.systemFunc.gitpull;
        disp(' ')
    end



    % プロジェクト開始時にTutorialのMail.mlxを起動する
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    switch cf.open.Value
        case "none"
        case "Tutorial"
            disp('=== Tutorial ===')
            disp(">> open _Tutorial/Main.mlx")
            open _Tutorial/Main.mlx
            disp(' ')
        case "GUI"
            disp('=== GUI ===')
            disp(">> Launching GUI...")
            disp(' ')
    end

    disp('==========================================================================================');
    disp('Welcome to GUILDA!!');
    disp([newline,newline]);
end