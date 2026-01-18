function path = pwd()
% Get guilda path
    path = replace(mfilename('fullpath'),[filesep,'@GUILDA',filesep,'pwd'],'');
end