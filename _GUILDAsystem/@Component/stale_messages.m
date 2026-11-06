function sv_message = stale_messages(obj)
% Messages of the stale tags, and a network frequency other than the one bound into the
% handles (a Hz edit of the network does not reach the component).
    arguments (Input)
        obj
    end
    arguments (Output)
        sv_message (:,1) string  % Messages; empty when the component is up to date.
    end
    sv_message = stale_messages@PowerSystemModel(obj);
    if isempty(obj.sct_stale.odefcn) && ~isempty(obj.r_odefcnHz) && obj.r_odefcnHz ~= obj.get_Hz()
        sv_message(end+1,1) = "network frequency changed: " + obj.r_odefcnHz + " -> " + obj.get_Hz() + " Hz";
    end
end
