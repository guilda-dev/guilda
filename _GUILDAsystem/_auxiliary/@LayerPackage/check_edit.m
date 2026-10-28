function flag = check_edit(obj)
% <@Desc>
% Brings the layer and its descendants up to date before an analysis.
% Rebuilds the f_* handle cache of every layer whose l_staleOdefcn is set
% (only those layers), and reports whether the equilibrium set by
% initialize is still valid. Called at the start of initialize, simulate
% and get_sys (see PowerNetwork.check_edit).
% <@Role>
% Edit Log
% <@Summary>
% Rebuild stale handles and report whether the equilibrium is up to date.
% <@Signatures>
% [
%   "flag = check_edit(obj)"
% ]
% <@Parameters>
% [
%   {
%     "Name": "obj",
%     "Type": "LayerPackage",
%     "Description": "Target layer object.",
%     "Required": true,
%     "Default": "-"
%   }
% ]
% <@Returns>
% [
%   {
%     "Name": "flag",
%     "Type": "logical scalar",
%     "Description": "True when initialize has run and nothing that changes the equilibrium was edited since (meaningful on PowerNetwork)."
%   }
% ]
    if obj.l_staleOdefcn
        obj.rebuild_odefcn();
    end
    cellfun(@(c) c.check_edit, obj.children);
    flag = obj.str_editFlag ~= "unset" && ~obj.l_staleEquilibrium;
end
