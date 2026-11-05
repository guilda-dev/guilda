function reset_edit(obj)
    % Initialize edit state for this layer and descendants.
    %
    % Marks the layer and its descendants as initialized (PowerNetwork also clears its edit log).
    obj.sct_edit.l_initialized = true;
    cellfun(@(c) c.reset_edit, obj.children);
end
