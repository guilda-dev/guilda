function initialize(obj, l_equilibrium)
% Bring the controller up to date (LocalController.initialize), designing the gain K
% when the generator has just set the equilibrium.
%
% With l_equilibrium = true (Component.set_equilibrium, during net.initialize) the
% handles, which bind K and the equilibrium, are marked stale; LocalController.initialize
% then clears the stale tag equilibrium and set_odefcn designs K and rebuilds them.
%
% <@Group> Called by analyses
    arguments (Input)
        obj
        l_equilibrium (1,1) logical = false  % The generator has just set the equilibrium.
    end
    if l_equilibrium
        obj.sct_stale.odefcn(end+1,1) = obj.s_tag + ": K redesigned";
    end
    initialize@LocalController(obj, l_equilibrium);
end
