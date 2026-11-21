function initialize(obj, l_equilibrium)
% Bring the controller up to date (LocalController.initialize), designing the gain K first
% when the component has just set the equilibrium.
%
% With l_equilibrium = true (Component.set_equilibrium, during net.initialize) K is
% designed at the equilibrium of the component and the handles, which bind K, are marked
% stale; then LocalController.initialize clears the stale tag equilibrium and rebuilds them.
%
% <@Group> Called by analyses
    arguments (Input)
        obj
        l_equilibrium (1,1) logical = false  % The component has just set the equilibrium.
    end
    if l_equilibrium
        comp = obj.a_Component;
        [~, iv_u] = ismember(obj.sv_y, comp.sv_u);
        obj.rv_u0 = comp.rv_Uequilibrium(iv_u);
        obj.design_gain(comp.c_Vequilibrium, comp.rv_Uequilibrium);
        obj.sct_stale.odefcn(end+1,1) = obj.s_tag + ": K redesigned";
    end
    initialize@LocalController(obj, l_equilibrium);
end
