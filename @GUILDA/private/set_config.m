function set_config(Env)
% Write the configuration to the user files in @GUILDA/user and read it again.
%
% Each category goes to @GUILDA/user/Default<Category>.json with the version of its default
% file (write_user_config). The cache of GUILDA.config is read again, so the new values
% apply to the next GUILDA.config call and analysis.
    arguments (Input)
        Env  % Configuration struct (as returned by get_config).
    end
    for ele = config_files()'
        field = replace(ele,["Default",".json"],["",""]);
        write_user_config(field, Env.(field));
    end
    GUILDA.config([],[],"reset",true);
end
