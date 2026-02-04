function out = get_config(varargin)

    % path_env_user = fullfile(GUILDA.pwd,"@GUILDA","user"  ,"GUILDAconfig.json");
    % path_env_sys  = fullfile(GUILDA.pwd,"@GUILDA","config","GUILDAconfig.json");
    % 
    % env_user = readstruct(path_env_user);
    % env_sys  = readstruct(path_env_sys );
    
    env_user = struct();
    env_sys  = struct();

    str_file = arrayfun(@(s) string(s.name), dir(fullfile(GUILDA.pwd,"@GUILDA","config")));
    lv_def   = cellfun(@(c) contains(c,'Default'), str_file);
    
    for ele = str_file(lv_def)'
        path_def_user  = fullfile(GUILDA.pwd,"@GUILDA","user"  ,ele);
        path_def_sys   = fullfile(GUILDA.pwd,"@GUILDA","config",ele);

        field = replace(ele,["Default",".json"],["",""]);
        if isfile(path_def_user)
            env_user.(field) = readstruct(path_def_user);
        else
            env_user.(field) = struct();
        end
        env_sys.(field)  = readstruct(path_def_sys);
    end

    out = merge_config(env_sys, env_user);
    if numel(varargin)>0
        out  = getfield(out,varargin{:});
    end
end