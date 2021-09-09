function add_branch(obj, branch)
if iscell(branch)
    if any(tools.vcellfun(@(l) ~isa(l, 'branch'), branch))
       error();
    end
    obj.a_branch = [obj.a_branch; branch];
else
    if isa(branch, 'branch')
        obj.a_branch = [obj.a_branch; {branch}];
    else
       error(); 
    end
end
end