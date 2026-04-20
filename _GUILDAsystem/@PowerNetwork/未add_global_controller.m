function add_global_controller(obj, a_Gcon, str_CompTag)
    arguments
        obj 
        a_Gcon      (1,1) GlobalController
        str_CompTag (:,1) string
    end
    a_Component    = tools.vcellfun(@(b) b.a_Component, obj.a_Bus );
    str_CompTagAll = cellfun(@(c) c.str_tag, a_Component );
    [~,iv_CompSpec]  = ismember(str_CompTag, str_CompTagAll);

    lv_lackSpec = iv_CompSpec==0;
    if any(lv_lackSpec)
        str_lackSpec  = str_Comptag(lv_lackSpec);
        char_lackSpec = cellfun(@(c)[c,','], str_lackSpec(:)');
        error("couldn't find Component >> [" +char_lackSpec(1:end-1)+ "]")
    end
    a_CompSpec = a_Component( iv_CompSpec );
    a_Gcon.set_component(a_CompSpec);
    obj.GlobalControllers = [obj.GlobalControllers; {a_GlobalController}];
    obj.log_edit('add Global Controller',"Topology")
end


function add_bus(obj, a_Bus)
    arguments
        obj 
        a_Bus (1,1) Bus
    end
    a_Bus.set_network(obj)
    obj.a_Bus = [obj.a_Bus;{a_Bus}];
    obj.log_edit(obj.str_tag+" <<-Add- "+a_Bus.str_tag,"Topology");
end