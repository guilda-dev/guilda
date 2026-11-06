function flag = check_edit(obj)
% Rebuild the handles of the subtree and report whether initialize has run.
%
% Calls apply_edit("odefcn") on every layer of the subtree, parent before children,
% so the f_* handles always match the current parameters and network frequency.
% Called at the start of every analysis that uses the f_* handles: initialize,
% calculate_continuation_powerflow and, through PowerNetwork.require_equilibrium,
% solver_ODE.solve and solver_LIN.solve (net.simulate, net.linearize, net.get_sys);
% the get_sys of each layer; LocalController.validate; and Component.get_dx_algebraic
% and LocalController.get_dx_algebraic when the handles of the layer were never built
% (a direct call; in a simulation the solver has already built every layer). See
% PowerNetwork.check_edit.
    arguments (Input)
        obj
    end
    arguments (Output)
        flag % True when initialize has run; on PowerNetwork, also nothing that changes the equilibrium was edited since.
    end
    obj.apply_edit("odefcn");
    for a = reshape(obj.children, 1, [])
        if isa(a{1}, "PowerSystemModel")
            a{1}.check_edit();
        end
    end
    flag = obj.l_initialized;
end
