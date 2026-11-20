function resolve_ports(obj, comp)
% The states: one copy "hat_" + name for each state of the generator
    arguments (Input)
        obj
        comp  Component  % Generator the controller observes.
    end
    obj.sv_x = "hat_" + reshape(string(comp.sv_x), [], 1);
end
