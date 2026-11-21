function sv = driven_inputs(obj, comp)
% Names of the inputs of comp (the component, or the AVR for a PSS) that the
% controller drives once attached to it (Component.add_local_controller checks them
% before the attachment, and for a PSS that moves to a new AVR, before the AVR is
% replaced). sv_y by default; a controller whose outputs follow the component (e.g.
% controller.local_LQR) or that suits only some parents (controller.pss.Retrofit)
% overrides this.
%
% <@Group> Internal helpers
    arguments (Input)
        obj
        comp  % The component, or the AVR for a PSS, the controller is to be attached to.
    end
    arguments (Output)
        sv (:,1) string  % Names of the driven inputs of comp.
    end
    sv = obj.sv_y;
end
