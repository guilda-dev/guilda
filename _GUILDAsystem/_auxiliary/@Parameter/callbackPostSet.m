function callbackPostSet(obj,name,event)
    % Report the change when the value differs.
    %
    % Reports the edit with log_edit after a property is changed, with the old and new
    % values in the message. The class is checked by the set method of the property
    % (add_entry) because MATLAB turns an error in a listener into a warning.
    arguments (Input)
        obj
        name   % Property name being updated.
        event  % Property set event data.
    end
    val_pre  = obj.val_stash;
    val_post = event.AffectedObject.(name);            
    
    if ~isequaln(val_pre, val_post)    % NaN -> NaN is not a change
        obj.s_lastEdited = name;
        obj.log_edit("edit " + name + ": " + tools.value_text(val_pre) + " -> " + tools.value_text(val_post), obj.s_tag);
        obj.CallbackChanged();
    end
end
