function set_config(Env)
    Env = format(Env);

    str_file = arrayfun(@(s) string(s.name), dir(fullfile(GUILDA.pwd,"@GUILDA","config")));
    lv_def   = cellfun(@(c) contains(c,'Default'), str_file);
    
    for ele = str_file(lv_def)'
        field = replace(ele,["Default",".json"],["",""]);
        text  = jsonencode(format(Env.(field)), PrettyPrint=true,ConvertInfAndNaN=false);
        path  = fullfile(GUILDA.pwd,'@GUILDA','user',ele);
        Env   = rmfield(Env,field);
        writelines(text,path)
    end
    text = jsonencode(format(Env), PrettyPrint=true,ConvertInfAndNaN=false);
    path = fullfile(GUILDA.pwd,'@GUILDA','user',"GUILDAconfig.json");
    writelines(text,path)
end


function data = format(data)
    fields = fieldnames(data);
    for i = 1:numel(fields)
        field = fields{i};
        if isstruct(data.(field))
            if all( ismember(["Value","Type","Description"], fieldnames(data.(field))) )
                data.(field) = data.(field).Value;
            else
                data.(field) = format(data.(field));
            end
        end
    end
end