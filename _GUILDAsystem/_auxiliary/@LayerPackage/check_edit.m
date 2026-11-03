function flag = check_edit(obj)
% Build the handles that are not up to date and report whether the equilibrium is.
%
% Brings the layer and its descendants up to date. Calls set_odefcn on every layer whose
% s_edit.str_odefcn is not "updated" ("unset": never built; "editted": a dynamics edit, a
% network Hz edit or an attach since the last build), parent before children, and reports
% whether the equilibrium set by initialize is still valid. Called at the start of every
% analysis that uses the f_* handles: initialize, calculate_continuation_powerflow and,
% through PowerNetwork.require_equilibrium, solver_ODE.solve and solver_LIN.solve
% (net.simulate, net.linearize, net.get_sys); the get_sys of each layer; validate; and
% get_dx_algebraic and get_sys_alone of a model used on its own. See PowerNetwork.check_edit.
    arguments (Output)
        flag % True when initialize has run and nothing that changes the equilibrium was edited since (meaningful on PowerNetwork).
    end
    if obj.s_edit.str_odefcn ~= "updated"
        obj.set_odefcn();
    end
    cellfun(@(c) c.check_edit(), obj.children);
    flag = obj.s_edit.str_flag ~= "unset" && ~obj.s_edit.l_staleEquilibrium;
end
