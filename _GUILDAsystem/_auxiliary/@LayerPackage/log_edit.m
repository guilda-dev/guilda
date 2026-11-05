function log_edit(obj, log, tag, before, after)
    % Append a new edit-log record.
    %
    % Reports the edit to the top layer of the hierarchy (report_edit), which records it.
    arguments (Input)
        obj % Target layer object.
        log    (1,1) string = ""; % Log message.
        tag    (1,1) string = ""; % Kind of edit (see edit_effect).
        before = nan;             % State before the edit.
        after  = nan;             % State after the edit.
    end
    % Record what the edit made stale (see LayerPackage.edit_effect): the handle cache of the
    % parameter's owner. The network derives the equilibrium state from its log.
    l_odefcn = obj.edit_effect(tag, log);
    if l_odefcn && isa(obj,"Parameter") && isa(obj.parent,"LayerPackage") && obj.parent.sct_edit.s_odefcn == "updated"
        obj.parent.sct_edit.s_odefcn = "editted";
    end

    obj.get_top_layer().report_edit(obj, log, tag, before, after);

    % A network Hz edit reaches the handles of every layer: the next analysis
    % (check_edit) builds them with the new frequency.
    if isa(obj,"Parameter") && isa(obj.parent,"PowerNetwork") && tag == "Parameter(base)" && log == "edit Hz"
        obj.parent.mark_odefcn();
    end
end
