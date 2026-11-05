function remove_global_controller(obj, sr_GconTag)
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
%
% <@Group> Model building
    arguments (Input)
        obj
        sr_GconTag (1,:) string   % Tags of the global controllers to remove.
    end
    sv_tagGcon  = string(obj.a_GlobalController);
    sr_missing  = sr_GconTag(~ismember(sr_GconTag, sv_tagGcon));
    if ~isempty(sr_missing)
        error(msg("GUILDA:PowerNetwork:GconNotFound", char(join(sr_missing,"', '")), char(obj.s_tag)))
    end
    lv_rm   = ismember(sv_tagGcon, sr_GconTag);
    a_rmGC  = obj.a_GlobalController(lv_rm);

    obj.a_GlobalController = obj.a_GlobalController(~lv_rm);
    obj.log_edit(obj.s_tag+" ---remove->> "+join(sv_tagGcon(lv_rm),", "),"Topology");
    cellfun(@(g) g.set_parent([]), a_rmGC);
end
