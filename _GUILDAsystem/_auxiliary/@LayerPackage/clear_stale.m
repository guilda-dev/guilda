function clear_stale(obj, sv_tag)
% Mark stale tags of this layer up to date (PowerNetwork.initialize and the steps it calls).
    arguments (Input)
        obj
        sv_tag (1,:) string  % Stale tags (fields of sct_stale) brought up to date.
    end
    for s_field = sv_tag
        if ~isempty(obj.sct_stale.(s_field))
            obj.sct_stale.(s_field) = strings(0,1);
        end
    end
end
