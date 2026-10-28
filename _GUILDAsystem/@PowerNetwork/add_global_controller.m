function add_global_controller(obj, a_Gcon)
    obj.a_GlobalController = [obj.a_GlobalController; {a_Gcon}];
    a_Gcon.set_parent(obj);
    obj.log_edit(obj.str_tag+" <<-Add--- "+a_Gcon.str_tag,"Topology");
end