function remove_branch(obj,tag)
% Remove branches by tag.
%
% A tag that is not found is an error, and then nothing is removed. The removed branches
% no longer refer to this network or its buses.
%
% <@Examples>
% ```matlab
% net.remove_branch("EL001")
% net.remove_branch(["EL001","EL002"])
% ```
%
% See also PowerNetwork.add_branch, PowerNetwork.remove_bus
%
% <@Group> Model building
    arguments (Input)
        obj
        tag string   % Tags of the branches to remove.
    end
    branch_tag = string(obj.a_Branch);
    sr_missing = tag(~ismember(tag, branch_tag));
    if ~isempty(sr_missing)
        error(msg("GUILDA:PowerNetwork:BranchNotFound", char(join(sr_missing(:),"', '")), char(obj.s_tag)))
    end
    lv_branch  = ismember(branch_tag,tag);

    % The removed branches no longer refer to this network or its buses
    a_removed    = obj.a_Branch(lv_branch);
    obj.a_Branch = obj.a_Branch(~lv_branch);
    if any(lv_branch)
        obj.log_edit(obj.s_tag+" ---remove->> "+join(branch_tag(lv_branch),", "),"Topology");
    end
    cellfun(@(b) b.set_bus(cell(0,1)), a_removed);
    cellfun(@(b) b.set_network([]),    a_removed);
end
