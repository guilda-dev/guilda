function startup()
    
    disp([newline,newline]);
    disp('Welcome to GUILDA!!');
    disp('==========================================================================================');
    
    data = supporters.for_user.config;
    data = data.startup;

    % プロジェクト開始時にTutorialのMail.mlxを起動する
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    switch data.Tutorial
        case "on"
            open _Tutorial/Main.mlx
        case "off"
        otherwise
    end
    
    % 旧バージョンの場合version_supportをパスに追加
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    switch string(data.version)
        case "1"
            addpath(fullfile(tools.pwd,'_GUILDAsystem','_version_support'))
        case "latest"
        otherwise
    end


    % gitのプルの実行
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ispull = strcmp(data.gitpull,'on');
    isgit  = isfolder([tools.pwd,filesep,'.git']);
    if ispull && isgit
        supporters.for_user.gitpull;
    end

    
    disp('==========================================================================================');
    disp(newline);
end