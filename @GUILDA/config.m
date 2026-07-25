function data = config(category,parameter,option)
    arguments
        category     = [] %(1,1) string 
        parameter    = [] %(1,1) string
        option.reset (1,1) logical = false;
    end
    
    persistent cache
    if isempty(cache) || option.reset
        cache = get_config();
    end
    
    data = cache;
    if ~isempty(category)
        data = data.(category);
        if ~isempty(parameter)
            data = data.(parameter).Value;
        end
    end

end