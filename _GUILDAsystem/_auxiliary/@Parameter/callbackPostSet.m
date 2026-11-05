function callbackPostSet(obj,name,event)
    % Record the change when the value differs.
    %
    % Logs edits after a property is changed. The class is checked by the set method of the
    % property (add_entry) because MATLAB turns an error in a listener into a warning.
    arguments (Input)
        obj
        name   % Property name being updated.
        event  % Property set event data.
    end
    val_pre  = obj.val_stash;
    val_post = event.AffectedObject.(name);            
    
    if ~isequaln(val_pre, val_post)    % NaN -> NaN is not a change
        obj.log_edit("edit "+name, "Parameter("+obj.str_tag+")", val_pre, val_post);
        obj.CallbackChanged();
    end
end
