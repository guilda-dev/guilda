function remove_branch(obj,tag)
    branch_tag = string(obj.a_Branch);
    lv_branch  = ismember(branch_tag,tag);

    obj.a_Branch = obj.a_Branch(~lv_branch);
    if any(lv_branch)
        obj.log_edit(obj.str_tag+" ---remove->> "+join(branch_tag(lv_branch),", "),"Topology");
    end
end