function flag = check_edit(obj)
% Build the handles that are not up to date and report whether the equilibrium is.
%
% Brings the layer and its descendants up to date. Calls set_odefcn on every layer whose
% sct_edit.str_odefcn is not "updated" ("unset": never built; "editted": a dynamics edit, a
% network Hz edit or an attach since the last build), parent before children, and reports
% whether initialize has run (PowerNetwork.check_edit also checks the edits since). Called at the start of every
% analysis that uses the f_* handles: initialize, calculate_continuation_powerflow and,
% through PowerNetwork.require_equilibrium, solver_ODE.solve and solver_LIN.solve
% (net.simulate, net.linearize, net.get_sys); the get_sys of each layer;
% LocalController.validate; and Component.get_dx_algebraic and
% LocalController.get_dx_algebraic when the layer itself is not "updated" (a direct
% call; in a simulation the solver has already checked every layer). See
% PowerNetwork.check_edit.
    arguments (Output)
        flag % True when initialize has run; on PowerNetwork, also nothing that changes the equilibrium was edited since.
    end
    if obj.sct_edit.str_odefcn ~= "updated"
        obj.set_odefcn();
    end
    cellfun(@(c) c.check_edit(), obj.children);
    flag = obj.sct_edit.l_initialized;
end
