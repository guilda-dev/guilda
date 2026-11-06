function remove_global_controller(obj, sr_GconTag)
% Remove global controllers by tag.
%
% The removed controllers no longer refer to this network. A removal makes nothing stale:
% it changes no equilibrium, and simulate and linearize take the controllers the network
% has.
%
% <@Examples>
% ```matlab
% agc = net.add_global_controller("agc-PI", ["SG1B001","SG1B002"]);
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
    for k = 1:numel(a_rmGC)
        a_rmGC{k}.a_PowerNetwork = [];
    end
end
