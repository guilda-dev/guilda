function struct_env = merge(struct_env, struct_user)
    fields = fieldnames(struct_user);
    for i = 1:numel(fields)
        field = fields{i};

        if ~isfield(struct_env, field)
            warning("Ignore non-existent environment field("+field+")." )
            continue
        end

        user = struct_user.(field);
        env  = struct_env.(field);

        if isstruct(env)  && ~all( ismember(["Value","Type"], fieldnames(env)) )
            struct_env.(field) = config.systemFunc.merge(env, user);
            continue
        end

        switch env.Type
            case "select"
                if ~ismember(user, env.options)
                    str_opt = tools.hcellfun(@(s) [char(s),','], env.options);
                    warning(field+" must be one of ["+str_opt(1:end-1)+"].")
                    continue
                end
            case "double"
                if ismissing(user)
                    user = nan;
                elseif ~isnumeric(user)
                    warning(field+" must be numeric.")
                    continue
                end
            case "logical"
                if ~islogical(user)
                    warning(str_field+" must be a logical value.")
                    continue
                end
        end
        struct_env.(field).Value = user;
    end

end
