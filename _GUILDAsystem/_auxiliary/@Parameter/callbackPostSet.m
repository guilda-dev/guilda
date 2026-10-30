function callbackPostSet(obj,name,cls,event)
    % Check type consistency and record changes when values differ.
    %
    % Validates a property after it is changed and logs edits.
    %
    % Inputs:
    % - `name`: Property name being updated.
    % - `cls`: Expected class name.
    % - `event`: Property set event data.
    val_pre  = obj.val_stash;
    val_post = event.AffectedObject.(name);            
    
    if ~isa(val_post,cls)
        obj.(name) = val_pre;
        error(msg('GUILDA:Parameter:ClassNameMismatch', name, cls))                
    elseif ~isequaln(val_pre, val_post)    % NaN -> NaN is not a change
        obj.log_edit("edit "+name, "Parameter("+obj.str_tag+")", val_pre, val_post);
        obj.CallbackChanged();
    end
end