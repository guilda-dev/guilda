function reflect_arrow_forward(obj)
    arguments (Input)
        obj
    end
    rm_Varg = angle(obj.cm_Vbranch);
    obj.BranchDirection = -diff(rm_Varg).';
    obj.LinkDirection = obj.rv_Pcomp(:);
end