function remove_global_controller(obj, sr_GconTag)
% Remove global controllers by tag.
%
% The removed controllers are deleted, so a handle to them becomes invalid. A removal makes nothing stale:
% it changes no equilibrium, and simulate and get_sys take the controllers the network
% has.
%
% <@Examples>
% ```matlab
% agc = net.add_global_controller("agc-PI", ["B001SG1","B002SG1"]);
% net.remove_global_controller(agc.s_tag)
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
    tools.delete_layers(a_rmGC);
end
