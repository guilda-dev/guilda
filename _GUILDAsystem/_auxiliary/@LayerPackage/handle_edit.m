function handle_edit(obj, a_layer, tag, log)
% Hook for an edit of a_layer, called by log_edit on every layer from the edited
% layer (the owner of a Parameter container) up to the top. Does nothing here;
% subclasses override it to append the message to their own stale tags (mark_stale).
    arguments (Input)
        obj            % Layer on the path from the edited layer to the top.
        a_layer        % Edited layer (a Parameter container for a parameter edit).
        tag string     % Kind of edit (see log_edit).
        log string     % Message: tags of the edited layer, ": ", what was edited.
    end
end
