function sv_message = stale_messages(obj)
% Messages of every stale tag of this layer (check_edit). Classes whose state can be
% out of date without an edit reaching them (the network frequency) add their own.
    arguments (Input)
        obj
    end
    arguments (Output)
        sv_message (:,1) string  % Messages; empty when the layer is up to date.
    end
    c = struct2cell(obj.sct_stale);
    sv_message = vertcat(strings(0,1), c{:});
end
