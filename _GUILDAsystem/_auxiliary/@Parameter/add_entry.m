function add_entry(obj,names,defaults,valids)
    % Register parameter names, defaults, and validation classes.
    %
    % Adds dynamic properties and attaches the class check and the change listeners.
    arguments
        obj % Target parameter container.
    end
    arguments(Input,Repeating)
        names    %(1,1) string {mustBeValidVariableName}
        defaults %(1,1) 
        valids   %(1,1) string
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
