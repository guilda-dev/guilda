function gitpull()
    % gitに関するconfigの設定値を取得
    config = supporters.for_user.config;
    config = config.git;

    % 前回のプルから変更された部分を取得
    repo = gitrepo;

    a_Un = repo.UntrackedFiles;
    a_Mo = repo.ModifiedFiles;
    
    clean_path = [config.pwd,filesep] + cellfun(@(c) string(c), config.clean);
    clean_list = struct('Mo',[],'Un',[]);
    clean_list.Mo = a_Mo( tools.vcellfun(@(s) contains(s,clean_path), a_Mo) );

    stash_path = [config.pwd,filesep] + cellfun(@(c) string(c), config.clean);
    stash_list = struct('Mo',[],'Un',[]);
    stash_list.Mo = a_Mo( tools.vcellfun(@(s) contains(s,stash_path), a_Mo) );

    if config.clean_UntrackedFiles
        clean_list.Un = a_Un( tools.vcellfun(@(s) contains(s,clean_path), a_Un) );
        if config.clean_UntrackedFiles
            stash_list.Un = a_Un( tools.vcellfun(@(s) contains(s,stash_path), a_Un) );
        end
    end
        
    

    if ~isempty(clean_list.Un) || ~isempty(clean_list.Mo)
        % ソースコードの変更に対してダイアログで選択を要求
        %
        % ・flag = "cancel": gitのプルを中止
        % ・flag = "clean" : 変更ファイルの変更内容を破棄　▶︎ gitpull
        % ・flag = "stash" : 変更ファイルの複製をstashフォルダに作成 ▶ ︎変更ファイルの変更内容を破棄　▶︎ gitpull
        %
        switch config.message
        case "disp"
            flag = Qdisp('GUILDAのソースコードへの変更が検出されました', clean_list, stash_list);
        case "dialog"
            flag = Qdialog('GUILDAのソースコードへの変更が検出されました', clean_list, stash_list);
        end

        if strcmp(flag,"cancel")
            disp('>> git pull cancelled.')
            return
        end

        if strcmp(flag,"stash")
            % フォルダ名を現在の時刻に基づき命名&作成
            datename = datetime("now","Format","uuMMdd_HHmmss");
            dirname  = ['stash',filesep,char(datename)];
            mkdir(dirname)

            % ファイルの複製
            disp('<< Duplicate file to ',dirname,' folder >>')
            stash_list = [stash_list.Mo(:);stash_list.Un(:)];
            flag_emergence_stop = false;
            for i = 1:numel(stash_list)
                [~,stashfile,extc] = fileparts(stash_list(i));
                filename = [char(stashfile), char(extc)];
                nc = max(1,numel(filename)-25);
                fprintf(['>> ',char(st),repmat(' ',1,nc),'...'])
                if copyfile(stash_list(i), dirname)
                    disp('ok')
                else
                    disp('failed !!!')
                    flag_emergence_stop = true;
                end
            end
            if flag_emergence_stop
                disp('Stop git pull as duplicate failure has been detected.')
            end
            disp(' ')
        end

        disp('<< Reset changes >>')
        try 
            cellfun(@(f) system(['git checkout HEAD ',f]), clean_list.Mo);
            cellfun(@(f) system(['git clean -fd ',f]), clean_list.Un);
            disp('>> Reset Completed.')
        catch
            disp('>> Reset Failure !!!')
            disp('Stop git pull as reset failure has been detected.')
        end
    end
    disp(' ')
    
    disp('<< git pull>>')
    status = system("git pull");
    if status==0
        disp('>> git pull completed.')
        type(fullfile(config.pwd,'_GUILDAsystem','+supporters','+for_user','UpdateLog.txt'))
    else
        disp('>> git pull failed !!!')
        disp('For some reason git pull could not be performed.')
    end
end



%%%%%%%%%%%%%%
% 質問用の関数 %
%%%%%%%%%%%%%%
function flag = Qdialog(msg,cleanlist,stashlist)%#ok
    flag =  "cancel";
end

function flag = Qdisp(msg,cleanlist,stashlist)
    flag = [];
    disp(msg)
    fprintf('\n\n')
    disp('<<変更内容>>')
    if ~isempty(cleanlist.Mo)
        disp(' 変更されたファイル')
        cellfun(@(f) disp([' ▶',f]), cleanlist.Mo);
    end
    if ~isempty(cleanlist.Un)
        disp(' 新規作成されたファイル')
        cellfun(@(f) disp([' ▶',f]), cleanlist.Un);
    end

    a_flag = tools.hcellfun(@(c) contains( c, fullfile(config.pwd,'_Tutorial') ), cleanlist.Mo);
    if all(a_flag) && ~isempty(a_flag)
        flag = "clean";
        return
    end

    fprintf('\n\n')
    disp('<<処理選択>>')
    disp('新たなアップデートがある場合上記の変更内容と競合する恐れがあります。')
    disp(' 1：gitのpullを中止')
    disp(' 2：変更箇所を破棄してpullを実行')
    if ~isempty(stashlist.Mo) || ~isempty(stashlist.Un)
        disp(' 3：以下のファイルのみstashフォルダに複製してからpullを実行')
        cellfun(@(f) disp(['    ▶︎',f]),[stashlist.Mo(:);stashlist.Un(:)])
    end
    disp(' ')
    while isempty(flag)
        switch input('どの処理を実行するか選択し番号を入力して下さい：')
            case 1; flag = "cancel";
            case 2; flag = "clean";
            case 3; flag = "stash";
        end
    end
    fprintf('\n\n')

end
