function remove_bus(obj, sr_BusTag, opt)
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
%
% <@Group> Model building
    arguments (Input)
        obj
        sr_BusTag (1,:) string   % Tags of the buses to remove.
        opt.RemoveBranches (1,1) logical = false   % Also remove the branches connected to the removed buses.
    end
    sv_tagBus   = string(obj.a_Bus);
    sr_missing  = sr_BusTag(~ismember(sr_BusTag, sv_tagBus));
    if ~isempty(sr_missing)
        error(msg("GUILDA:PowerNetwork:BusNotFound", char(join(sr_missing,"', '")), char(obj.s_tag)))
    end
    lv_rmBus = ismember(sv_tagBus, sr_BusTag);
    a_rmBus  = obj.a_Bus(lv_rmBus);

    % global controllers must not keep controlling a removed component
    sv_rmComp  = tools.cellfun(@(b) string(b.a_Component), a_rmBus);
    sv_rmComp  = [string.empty(0,1); vertcat(sv_rmComp{:})];
    for i = 1:numel(obj.a_GlobalController)
        gcon = obj.a_GlobalController{i};
        lv_ctrl = ismember(string(gcon.controlledUnits), sv_rmComp);
        if any(lv_ctrl)
            sv_ctrl = string(gcon.controlledUnits);
            error(msg("GUILDA:PowerNetwork:BusHasControlledUnits", char(join(sv_ctrl(lv_ctrl),", ")), char(gcon.s_tag)))
        end
    end

    % branches connected to a removed bus
    lv_rmBranch = cellfun(@(br) any(ismember(string(br.a_Bus), sr_BusTag)), obj.a_Branch);
    if any(lv_rmBranch)
        sv_rmBranch = string(obj.a_Branch(lv_rmBranch));
        if ~opt.RemoveBranches
            error(msg("GUILDA:PowerNetwork:BusHasBranches", char(join(sr_BusTag,", ")), char(join(sv_rmBranch,", "))))
        end
        obj.remove_branch(sv_rmBranch);
    end

    obj.a_Bus = obj.a_Bus(~lv_rmBus);
    obj.log_edit(obj.s_tag+" ---remove->> "+join(sv_tagBus(lv_rmBus),", "),"Topology");
    cellfun(@(b) b.set_network([]), a_rmBus);
end
