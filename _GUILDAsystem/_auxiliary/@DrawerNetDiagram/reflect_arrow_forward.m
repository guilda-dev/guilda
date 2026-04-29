function reflect_arrow_forward(obj)
    rm_Varg = angle(obj.cm_Vbranch);
    obj.EdgeB2B_forward = diff(rm_Varg).';
    obj.EdgeB2C_forward = obj.rv_Pcomp(:);
end