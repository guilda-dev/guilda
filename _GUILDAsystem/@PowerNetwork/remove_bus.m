function remove_bus(obj, str_BusTag, opt)
% Remove buses by tag, together with their components.
%
% A branch connected to a removed bus would be left with a dangling end, so removing
% such a bus is an error unless `RemoveBranches` is true, which removes those branches
% too. A bus whose components are controlled by a global controller cannot be removed
% until that controller is removed. The removed buses (and branches) no longer refer to
% this network.
%
% <@Examples>
% ```matlab
% net.remove_bus("B010")
% net.remove_bus("B003", RemoveBranches=true)
% ```
%
% See also PowerNetwork.add_bus, PowerNetwork.remove_branch
    arguments
        obj
        str_BusTag (1,:) string   % Tags of the buses to remove.
        opt.RemoveBranches (1,1) logical = false   % Also remove the branches connected to the removed buses.
    end
    str_tagBus  = string(obj.a_Bus);
    str_missing = str_BusTag(~ismember(str_BusTag, str_tagBus));
    if ~isempty(str_missing)
        error('GUILDA:PowerNetwork:BusNotFound', '%s', ...
              msg('GUILDA:PowerNetwork:BusNotFound', char(join(str_missing,"', '")), char(obj.str_tag)))
    end
    lv_rmBus = ismember(str_tagBus, str_BusTag);
    a_rmBus  = obj.a_Bus(lv_rmBus);

    % global controllers must not keep controlling a removed component
    str_rmComp = tools.cellfun(@(b) string(b.a_Component), a_rmBus);
    str_rmComp = [string.empty(0,1); vertcat(str_rmComp{:})];
    for i = 1:numel(obj.a_GlobalController)
        gcon = obj.a_GlobalController{i};
        lv_ctrl = ismember(string(gcon.controlledUnits), str_rmComp);
        if any(lv_ctrl)
            str_ctrl = string(gcon.controlledUnits);
            error('GUILDA:PowerNetwork:BusHasControlledUnits', '%s', ...
                  msg('GUILDA:PowerNetwork:BusHasControlledUnits', char(join(str_ctrl(lv_ctrl),", ")), char(gcon.str_tag)))
        end
    end

    % branches connected to a removed bus
    lv_rmBranch = cellfun(@(br) any(ismember(string(br.a_Bus), str_BusTag)), obj.a_Branch);
    if any(lv_rmBranch)
        str_rmBranch = string(obj.a_Branch(lv_rmBranch));
        if ~opt.RemoveBranches
            error('GUILDA:PowerNetwork:BusHasBranches', '%s', ...
                  msg('GUILDA:PowerNetwork:BusHasBranches', char(join(str_BusTag,", ")), char(join(str_rmBranch,", "))))
        end
        obj.remove_branch(str_rmBranch);
    end

    obj.a_Bus = obj.a_Bus(~lv_rmBus);
    obj.log_edit(obj.str_tag+" ---remove->> "+join(str_tagBus(lv_rmBus),", "),"Topology");
    cellfun(@(b) b.set_network([]), a_rmBus);
end
