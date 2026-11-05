function log_edit(obj, log, tag, before, after)
    % Append a new edit-log record.
    %
    % Stores the edit in the layer's own rows (the rows of the owner for a Parameter
    % container) once that layer has been initialized, then calls handle_edit on every
    % layer from there up to the top of the hierarchy.
    arguments (Input)
        obj % Target layer object.
        log    (1,1) string = ""; % Log message.
        tag    (1,1) string = ""; % Kind of edit.
        before = nan;             % State before the edit.
        after  = nan;             % State after the edit.
    end
    % A Parameter container keeps no rows: the containers of the controllers are not their
    % children, so initialize (reset_edit) and disp_edit reach them through the owner.
    a_owner = obj;
    if isa(obj,"Parameter") && isa(obj.parent,"LayerPackage")
        a_owner = obj.parent;
    end
    if a_owner.l_initialized
        a_owner.sct_editLog(end+1) = struct("i_seq",next_edit_seq(), "r_time",now, ...
            "s_ID",obj.get_tag("/"), "s_log",log, "s_tag",tag, "before",{before}, "after",{after});
    end

    % The hook of every layer up to the top: the first layer without a LayerPackage parent.
    a_layer = a_owner;
    while true
        a_layer.handle_edit(obj, tag, log);
        a_parent = a_layer.parent;
        if ~isa(a_parent,"LayerPackage")
            break
        end
        a_layer = a_parent;
    end
end
