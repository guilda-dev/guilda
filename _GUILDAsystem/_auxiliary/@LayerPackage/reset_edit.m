function reset_edit(obj)
    % Initialize edit state for this layer and descendants.
    %
    % Marks the layer and its descendants as initialized and clears their edit logs (only the
    % top layer of the hierarchy keeps one; a layer that was a top layer while detached may
    % still hold rows).
    arguments (Input)
        obj
    end
    obj.sct_edit.l_initialized = true;
    if obj.n_editLog > 0 || ~isempty(obj.rv_editTime)
        obj.clear_edit_log();
    end
    cellfun(@(c) c.reset_edit, obj.children);
end
