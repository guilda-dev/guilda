function c_index = simulator_columns(net, tab)
% c_index{i}: columns of tab (the rows x, Vre, Vim, u of the variable map, which are the
% columns of the trajectories, see SolverODE.phase_result) for the view odeResults of bus
% i: the voltage, and the component's own states (not its controllers) and inputs.
    a_bus = net.a_Bus;
    n_bus = numel(a_bus);
    [tab_all, c_idxBus] = net.get_variable_map();
    n_lin = height(tab);
    if n_lin > height(tab_all) || ~isequal(string(tab.Label), string(tab_all.Label(1:n_lin)))
        error(msg("GUILDA:ResultODE:VariableMap"))
    end

    c_index = cell(n_bus,1);
    for i = 1:n_bus
        a_comp = a_bus{i}.a_Component;
        iv_bus = c_idxBus{i};
        iv_bus = iv_bus(iv_bus <= n_lin);
        s = struct();
        s.iv_V = iv_bus(tab.Kind(iv_bus) == "Vre" | tab.Kind(iv_bus) == "Vim");
        s.c_x  = cell(1, numel(a_comp));
        s.c_u  = cell(1, numel(a_comp));
        for j = 1:numel(a_comp)
            s_tag = string(a_comp{j}.s_tag);
            s.c_x{j} = iv_bus(tab.Kind(iv_bus) == "x" & tab.Owner(iv_bus) == s_tag);
            s.c_u{j} = iv_bus(tab.Kind(iv_bus) == "u" & tab.Owner(iv_bus) == s_tag);
        end
        c_index{i} = s;
    end
end
