function flag = check_edit(obj)
% Rebuild stale handles and report whether the equilibrium is up to date.
%
% Brings the layer and its descendants up to date before an analysis.
% Rebuilds the f_* handle cache of every layer whose l_staleOdefcn is set
% (only those layers), and reports whether the equilibrium set by
% initialize is still valid. Called at the start of initialize and, through
% PowerNetwork.require_equilibrium, of solver_ODE.solve and solver_LIN.solve
% (net.simulate, net.linearize, net.get_sys); see PowerNetwork.check_edit.
    arguments (Output)
        flag % True when initialize has run and nothing that changes the equilibrium was edited since (meaningful on PowerNetwork).
    end
    if obj.l_staleOdefcn
        obj.rebuild_odefcn();
    end
    cellfun(@(c) c.check_edit, obj.children);
    flag = obj.str_editFlag ~= "unset" && ~obj.l_staleEquilibrium;
end
