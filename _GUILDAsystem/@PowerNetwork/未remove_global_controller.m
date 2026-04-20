function remove_global_controller(obj,str_GconTag)
    arguments
        obj 
        str_GconTag (:,1) string
    end
    str_GconTagAll   = cellfun(@(b) b.str_tag,  obj.a_GlobalController );
    lv_GconTagSpec   = ismember(str_GconTagAll, str_GconTag);
    
    if any(lv_GconTagSpec)
        disp("Remove Global Controller")
        cellfun(@(s) disp(" >> "+s), str_GconTagAll(lv_GconTagSpec))
    else
        warning("The corresponding GlobalController class was not found")
    end

    obj.a_GlobalController(lv_GconTagSpec) = [];
    obj.log_edit("remove GlobalController","Topology");
end