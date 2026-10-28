function flag = check_edit(obj, opt)
% <@Desc>
% Prepares the network for an analysis after edits.
% Rebuilds the stale f_* handle caches (LayerPackage.check_edit) and, when
% RequireEquilibrium is true, stops with an error if initialize has not run
% or something that changes the equilibrium was edited since (dynamics,
% base or powerflow parameters, topology, slack bus).
% <@Role>
% Edit Log
% <@Summary>
% Rebuild stale handles; optionally require an up-to-date equilibrium.
% <@Signatures>
% [
%   "flag = check_edit(obj)",
%   "flag = check_edit(obj, RequireEquilibrium=true)"
% ]
% <@Parameters>
% [
%   {
%     "Name": "obj",
%     "Type": "PowerNetwork",
%     "Description": "Target network.",
%     "Required": true,
%     "Default": "-"
%   },
%   {
%     "Name": "RequireEquilibrium",
%     "Type": "logical scalar",
%     "Description": "Error with ID GUILDA:PowerNetwork:EquilibriumStale when the equilibrium is out of date.",
%     "Required": false,
%     "Default": "false"
%   }
% ]
% <@Returns>
% [
%   {
%     "Name": "flag",
%     "Type": "logical scalar",
%     "Description": "True when the equilibrium is up to date."
%   }
% ]
    arguments
        obj
        opt.RequireEquilibrium (1,1) logical = false
    end
    flag = check_edit@LayerPackage(obj);
    if opt.RequireEquilibrium && ~flag
        if obj.str_editFlag == "unset"
            str_reason = "net.initialize() has not been run";
        else
            tab = obj.tab_editLog;
            [~, lv] = arrayfun(@(t) LayerPackage.edit_effect(t), string(tab.tag));
            str_edit   = tab.ID(lv) + ": " + tab.log(lv);
            str_reason = "edited since the last initialize (" + join(str_edit(1:min(end,3)), ", ");
            if numel(str_edit) > 3
                str_reason = str_reason + ", ...";
            end
            str_reason = str_reason + ")";
        end
        error('GUILDA:PowerNetwork:EquilibriumStale', '%s', ...
              msg('GUILDA:PowerNetwork:EquilibriumStale', char(obj.str_tag), char(str_reason)))
    end
end
