function log_edit(obj, log, tag, before, after)
    % Append a new edit-log record.
    %
    % Stores the edit in the layer's own rows (the rows of the owner for a Parameter
    % container) once that layer has been initialized, and reports it to the top layer of
    % the hierarchy (report_edit) for its rules.
    arguments (Input)
        obj % Target layer object.
        log    (1,1) string = ""; % Log message.
        tag    (1,1) string = ""; % Kind of edit (see edit_effect).
        before = nan;             % State before the edit.
        after  = nan;             % State after the edit.
    end
    % What the edit made stale (see LayerPackage.edit_effect): the handle cache of the
    % parameter's owner here; the equilibrium is kept by the network (report_edit).
    [l_odefcn, l_equilibrium] = obj.edit_effect(tag, log);
    if l_odefcn && isa(obj,"Parameter") && isa(obj.parent,"LayerPackage") && obj.parent.sct_edit.s_odefcn == "updated"
        obj.parent.sct_edit.s_odefcn = "editted";
    end

    % A Parameter container keeps no rows: the containers of the controllers are not their
    % children, so initialize (reset_edit) and tab_editLog reach them through the owner.
    a_owner = obj;
    if isa(obj,"Parameter") && isa(obj.parent,"LayerPackage")
        a_owner = obj.parent;
    end
    if a_owner.sct_edit.l_initialized
        a_owner.store_edit(obj, log, tag, before, after);
    end

    obj.get_top_layer().report_edit(obj, tag, l_equilibrium);

    % A network Hz edit reaches the handles of every layer: the next analysis
    % (check_edit) builds them with the new frequency.
    if isa(obj,"Parameter") && isa(obj.parent,"PowerNetwork") && tag == "Parameter(base)" && log == "edit Hz"
        obj.parent.mark_odefcn();
    end
end
