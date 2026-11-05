function sv = driven_inputs(obj, comp)
% Names of the inputs of the component comp that the controller drives once
% attached to it (Component.add_local_controller checks them before the
% attachment). sv_y by default; a controller whose outputs follow the component
% (e.g. controller.local_LQR) overrides this.
%
% <@Group> Internal helpers
    arguments (Input)
        obj
        comp   % Component the controller is to be attached to.
    end
    arguments (Output)
        sv (:,1) string   % Names of the driven inputs of comp.
    end
    sv = obj.sv_y;
end
