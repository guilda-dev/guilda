function remove_local_controller(obj, s_tag, opt)
% Remove a local controller from the component by tag.
%
% The tag can name a top-level controller (the AVR or "local" controller, or the
% governor) or the PSS under the AVR; the other top-level controller stays attached.
% An AVR that still has a PSS feeding it cannot be removed unless `RemoveNested` is true,
% which removes the PSS too. Remove the PSS alone by its own tag. The removed controllers
% are deleted, so a handle to them becomes invalid.
% The removal is a "Topology" edit, so the equilibrium of the component becomes stale.
% When a global controller controls the component and the edit changes where one of its
% outputs goes (the "global" rows of net.get_variable_map), an INFO message
% (GUILDA:Component:GconRouteChanged) lists the outputs that go elsewhere now.
%
% <@Examples>
% ```matlab
% gen = net.a_Bus{1}.a_Component{1};
% avr = gen.add_local_controller("avr-ST1");
% pss = gen.add_local_controller("pss-PSS1");
% gen.remove_local_controller(pss.s_tag);                       % the PSS only
% gen.add_local_controller("pss-PSS1");
% gen.remove_local_controller(avr.s_tag, RemoveNested=true);    % the AVR and its PSS
% gov = gen.add_local_controller("gov-LPT1");
% gen.remove_local_controller(gov.s_tag);                       % the governor
% ```
%
% See also Component.add_local_controller, LocalController
%
% <@Group> Construction and editing
    arguments (Input)
        obj
        s_tag (1,1) string   % Tag (s_tag) of the local controller to remove.
        opt.RemoveNested (1,1) logical = false   % Also remove the controller nested in the removed one (the PSS under an AVR).
    end
    a_top = obj.a_LocalController;
    sv_top = string(cellfun(@(con) char(con.s_tag), a_top, 'UniformOutput', false));
    sm_route = gc_routes(obj);      % connections of the global controllers before the edit
    k_top = find(sv_top == s_tag, 1);

    if ~isempty(k_top)
        top = a_top{k_top};
        a_nested = top.a_LocalController;
        % Checked before anything changes, so a rejected call leaves the component as it was
        if ~isempty(a_nested) && ~opt.RemoveNested
            error(msg("GUILDA:Component:ControllerHasNested", char(s_tag), char(a_nested{1}.s_tag)))
        end
        s_removed = s_tag;
        if ~isempty(a_nested)
            s_removed = s_tag+", "+a_nested{1}.s_tag;
        end
        obj.a_LocalController(k_top) = [];
        obj.l_hasController = ~isempty(obj.a_LocalController);
        obj.log_edit(obj.s_tag+" ---remove->> "+s_removed, "Topology");
        tools.delete_layers({top});    % with the nested controller
        gc_routes(obj, sm_route);   % INFO when an output of a global controller goes elsewhere now
        return
    end

    for k = 1:numel(a_top)
        top = a_top{k};
        a_nested = top.a_LocalController;
        if ~isempty(a_nested) && a_nested{1}.s_tag == s_tag
            obj.log_edit(obj.s_tag+" ---remove->> "+s_tag, "Topology");
            top.remove_local_controller();
            tools.delete_layers(a_nested);
            gc_routes(obj, sm_route);
            return
        end
    end
    error(msg("GUILDA:Component:ControllerNotFound", char(s_tag), char(obj.s_tag)))
end
