function replace_branch(obj,BranchInstance,i_branch)
    arguments
        obj 
        BranchInstance (1,1) Branch
        i_branch          (1,1) double {mustBePositive,mustBeInteger}
    end
    BranchInstance.checkParent;
    BranchInstance.belong(obj, i_branch)
    BranchInstance.connect_bus( obj.Branches{i_branch}.from, obj.Branches{i_branch}.to)
    obj.Branches{i_branch}.disband;
    obj.Branches{i_branch} = BranchInstance;
    obj.onEdit("replace Branch"+i_branch);
end
