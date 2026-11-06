function move_local_controllers(obj, comp_new)
% Move the local controllers to another component, with the controllers nested in them.
%
% Each top-level controller (the AVR or "local" controller, and the governor) goes to the
% same slot of the new component.
%
% Called by Bus.replace_component, which checks first that the new component suits them.
%
% <@Group> Construction and editing
    arguments (Input)
        obj
        comp_new (1,1) Component   % Component that receives the controllers.
    end
    % a_LocalController is already in the slot order (the AVR or "local" controller, then the governor)
    a_con = obj.a_LocalController;
    obj.a_LocalController = cell(0,1);
    obj.l_hasController   = false;
    comp_new.a_LocalController = a_con;
    for k = 1:numel(a_con)
        a_con{k}.a_Component = comp_new;
        a_con{k}.resolve_observe();
        a_con{k}.log_edit("attached to " + comp_new.s_tag, "Topology");
        comp_new.log_edit(comp_new.s_tag+" <<-Add--- "+a_con{k}.s_tag, "Topology");
    end
    comp_new.l_hasController = ~isempty(a_con);
end
