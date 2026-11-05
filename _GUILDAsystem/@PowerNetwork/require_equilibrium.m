function require_equilibrium(obj)
% Called at the start of solver_ODE.solve and solver_LIN.solve (the one place
% of this check for simulate, linearize and get_sys): build the f_* handles
% that are not up to date; error if net.initialize() is needed.
%
% <@Group> Called by analyses
    arguments (Input)
        obj
    end
    obj.check_edit("RequireEquilibrium", true);
end
