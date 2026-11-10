function data = config(category,parameter,option)
    arguments (Input)
        category     = []                % Configuration category (field of the config struct); empty returns everything.
        parameter    = []                % Parameter in the category; empty returns the whole category.
        option.reset (1,1) logical = false;  % Read the configuration files again instead of the cache.
    end
    arguments (Output)
        data  % Configuration struct, category struct, or the parameter value.
    end
    
    persistent cache
    if isempty(cache) || option.reset
        [cache, sv_reset] = get_config();
        for s_reset = sv_reset'
            % after the cache is set: show_msg reads the Message settings through GUILDA.config
            show_msg("info", "GUILDA:GUILDA:ConfigReset", s_reset)
        end
    end
    
    data = cache;
    if ~isempty(category)
        data = data.(category);
        if ~isempty(parameter)
            data = data.(parameter).Value;
        end
    end

end