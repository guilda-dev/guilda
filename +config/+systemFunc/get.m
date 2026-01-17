function out = get(varargin)
    path_env_user = fullfile(config.pwd,"+config","data","config_user.json");
    path_env_sys  = fullfile(config.pwd,"+config","data","config.json");

    try 
        env_user = readstruct(path_env_user);
        env_sys  = readstruct(path_env_sys );
    catch
        env_user = jsondecode(fileread(path_env_user));
        env_sys  = jsondecode(fileread(path_env_sys));
    end

    out = config.systemFunc.merge(env_sys, env_user);
    if numel(varargin)>0
        out  = getfield(out,varargin{:});
    end
end
