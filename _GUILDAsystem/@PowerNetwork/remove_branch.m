function remove_branch(obj,i_branch)
    arguments
        obj 
        i_branch          (1,1) double {mustBePositive,mustBeInteger}
    end
    obj.Branches{i_branch}.disband;
    obj.Branches{i_branch} = branch.empty;
    obj.onEdit("remove Branch"+i_branch);
end