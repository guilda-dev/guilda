function log_change(obj, s_name)
% A weight edit changes K, which net.initialize recomputes
    arguments (Input)
        obj
        s_name    % Name of the edited weight.
    end
    if ~isempty(obj.a_Component)
        obj.log_edit(obj.s_tag + " edit " + s_name, "Parameter(dynamics)");
    end
end
