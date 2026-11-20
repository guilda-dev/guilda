function sv_in = driven_inputs(obj, comp)
% The driven inputs on the component comp: Input, or all the inputs of comp
    arguments (Input)
        obj
        comp  Component  % Component the controller is attached to.
    end
    arguments (Output)
        sv_in  % Names of the driven inputs on comp.
    end
    if isempty(obj.sv_input)
        sv_in = reshape(string(comp.sv_u), [], 1);
    else
        sv_in = obj.sv_input;   % checked by Component.add_local_controller
    end
end
