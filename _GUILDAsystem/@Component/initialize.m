function initialize(obj)
% Bring the component and its local controllers up to date (PowerNetwork.initialize,
% through Bus.initialize, after the power flow is written).
%
% Rebuilds the handles when they are stale. When the equilibrium of the component or of
% one of its local controllers is still stale, recomputes it from the held V and I
% (set_equilibrium; the power flow is up to date by then). Then initializes the local
% controllers.
%
% <@Group> Called by analyses
    arguments (Input)
        obj
    end
    if obj.odefcn_stale()
        obj.build_odefcn();
    end
    if equilibrium_stale(obj)
        obj.set_equilibrium(obj.c_Vequilibrium, obj.c_Iequilibrium);
    end
    for k = 1:numel(obj.a_LocalController)
        obj.a_LocalController{k}.initialize();
    end
end


function l = equilibrium_stale(layer)
% True when the equilibrium of layer or of a controller below it is stale
    l = ~isempty(layer.sct_stale.equilibrium);
    k = 1;
    while ~l && k <= numel(layer.a_LocalController)
        l = equilibrium_stale(layer.a_LocalController{k});
        k = k + 1;
    end
end
