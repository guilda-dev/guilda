function callbackPreSet(obj,name,event)
    % Stash the previous property value for later comparison.
    %
    % Stores the current value before a property is changed.
    arguments (Input)
        obj
        name   % Property name being updated.
        event  % Property set event data.
    end
    obj.val_stash = event.AffectedObject.(name);
end