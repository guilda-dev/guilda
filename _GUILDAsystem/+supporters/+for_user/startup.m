function startup()
    
    disp('Welcome to GUILDA!!');
    
    name_folder = pwd;
    c_name_folder = split(name_folder, '/');
    addpath(strcat('../../../', c_name_folder{numel(c_name_folder)-2}));


end