function startup()
    
    disp('----------------------------------------------------------------------------------------------------');
    disp('Welcome to GUILDA!!');
    disp(" ")
    
    disp('<<< Start git pull >>>');
    path_guilda = pwd;
    c_path_guilda = split(path_guilda, '/');
    path_code_share = strcat('../../../', c_path_guilda{numel(c_path_guilda)-2});
    
    url_code_share = 'https://github.com/guilda-dev/guilda_code_share.git';
    [status, cmdout] = system(strcat("git -C ", path_code_share, " remote -v"));
    if and(status==0, contains(cmdout, url_code_share))
        status = system(strcat("git -C ", path_code_share, " pull"));
        if status~=0
            warning("git pull error in guilda_code_share");
        end
        addpath(path_code_share);
    end

    status = system("git pull");
    if status~=0
        warning("git pull error in guilda");
    end
    disp('<<< Finish git pull >>>');
    disp(newline);

end