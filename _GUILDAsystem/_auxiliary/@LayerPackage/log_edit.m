function log_edit(obj, log, tag)
    % Report an edit of this layer to every layer up to the top.
    %
    % Calls handle_edit(a_owner, tag, message) on the edited layer and on every layer
    % above it; a_owner is the edited layer (the owner for a Parameter container) and
    % message is "<tags from obj up, joined by "/">: <log>". Each layer appends it to its
    % own stale tags that the edit affects.
    arguments (Input)
        obj % Edited layer (a Parameter container for a parameter edit).
        log    (1,1) string  % What was edited, with the values (e.g. "edit D: 0.1 -> 0.2").
        tag    (1,1) string  % Kind of edit: a parameter group ("dynamics", "powerflow", ...), "Topology", "Slack", "opffcn" or "Tag".
    end
    s_message = obj.get_tag("/") + ": " + log;

    % A Parameter container is not a child of a controller, so the walk starts at its owner.
    a_owner = obj;
    if isa(obj,"Parameter") && isa(obj.parent,"LayerPackage")
        a_owner = obj.parent;
    end
    a_layer = a_owner;
    while true
        a_layer.handle_edit(a_owner, tag, s_message);
        a_parent = a_layer.parent;
        if ~isa(a_parent,"LayerPackage")
            break
        end
        a_layer = a_parent;
    end
end
