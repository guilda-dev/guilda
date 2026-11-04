function remove_component(obj, str_tag)
% Remove a component from the bus by tag.
%
% The removed component no longer refers to this bus. The removal is logged as a
% "Topology" edit. A tag that is not found is an error. A component controlled by a global
% controller cannot be removed.
%
% See also Bus.add_component
%
% <@Group> Construction and editing
    arguments
        obj 
        str_tag (1,1) string   % Tag of the component to remove.
    end
    str_tagComp = string(obj.a_Component);
    lv_rmcub = str_tagComp==str_tag;
    if ~any(lv_rmcub)
        error(msg("GUILDA:Bus:ComponentNotFound", char(str_tag), char(obj.str_tag)))
    end
    comp = obj.a_Component{lv_rmcub};
    str_gcon = controlling_gcon(obj, comp);
    if str_gcon ~= ""
        error(msg("GUILDA:Bus:ComponentControlled", char(comp.str_tag), char(str_gcon)))
    end
    obj.a_Component(lv_rmcub) = [];
    obj.log_edit(obj.str_tag+" ---remove->> "+str_tag,"Topology")
    comp.set_bus([])    % the removed component no longer reads this bus (c_Vequilibrium = [])
end
