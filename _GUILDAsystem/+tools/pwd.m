function path = pwd()
    pwd_path = [filesep,'_GUILDAsystem',filesep,'+tools',filesep,'pwd'];
    path = replace(mfilename('fullpath'),pwd_path,'');
end
