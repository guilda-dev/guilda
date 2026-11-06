function set_bus(obj,bus)
% Set the bus of the component; [] detaches it.
%
% Called by Bus.add_component, replace_component and remove_component. Attaching makes
% the equilibrium and the handles stale (the network frequency may differ).
%
% <@Group> Construction and editing
    arguments (Input)
        obj
        bus   % Bus of the component, or [] to detach it.
    end
    obj.a_Bus = bus;
    if ~isempty(bus)
        s_log = obj.s_tag + ": attached to " + bus.s_tag;
        obj.sct_stale.equilibrium(end+1,1) = s_log;
        obj.sct_stale.odefcn(end+1,1)      = s_log;
    end
end
