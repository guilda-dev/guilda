function move_local_controllers(obj, comp_new)
% Move the local controllers to another component, with the controllers nested in them.
%
% Each top-level controller (the AVR or "local" controller, and the governor) goes to the
% same slot of the new component. The default Static controllers (controller.avr.Static,
% controller.governor.Static) do not move: they stay on this component, and the new
% component keeps its own defaults in the slots that no moved controller takes (the
% defaults it loses are deleted). A PSS under the Static AVR moves under the Static AVR of
% the new component.
%
% Called by Bus.replace_component, which checks first that the new component suits them.
%
% <@Group> Construction and editing
    arguments (Input)
        obj
        comp_new (1,1) Component  % Component that receives the controllers.
    end
    % a_LocalController is already in the slot order (the AVR or "local" controller, then the governor)
    lv_move = ~cellfun(@is_static_controller, obj.a_LocalController);
    a_con   = obj.a_LocalController(lv_move);
    obj.a_LocalController = obj.a_LocalController(~lv_move);
    obj.l_hasController   = ~isempty(obj.a_LocalController);
    % the moved controllers first, so that they take the slot of a default of the same role
    a_all  = [a_con; comp_new.a_LocalController];
    lv_gov = cellfun(@(c) c.s_role == "governor", a_all);
    iv_keep = [find(~lv_gov, 1); find(lv_gov, 1)];
    a_lost = a_all(setdiff(1:numel(a_all), iv_keep));
    comp_new.a_LocalController = a_all(iv_keep);
    tools.delete_layers(a_lost);
    % a PSS under the Static AVR left here goes under the AVR slot of the new component
    for k = 1:numel(obj.a_LocalController)
        avr_pre = obj.a_LocalController{k};
        if avr_pre.s_role == "avr" && ~isempty(avr_pre.a_LocalController)
            a_pss   = avr_pre.a_LocalController;
            avr_new = comp_new.a_LocalController{cellfun(@(c) c.s_role == "avr", comp_new.a_LocalController)};
            avr_pre.remove_local_controller();
            avr_new.add_local_controller(a_pss{1});
            a_pss{1}.a_Component = avr_new;
            a_pss{1}.resolve_observe();
            a_pss{1}.log_edit("attached to " + avr_new.s_tag, "Topology");
            comp_new.log_edit(comp_new.s_tag+" <<-Add--- "+a_pss{1}.s_tag, "Topology");
        end
    end
    for k = 1:numel(a_con)
        a_con{k}.a_Component = comp_new;
        a_con{k}.resolve_observe();
        a_con{k}.log_edit("attached to " + comp_new.s_tag, "Topology");
        comp_new.log_edit(comp_new.s_tag+" <<-Add--- "+a_con{k}.s_tag, "Topology");
    end
    comp_new.l_hasController = ~isempty(comp_new.a_LocalController);
end
