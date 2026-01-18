function gitpull()
% Get new version from GitHub

    if ~isfolder([GUILDA.pwd,filesep,'.git'])
        disp("  .git file not found.")
    end

    repo = gitrepo;
    str_ModifiedFiles  = repo.ModifiedFiles;

    fprintf('\n === Git pull === \n')
    
    % Detect editing of files under the specified path below
    GUILDApath  = string(GUILDA.pwd);
    UntouchPath = GUILDApath + filesep + ["_GUILDAsystem","_GUILDAobject","@GUILDA"];
            
    l_rmFiles   = cellfun(@(p) contains(p,UntouchPath), str_ModifiedFiles);
    str_rmFiles = str_ModifiedFiles(l_rmFiles);

    % Exception: Changes to the following files are permitted.
    keepPath    = fullfile(GUILDApath,"@GUILDA","user");
    l_keepFiles = cellfun(@(p) contains(p,keepPath), str_rmFiles);
    str_rmFiles = str_rmFiles(~l_keepFiles);
    
    
    if ~isempty(str_rmFiles)
        disp("  Found a modified file in the GUILDA source code.")
        cellfun(@(f) disp("    Editing detected: "+f), str_rmFiles)
        fprintf(newline+  "    Your action >>")

        sentence = "Please select an action for the edited files:"+newline+...
                   "> clean  : Discard your edits. Changes cannot be recovered permanently!!"+newline+...
                   "> stash  : Duplicate the edited files and then discard the changes."+newline+...
                   "> cancel : Abort the git pull operation.";

        switch questdlg(sentence, 'Git pull Option', 'clean','stash','cancel','cancel')
            case "cancel"
                disp("git pull cancelled."+newline)
                return
            case "stash"
                disp("Duplicate the file, clean up the edits, and finally execute git pull"+newline)

                % フォルダ名を現在の時刻に基づき命名&作成
                datename = datetime("now","Format","uuMMdd_HHmmss");
                dirname  = ['stash',filesep,char(datename)];
                mkdir(dirname)
    
                % ファイルの複製
                disp(['  << Duplicate file to ',dirname,' folder >>'])
                flag_emergence_stop = false;
                for i = 1:numel(str_rmFiles)
                    str_rmFilesi = str_rmFiles(i);
                    [stashpath,stashfile,extc] = fileparts(str_rmFilesi);
                    stashpath = replace(stashpath,GUILDApath,"");
                    filename = [char(stashfile), char(extc)];
                    nc = max(1,40-numel(filename));
                    fprintf(['    Copy File: ',filename,repmat(' ',1,nc),'...'])

                    if ~isfile(str_rmFilesi)
                        disp("Not Found (deleted)")
                        continue
                    end

                    newpath = fullfile(dirname,stashpath);
                    if ~isfolder(newpath)
                        mkdir(newpath)
                    end
                    if copyfile(str_rmFilesi, newpath )
                        disp('ok')
                    else
                        disp('failed')
                        flag_emergence_stop = true;
                    end
                end
                if flag_emergence_stop
                    disp("    Git pull has been stopped due to a file copy failure."+newline)
                    return
                end
                disp(' ')

            case "clean"
                disp("Discard the edits and then execute git pull"+newline)
        end

        try 
            disp('  << Clean up Edits >>')
            fprintf('    Reset Modified Files ...')
            % cellfun(@(f) system(['git checkout HEAD ',f]), str_rmFiles);
            disp('ok')
            disp(' ')
        catch
            disp('failed')
            disp("    Stop git pull as reset failure has been detected."+newline)
            return
        end

        disp('  << git pull>>')
    end
    
    % status = system("git pull");
    status = 0;
    if status==0
        disp('    Git pull ...ok')
    else
        disp('    Git pull ...failed')
        disp('For some reason git pull could not be performed.')
    end
end



%%%%%%%%%%%%%%
% 質問用の関数 %
%%%%%%%%%%%%%%
function flag = Qdialog(msg,cleanlist,stashlist)%#ok
    flag =  "cancel";
end
