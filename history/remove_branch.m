function remove_branch(obj,str_BranchTag)
    arguments
        obj 
        str_BranchTag (1,:) string
    end
    str_BranchTagAll   = string( obj.a_Branch );
    for str_BranchTagi = str_BranchTag
        lv_rmline = str_BranchTagAll==str_BranchTagi;
        if ~any(lv_rmline)
            warning("No Branch with '"+str_BranchTagi+"' was found.")
        else
            a_rmline = obj.a_Branch{lv_rmline};
            for i =1:2 
                a_rmcub = a_rmline.a_Cubicle{i};
                a_rmbus = a_rmcub.a_Bus;
                if isa(a_rmbus,"Bus")
                    a_rmbus.remove_cubicle(a_rmcub)
                end
            end
            obj.a_Branch(lv_rmline)    = [];
            str_BranchTagAll(lv_rmline) = [];
            obj.log_edit(obj.str_tag+" ---Remove->> "+a_rmline.str_tag,"Topology");
        end
    end
end