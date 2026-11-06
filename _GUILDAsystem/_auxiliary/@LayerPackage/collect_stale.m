function sv_message = collect_stale(obj)
% Messages of every stale tag of this layer and the layers below it (stale_messages of
% each), in tree order with repeats. A Parameter container among the children has no
% stale tags and no children. Used by check_edit and PowerNetwork.initialize.
    arguments (Input)
        obj
    end
    arguments (Output)
        sv_message (:,1) string  % Messages; empty when the subtree is up to date.
    end
    sv_message = obj.stale_messages();
    a_children = obj.children;
    for i = 1:numel(a_children)
        if ~isa(a_children{i}, "Parameter")
            sv_message = [sv_message; a_children{i}.collect_stale()]; %#ok<AGROW>
        end
    end
end
