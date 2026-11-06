function log_change(obj, s_name)
% A weight edit changes K, which net.initialize recomputes (tag "dynamics" on the
% controller itself: LocalController.handle_edit marks equilibrium and odefcn)
    arguments (Input)
        obj
        s_name    % Name of the edited weight.
    end
    if ~isempty(obj.a_Component)
        obj.log_edit("edit " + s_name + ": " + tools.value_text(obj.(s_name)), "dynamics");
    end
end
