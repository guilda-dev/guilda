function remove_local_controller(obj, s_tag, opt)
% Remove a local controller from the component by tag.
%
% The tag can name a top-level controller (the AVR or "local" controller, or the
% governor) or the PSS under the AVR; the other top-level controller stays attached.
% An AVR that still has a PSS feeding it cannot be removed unless `RemoveNested` is true,
% which removes the PSS too. Remove the PSS alone by its own tag. The removed controllers
% no longer refer to this component or to each other, so they can be attached again.
% The removal is a "Topology" edit, so the equilibrium of the component becomes stale.
%
% <@Examples>
% ```matlab
% gen = net.a_Bus{1}.a_Component{1};
% gen.add_local_controller(controller.avr.AVR_ST1("1"), controller.pss.PSS1("1"));
% gen.remove_local_controller("CP1");                     % the PSS only (tag: s_tag)
% gen.add_local_controller(controller.pss.PSS1("2"));
% gen.remove_local_controller("CA1", RemoveNested=true);  % the AVR and its PSS
% gen.add_local_controller(controller.governor.IEEJ_LPT1("1"));
% gen.remove_local_controller("CG1");                     % the governor
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
        top.remove_local_controller();
        top.a_Component = [];
        for m = 1:numel(a_nested)
            a_nested{m}.a_Component = [];
        end
        return
    end

    for k = 1:numel(a_top)
        top = a_top{k};
        a_nested = top.a_LocalController;
        if ~isempty(a_nested) && a_nested{1}.s_tag == s_tag
            obj.log_edit(obj.s_tag+" ---remove->> "+s_tag, "Topology");
            top.remove_local_controller();
            a_nested{1}.a_Component = [];
            return
        end
    end
    error(msg("GUILDA:Component:ControllerNotFound", char(s_tag), char(obj.s_tag)))
end
