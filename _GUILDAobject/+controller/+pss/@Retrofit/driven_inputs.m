function sv_in = driven_inputs(obj, comp)
% Names of the inputs of comp (the component, or the AVR for a PSS) that the
% controller drives once attached to it: Vpss of the AVR. Stops unless comp is the
% Static AVR. Component.add_local_controller calls it before anything changes (on
% attachment, and for the PSS that moves to a new AVR), so that a rejected call leaves
% the generator as it was.
    arguments (Input)
        obj
        comp  % The component, or the AVR for a PSS, the controller is to be attached to.
    end
    arguments (Output)
        sv_in  % Names of the driven inputs of comp ("Vpss").
    end
    if ~isa(comp, "controller.avr.Static")
        error(msg("GUILDA:Retrofit:ParentNotStatic", obj.s_tag, comp.s_tag, comp.key, obj.s_tag))
    end
    sv_in = obj.sv_y;
end
