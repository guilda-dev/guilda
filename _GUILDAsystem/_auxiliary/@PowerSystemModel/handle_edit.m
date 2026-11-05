function handle_edit(obj, a_layer, tag, log)
% An edit of one of the layer's own Parameter containers that makes the handles
% stale marks them "editted" (when they were "updated"). log_edit calls this on
% every layer from the edited layer up to the top.
    arguments (Input)
        obj            % Layer on the path from the edited layer to the top.
        a_layer        % Edited layer (a Parameter container for a parameter edit).
        tag string     % Kind of edit (see edit_effect).
        log string     % Log message.
    end
    if obj.s_odefcn == "updated" && isa(a_layer, "Parameter") && obj.is_parent_of(a_layer)
        if obj.edit_effect(tag, log)
            obj.s_odefcn = "editted";
        end
    end
end
