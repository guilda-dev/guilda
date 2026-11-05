function flag = check_edit(obj, opt)
% Build out-of-date handles and optionally require an up-to-date equilibrium.
%
% Prepares the network for an analysis after edits.
% Builds the f_* handle caches that are not up to date (LayerPackage.check_edit) and, when
% RequireEquilibrium is true, stops with an error if initialize has not run
% or something that changes the equilibrium was edited since (dynamics,
% baseMVA or powerflow parameters, topology, slack bus; not the network Hz).
%
% <@Group> Called by analyses
    arguments (Input)
        obj   % Target network.
        opt.RequireEquilibrium (1,1) logical = false   % Error with ID GUILDA:PowerNetwork:EquilibriumStale when the equilibrium is out of date.
    end
    arguments (Output)
        flag   % True when the equilibrium is up to date.
    end
    check_edit@LayerPackage(obj);
    flag = ~obj.l_staleEquilibrium;
    if opt.RequireEquilibrium && ~flag
        i      = 1:obj.n_editLog;
        sv_tag = obj.sv_editTag(i);
        sv_log = obj.sv_editLog(i);
        [~, lv] = obj.edit_effect(sv_tag, sv_log);
        lv = lv & sv_tag ~= "Initialize";   % an "Initialize" row: initialize stopped while writing
        if ~obj.sct_edit.l_initialized
            s_reason = "net.initialize() has not been run";
        elseif any(lv)
            sv_edit    = obj.sv_editID(i(lv)) + ": " + sv_log(lv);
            s_reason   = "edited since the last initialize (" + join(sv_edit(1:min(end,3)), ", ");
            if numel(sv_edit) > 3
                s_reason = s_reason + ", ...";
            end
            s_reason = s_reason + ")";
        else
            s_reason = "the last net.initialize() stopped before it finished";
        end
        error(msg("GUILDA:PowerNetwork:EquilibriumStale", char(obj.s_tag), char(s_reason)))
    end
end
