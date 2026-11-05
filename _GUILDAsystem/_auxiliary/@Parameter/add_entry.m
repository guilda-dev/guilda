function add_entry(obj,names,defaults,valids)
    % Register parameter names, defaults, and validation classes.
    %
    % Adds dynamic properties and attaches the class check and the change listeners.
    arguments (Input)
        obj
    end
    arguments (Input, Repeating)
        names     % Property name of the parameter (valid variable name).
        defaults  % Default value of the parameter.
        valids    % Class the value must have.
    end
    for i = 1:numel(names)
        name    = names{i};
        default = defaults{i};
        valid   = valids{i};
        
        obj.sv_parameter   = [obj.sv_parameter,name];
        dprop               = obj.addprop( name );
        dprop.SetObservable = true;
        obj.(name)          = default;
        obj.attach_callbacks(name,valid);
    end
end
