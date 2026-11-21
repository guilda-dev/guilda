function resolve_ports(obj, comp)
% The driven inputs: Input, or all the inputs of the component
    arguments (Input)
        obj
        comp  Component  % Component the controller is attached to.
    end
    obj.sv_y = obj.driven_inputs(comp);
end
