function struct_env = merge_config(struct_env, struct_user)
    fields = fieldnames(struct_user);
    for i = 1:numel(fields)
        field = fields{i};
        if ~isfield(struct_env, field)
            disp("Remove unknown environment field '"+field+"'." )
            continue
        elseif isempty(struct_user.(field))
            continue
        end
        user = struct_user.(field);
        env  = struct_env.(field);
        if isstruct(env)  && ~all( ismember(["Value","Type"], fieldnames(env)) )
            struct_env.(field) = merge_config(env, user);
            continue
        end
        switch env.Type
            case "select"
                if ~ismember(user, env.options)
                    disp("Auto-change @"+field+" ("+user+" >> "+env.Value+")")
                    continue
                end
            case "double"
                if ismissing(user)
                    user = nan;
                elseif ~isnumeric(user)
                    disp("Auto-change @"+field+" ("+user+" >> "+env.Value+")")
                    continue
                end
            case "logical"
                if ~islogical(user)
                    disp("Auto-change @"+field+" ("+user+" >> "+env.Value+")")
                    continue
                end
        end
        struct_env.(field).Value = user;
    end
end