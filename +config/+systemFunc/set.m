function set(newEnv)
    newEnv = format(newEnv);
    Env  = config.systemFunc.get();
    Env  = config.systemFunc.merge(Env,newEnv);
    
    text = jsonencode(format(Env), PrettyPrint=true,ConvertInfAndNaN=false);
    path = fullfile(config.pwd,'+config','data','config_user.json');
    
    writelines(text,path)
end


function data = format(data)
    fields = fieldnames(data);
    for i = 1:numel(fields)
        field = fields{i};
        if isstruct(data.(field))
            if all( ismember(["Value","Type"], fieldnames(data.(field))) )
                data.(field) = data.(field).Value;
            else
                data.(field) = format(data.(field));
            end
        end
    end

end