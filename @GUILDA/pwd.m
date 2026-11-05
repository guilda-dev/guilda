function path = pwd()
% Get guilda path
    arguments (Output)
        path  % Root folder of GUILDA.
    end
    path = replace(mfilename('fullpath'),[filesep,'@GUILDA',filesep,'pwd'],'');
end