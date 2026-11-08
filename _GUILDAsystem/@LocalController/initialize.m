function initialize(obj, l_equilibrium)
% Bring the controller and its nested controller up to date (PowerNetwork.initialize,
% through Component.initialize or Component.set_equilibrium).
%
% With l_equilibrium = true the component has just computed the equilibria of its
% controllers, so the stale tag equilibrium is cleared. Then the handles are rebuilt when
% they are stale (the stale tag odefcn, or a network frequency other than r_odefcnHz),
% and the nested controller is initialized with the same l_equilibrium.
%
% <@Group> Called by analyses
    arguments (Input)
        obj
        l_equilibrium (1,1) logical = false  % The component has just set the equilibrium.
    end
    if l_equilibrium
        obj.sct_stale.equilibrium = strings(0,1);
    end
    obj.set_odefcn();
    for k = 1:numel(obj.a_LocalController)
        obj.a_LocalController{k}.initialize(l_equilibrium);
    end
end
