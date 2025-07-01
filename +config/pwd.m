function path = pwd()
    path = replace(mfilename('fullpath'),[filesep,'+config',filesep,'pwd'],'');
end