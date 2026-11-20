function set_options(obj, opt)
% Assign the Name-Value options of a constructor (one field per property) to obj.
    arguments (Input)
        obj
        opt (1,1) struct  % Name-Value options, one field per public property.
    end
    for s_name = string(fieldnames(opt)).'
        obj.(s_name) = opt.(s_name);
    end
end
