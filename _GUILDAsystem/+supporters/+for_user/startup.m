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
    if isnumeric(data.version)
        list = dir(fullfile(tools.pwd,'_GUILDAsystem','_version_support'));
        for i = 1:numel(list)
            name = list(i).name;
            if contains(name,'ver') && list(i).isdir
                veri = str2double(replace(name,'ver',''));
                if ~isnan(veri) && veri>=data.version
                    addpath(fullfile(tools.pwd,'_GUILDAsystem','_version_support',name))
                end
            end
        end
    else
        switch string(data.version)
            case "latest"
            otherwise
        end
    end



    % gitのプルの実行
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ispull = strcmp(data.gitpull,'on');
    isgit  = isfolder([tools.pwd,filesep,'.git']);
    if ispull && isgit
        supporters.for_user.gitpull;
    end

    
    disp('  ')
    disp('==========================================================================================');
    disp(newline);
end