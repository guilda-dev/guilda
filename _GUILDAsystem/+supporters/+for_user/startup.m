function startup()
    
    disp('Welcome to GUILDA!!');
    
    path_guilda = pwd;
    c_path_guilda = split(path_guilda, '/');
    path_code_share = strcat('../../../', c_path_guilda{numel(c_path_guilda)-2});
    
    url_code_share = 'https://github.com/guilda-dev/guilda_code_share.git';
    [status, cmdout] = system(strcat("git -C ", path_code_share, " remote -v"));
    if and(status==0, contains(cmdout, url_code_share))
        addpath(path_code_share);
    end
    disp(cmdout); disp(status);

end