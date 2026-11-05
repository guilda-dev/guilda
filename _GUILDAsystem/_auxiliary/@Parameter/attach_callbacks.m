function attach_callbacks(obj,name,valid)
    % Attach the class check and the change listeners of a parameter.
    %
    % A MAT file keeps neither of them, so PowerNetwork.loadobj attaches them again.
    arguments (Input)
        obj
        name   % Property name of the parameter.
        valid  % Class the value must have.
    end
    dprop           = findprop(obj,name);
    dprop.SetMethod = set_method(name,valid);                                              % Before Change: Validate (an error here is a real error, unlike in a listener)
    
    addlistener(obj,name,'PreSet', @(~,event) obj.callbackPreSet(name,event));             % Befor Change: Save unchanged data to val_stash
    addlistener(obj,name,'PostSet', @(~,event) obj.callbackPostSet(name,event));           % After Change: Compare changed data vs. val_stash / log 
end

function fcn = set_method(name,valid)
    % Return the set method of a parameter.
    %
    % It must be a nested function: an anonymous function that calls another function would
    % assign outside the set method and call the set method again without end.
    fcn = @set_value;
    function set_value(obj,val)
        if ~isa(val,valid)
            error(msg("GUILDA:Parameter:ClassNameMismatch", name, valid, class(val)))
        end
        obj.(name) = val;
    end
end
