function add_global_controller(obj, a_Gcon)
% Add a global controller to the network.
%
% `a_Gcon` is a GlobalController built for this network; its tag must not be in use
% yet. The addition is logged as a "Topology" edit.
%
% See also PowerNetwork.remove_global_controller, GlobalController
    if ismember(a_Gcon.str_tag, string(obj.a_GlobalController))
        error('GUILDA:PowerNetwork:GconTagInUse', '%s', ...
              msg('GUILDA:PowerNetwork:GconTagInUse', char(a_Gcon.str_tag), char(obj.str_tag)))
    end
    obj.a_GlobalController = [obj.a_GlobalController; {a_Gcon}];
    a_Gcon.set_parent(obj);
    obj.log_edit(obj.str_tag+" <<-Add--- "+a_Gcon.str_tag,"Topology");
end