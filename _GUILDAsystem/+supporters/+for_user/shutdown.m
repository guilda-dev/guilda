function shutdown()

    disp(newline);
    disp('Start git push');

    path_guilda = pwd;
    c_path_guilda = split(path_guilda, '/');
    path_code_share = strcat('../../../', c_path_guilda{numel(c_path_guilda)-2});
    
    url_code_share = 'https://github.com/guilda-dev/guilda_code_share.git';
    [status, cmdout] = system(strcat("git -C ", path_code_share, " remote -v"));
    if and(status==0, contains(cmdout, url_code_share))
        status_1 = system(strcat("git -C ", path_code_share, " commit -a -m 'auto commit in guilda shutdown'"));
        status_2 = system(strcat("git -C ", path_code_share, " push"));
        if and(status_1~=0, status_2~=0)
            warning("git push error in guilda_code_share");
        end
    end

    disp('Finish git push');
    disp(" ")
    disp('Shut down GUILDA.');
    disp('----------------------------------------------------------------------------------------------------');
    
end