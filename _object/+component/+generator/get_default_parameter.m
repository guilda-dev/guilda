function parameter = get_default_parameter(parameter)

    if istable(paramter)
        return
    end
    
    if ischar(parameter) || isstring(parameter)
        parameter = char(paremeter);
        dataset = readtable('generator_parameter_default.csv');
        switch parameter
            case 'NGT2'
                parameter = dataset(1,:);
            case 'NGT6'
                parameter = dataset(2,:);
            case 'NGT8'
                parameter = dataset(3,:);
        end
    end
end