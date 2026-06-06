function remove_branch(obj,tag)
    branch_tag = string(obj.a_Branch);
    lv_branch  = ismember(branch_tag,tag);

    obj.a_Branch = obj.a_Branch(~lv_branch);
end