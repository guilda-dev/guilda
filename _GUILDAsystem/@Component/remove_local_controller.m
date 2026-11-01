function remove_local_controller(obj, str_tag, opt)
% Remove a local controller from the component by tag.
%
% An AVR that still has a PSS feeding it cannot be removed unless `RemoveNested` is true,
% which removes the PSS too. Remove the PSS alone by its own tag. The removed controllers
% no longer refer to this component or to each other, so they can be attached again.
% The removal is logged as a "Topology" edit, so the equilibrium becomes stale.
%
% <@Examples>
% ```matlab
% gen = net.a_Bus{1}.a_Component{1};
% gen.add_local_controller(controller.avr.AVR_ST1("1"), controller.pss.PSS1("1"));
% gen.remove_local_controller("CP1");                     % the PSS only (tag: str_tag)
% gen.add_local_controller(controller.pss.PSS1("2"));
% gen.remove_local_controller("CA1", RemoveNested=true);  % the AVR and its PSS
% ```
%
% See also Component.add_local_controller, LocalController
    arguments
        obj
        str_tag (1,1) string   % Tag (str_tag) of the local controller to remove.
        opt.RemoveNested (1,1) logical = false   % Also remove the controller nested in the removed one (the PSS under an AVR).
    end
    if isempty(obj.a_LocalController)
        top = [];
        a_nested = cell(0,1);
    else
        top = obj.a_LocalController{1};
        a_nested = top.a_LocalController;
    end

    if ~isempty(top) && top.str_tag == str_tag
        % Checked before anything changes, so a rejected call leaves the component as it was
        if ~isempty(a_nested) && ~opt.RemoveNested
            error('GUILDA:Component:ControllerHasNested', '%s', ...
                  msg('GUILDA:Component:ControllerHasNested', char(str_tag), char(a_nested{1}.str_tag)))
        end
        str_removed = str_tag;
        if ~isempty(a_nested)
            str_removed = str_tag+", "+a_nested{1}.str_tag;
        end
        obj.a_LocalController = cell(0,1);
        obj.l_hasController = false;
        obj.log_edit(obj.str_tag+" ---remove->> "+str_removed, "Topology");
        top.remove_local_controller();
        top.set_parent([])
        cellfun(@(con) con.set_parent([]), a_nested);
    elseif ~isempty(a_nested) && a_nested{1}.str_tag == str_tag
        obj.log_edit(obj.str_tag+" ---remove->> "+str_tag, "Topology");
        top.remove_local_controller();
        a_nested{1}.set_parent([])
    else
        error('GUILDA:Component:ControllerNotFound', '%s', ...
              msg('GUILDA:Component:ControllerNotFound', char(str_tag), char(obj.str_tag)))
    end
end
