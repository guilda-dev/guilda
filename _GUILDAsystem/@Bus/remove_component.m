function remove_component(obj, s_tag)
% Remove a component from the bus by tag.
%
% The removed component no longer refers to this bus. The removal is a
% "Topology" edit, which makes the power flow of the network stale. A tag that is not found is an error. A component controlled by a global
% controller cannot be removed.
%
% See also Bus.add_component
%
% <@Group> Construction and editing
    arguments (Input)
        obj 
        s_tag (1,1) string   % Tag of the component to remove.
    end
    sv_tagComp = string(obj.a_Component);
    lv_rmcub = sv_tagComp==s_tag;
    if ~any(lv_rmcub)
        error(msg("GUILDA:Bus:ComponentNotFound", char(s_tag), char(obj.s_tag)))
    end
    comp = obj.a_Component{lv_rmcub};
    s_gcon = controlling_gcon(obj, comp);
    if s_gcon ~= ""
        error(msg("GUILDA:Bus:ComponentControlled", char(comp.s_tag), char(s_gcon)))
    end
    obj.a_Component(lv_rmcub) = [];
    obj.log_edit(obj.s_tag+" ---remove->> "+s_tag,"Topology")
    comp.a_Bus = [];    % the removed component no longer reads this bus (c_Vequilibrium = [])
end
