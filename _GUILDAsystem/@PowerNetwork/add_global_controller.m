function add_global_controller(obj, a_Gcon)
    % the tag is given by the user, so a tag already in use is an error
    if ismember(a_Gcon.str_tag, string(obj.a_GlobalController))
        error('GUILDA:PowerNetwork:GconTagInUse', '%s', ...
              msg('GUILDA:PowerNetwork:GconTagInUse', char(a_Gcon.str_tag), char(obj.str_tag)))
    end
    obj.a_GlobalController = [obj.a_GlobalController; {a_Gcon}];
    a_Gcon.set_parent(obj);
    obj.log_edit(obj.str_tag+" <<-Add--- "+a_Gcon.str_tag,"Topology");
end