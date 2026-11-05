function reset_edit(obj)
    % Initialize edit state for this layer and descendants.
    %
    % Marks the layer and its descendants as initialized and clears their edits.
    arguments (Input)
        obj
    end
    obj.sct_edit.l_initialized = true;
    obj.clear_edit_rows();
    cellfun(@(c) c.reset_edit, obj.children);
end
