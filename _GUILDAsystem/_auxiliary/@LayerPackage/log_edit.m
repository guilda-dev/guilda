function log_edit(obj, log, tag, before, after, time, tab)
    % Append a new edit-log record.
    %
    % Records an edit event and propagates it to parent layers.
    arguments
        obj % Target layer object.
        log   (1,1) string = "";                                                    %#ok
        tag   (1,1) string = ""; %#ok
        before = nan;                                                               %#ok
        after  = nan;                                                               %#ok
        time   = string(datetime('now','Format','uuuu/MM/dd HH:mm:ss'));            %#ok
        tab    = table(time, obj.get_tag(true,"/"), log, tag, {before}, {after}) % Prebuilt edit-log row.
    end
    % Record what the edit made stale (see LayerPackage.edit_effect):
    % the handle cache of the parameter's owner (of the owner and all its
    % descendants for a "base" parameter such as Hz), and the network equilibrium.
    str_logtag = string(tab{1,4});
    [l_odefcn, l_equilibrium] = LayerPackage.edit_effect(str_logtag, string(tab{1,3}));
    if l_odefcn && isa(obj,"Parameter") && isa(obj.parent,"LayerPackage")
        if str_logtag == "Parameter(base)"
            obj.parent.mark_stale_odefcn();
        else
            obj.parent.l_staleOdefcn = true;
        end
    end

    if isa(obj,"PowerNetwork")
        if obj.str_editFlag ~= "unset"
            obj.str_editFlag = "editted";
            obj.l_staleEquilibrium = obj.l_staleEquilibrium || l_equilibrium;
            tab.Properties.VariableNames = {'timestamp','ID','log','tag','before','after'};
            obj.tab_editLog  = [obj.tab_editLog; tab];
        end
        % The network reacts to the reported edit (e.g. keeps a single slack bus),
        % also before the first initialize.
        obj.handle_edit(tab);
    elseif isa(obj.parent,"LayerPackage")
        obj.str_editFlag = "editted";
        obj.parent.log_edit("","",nan,nan,"",tab)
    else
        return
    end
end