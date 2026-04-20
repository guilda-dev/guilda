function remove_component(obj, str_tag)
    arguments
        obj 
        str_tag (1,1) string
    end
    str_tagComp = string(obj.a_Component);
    lv_rmcub = str_tagComp==str_tag;
    if ~any(lv_rmcub)
        error("No component with '"+str_tag+"' was found.")
    end
    obj.a_Component(lv_rmcub) = [];
    obj.log_edit(obj.str_tag+" ---remove->> "+str_tag,"Topology")
end