function mark_odefcn(obj)
% Mark the built handles of the layer and its descendants as "editted", for a change
% of the frequency they read: a network Hz edit (PowerNetwork.handle_edit) and an
% attach (Component.set_bus, LocalController.set_parent, GlobalController.set_parent).
% check_edit builds them at the next analysis. Handles never built stay "unset".
    arguments (Input)
        obj
    end
    if obj.s_odefcn == "updated"
        obj.s_odefcn = "editted";
    end
    for a = reshape(obj.children, 1, [])
        if isa(a{1}, "PowerSystemModel")
            a{1}.mark_odefcn();
        end
    end
end
