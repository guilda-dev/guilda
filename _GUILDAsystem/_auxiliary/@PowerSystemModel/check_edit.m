function flag = check_edit(obj)
% Build the handles that are not up to date and report whether initialize has run.
%
% Calls set_odefcn on every layer of the subtree whose s_odefcn is not "updated"
% ("unset": never built; "editted": a dynamics edit, a network Hz edit or an attach
% since the last build), parent before children. Called at the start of every
% analysis that uses the f_* handles: initialize, calculate_continuation_powerflow
% and, through PowerNetwork.require_equilibrium, solver_ODE.solve and
% solver_LIN.solve (net.simulate, net.linearize, net.get_sys); the get_sys of each
% layer; LocalController.validate; and Component.get_dx_algebraic and
% LocalController.get_dx_algebraic when the layer itself is not "updated" (a direct
% call; in a simulation the solver has already checked every layer). See
% PowerNetwork.check_edit.
    arguments (Input)
        obj
    end
    arguments (Output)
        flag % True when initialize has run; on PowerNetwork, also nothing that changes the equilibrium was edited since.
    end
    if obj.s_odefcn ~= "updated"
        obj.set_odefcn();
    end
    for a = reshape(obj.children, 1, [])
        if isa(a{1}, "PowerSystemModel")
            a{1}.check_edit();
        end
    end
    flag = obj.l_initialized;
end
