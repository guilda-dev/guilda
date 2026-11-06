function mark_stale(obj, sv_tag, s_message)
% Append a message to stale tags of this layer.
% A message already there is not repeated, and a tag that still holds the initial
% message ("initialize has not been run") takes no other one.
    arguments (Input)
        obj
        sv_tag    (1,:) string  % Stale tags (fields of sct_stale) to mark.
        s_message (1,1) string  % Why they are stale.
    end
    for s_field = sv_tag
        sv = obj.sct_stale.(s_field);
        if ~any(sv == s_message | sv == obj.s_notInitialized)
            obj.sct_stale.(s_field) = [sv; s_message];
        end
    end
end
