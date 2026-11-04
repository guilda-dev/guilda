function move_local_controllers(obj, comp_new)
% Move the local controllers to another component, with the controllers nested in them.
%
% Each top-level controller (the AVR or "local" controller, and the governor) goes to the
% same slot of the new component.
%
% Called by Bus.replace_component, which checks first that the new component suits them.
%
% <@Group> Construction and editing
    a_con = obj.a_LocalController;
    obj.a_LocalController = cell(0,1);
    obj.l_hasController   = false;
    for k = 1:numel(a_con)
        a_con{k}.set_parent([])
        comp_new.add_local_controller(a_con{k})
    end
end
