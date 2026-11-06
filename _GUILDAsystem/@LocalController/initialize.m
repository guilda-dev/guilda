function initialize(obj)
% Rebuild the stale handles of the controller and of its nested controller
% (PowerNetwork.initialize, through Component.initialize).
%
% The equilibrium of a controller is computed by its component: Component.initialize
% calls set_equilibrium when the equilibrium of the component or of one of its
% controllers is stale.
%
% <@Group> Called by analyses
    arguments (Input)
        obj
    end
    if obj.odefcn_stale()
        obj.build_odefcn();
    end
    for k = 1:numel(obj.a_LocalController)
        obj.a_LocalController{k}.initialize();
    end
end
