function remove_bus(obj, str_BusTag)
    arguments
        obj 
        str_BusTag (1,:) string
    end

    str_BusTagAll   = string(obj.a_Bus);
    for str_BusTagi = str_BusTag
        lv_rmbus    = str_BusTagAll==str_BusTagi;
        if ~any(lv_rmbus)
            error("No Bus with '"+str_BusTagi+"' was found.")
        end
        a_rmbus = obj.a_Bus{lv_rmbus};
        cellfun(@(c) a_rmbus.remove_cubicle(c), a_rmbus.a_Cubicle)
        obj.a_Bus(lv_rmbus)     = [];
        str_BusTagAll(lv_rmbus) = [];
        obj.log_edit(obj.str_tag+" ---Remove->> "+a_rmbus.str_tag,"Topology");
    end
end