function out = config(field)
    filename = "Default"+field+".json";
    path_def_user  = fullfile(GUILDA.pwd,"@GUILDA","user",filename);
    out = readstruct(path_def_user);
end