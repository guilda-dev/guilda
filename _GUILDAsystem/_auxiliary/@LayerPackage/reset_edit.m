function reset_edit(obj, l_initialized)
    % Clear the edits of this layer and its descendants and set their initialized flag.
    %
    % Called with true at the end of initialize and with false when the layer is attached
    % to a new parent (Bus.set_network, Branch.set_network, Component.set_bus,
    % LocalController.set_parent, GlobalController.set_parent).
    arguments (Input)
        obj
        l_initialized (1,1) logical  % New value of l_initialized.
    end
    obj.l_initialized = l_initialized;
    if ~isempty(obj.sct_editLog)
        obj.sct_editLog = obj.sct_editLog([]);
    end
    cellfun(@(c) c.reset_edit(l_initialized), obj.children);
end
