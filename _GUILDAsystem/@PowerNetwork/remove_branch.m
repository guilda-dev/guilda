function remove_branch(obj,tag)
    branch_tag = string(obj.a_Branch);
    lv_branch  = ismember(branch_tag,tag);

    % The removed branches no longer refer to this network or its buses
    a_removed    = obj.a_Branch(lv_branch);
    obj.a_Branch = obj.a_Branch(~lv_branch);
    if any(lv_branch)
        obj.log_edit(obj.str_tag+" ---remove->> "+join(branch_tag(lv_branch),", "),"Topology");
    end
    cellfun(@(b) b.set_bus(cell(0,1)), a_removed);
    cellfun(@(b) b.set_network([]),    a_removed);
end
