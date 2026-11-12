function get_equilibrium(obj, V, u)
% Set the equilibrium of the controller and design the gain K.
% The component calls this after its equilibrium is set: the observed
% signals of the controller are the states `x*` and its outputs the
% driven inputs `u*` of the component.
    arguments (Input)
        obj
        V  % [pu] Complex terminal voltage of the component at the equilibrium.
        u  % Equilibrium input of the component (in the order of its sv_u).
    end
    comp = obj.a_Component;    % role "local": always on the component
    [~, iv_u] = ismember(obj.sv_y, comp.sv_u);

    obj.rv_Xequilibrium = zeros(0,1);
    obj.rv_Uequilibrium = comp.rv_Xequilibrium;
    obj.rv_u0 = u(iv_u);
    obj.design_gain(V, u);
    % the handles bind K: mark them stale so that set_odefcn rebuilds them
    obj.sct_stale.odefcn(end+1,1) = obj.s_tag + ": K redesigned";
    obj.set_odefcn();
end
