function flag = check_edit(obj, l_force)
% Rebuild stale handles and report whether the equilibrium is up to date.
%
% Brings the layer and its descendants up to date. Rebuilds the f_* handle cache of
% every layer whose s_edit.l_staleOdefcn is set (only those layers), or of all of them
% with l_force, and reports whether the equilibrium set by initialize is still valid.
% Called at the start of initialize and, through PowerNetwork.require_equilibrium, of
% solver_ODE.solve and solver_LIN.solve (net.simulate, net.linearize, net.get_sys); see
% PowerNetwork.check_edit. l_force is for a change of the frequency the layers read: a
% network Hz edit (log_edit) and attaching a layer to a parent.
    arguments
        obj
        l_force (1,1) logical = false   % Rebuild every layer, stale or not.
    end
    arguments (Output)
        flag % True when initialize has run and nothing that changes the equilibrium was edited since (meaningful on PowerNetwork).
    end
    if obj.s_edit.l_staleOdefcn || l_force
        obj.set_odefcn();
    end
    cellfun(@(c) c.check_edit(l_force), obj.children);
    flag = obj.s_edit.str_flag ~= "unset" && ~obj.s_edit.l_staleEquilibrium;
end
