function startup()
    
    
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
    switch data.version
        case 1
            addpath('./_GUILDAsystem/_version_support')
        case "latest"
        otherwise
    end


    % gitのプルの実行
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ispull = strcmp(data.gitpull,'on');
    isgit  = isfolder([tools.pwd,filesep,'.git']);
    if ispull && isgit
        status = system(strcat("git pull"));
        if status~=0
            warning("git pull error in guilda_code_share");
        end
    end

    
    disp('----------------------------------------------------------------------------------------------------');
    disp('Welcome to GUILDA!!');
    disp(newline);
end