function remove_global_controller(obj, str_GconTag)
% Remove global controllers by tag.
%
% The removed controllers no longer refer to this network.
%
% <@Examples>
% ```matlab
% net.remove_global_controller("agc")
% ```
%
% See also PowerNetwork.add_global_controller
    arguments
        obj
        str_GconTag (1,:) string   % Tags of the global controllers to remove.
    end
    str_tagGcon = string(obj.a_GlobalController);
    str_missing = str_GconTag(~ismember(str_GconTag, str_tagGcon));
    if ~isempty(str_missing)
        error('GUILDA:PowerNetwork:GconNotFound', '%s', ...
              msg('GUILDA:PowerNetwork:GconNotFound', char(join(str_missing,"', '")), char(obj.str_tag)))
    end
    lv_rm   = ismember(str_tagGcon, str_GconTag);
    a_rmGC  = obj.a_GlobalController(lv_rm);

    obj.a_GlobalController = obj.a_GlobalController(~lv_rm);
    obj.log_edit(obj.str_tag+" ---remove->> "+join(str_tagGcon(lv_rm),", "),"Topology");
    cellfun(@(g) g.set_parent([]), a_rmGC);
end
