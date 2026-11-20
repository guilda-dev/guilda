function sct_value = tab_cpf_value(net)
% Initial LoadBus of the CPF form: the buses with a load (component.load.*) while net.solver_CPF.LoadBus is empty.
    arguments (Input)
        net (1,1) PowerNetwork  % Network of the form.
    end
    arguments (Output)
        sct_value (1,1) struct  % DrawerOptionDialog Value: LoadBus, or no field.
    end
    sct_value = struct();
    if ~isempty(net.solver_CPF.LoadBus)
        return
    end
    l_load = cellfun(@(b) any(cellfun(@(c) startsWith(class(c), "component.load."), b.a_Component)), net.a_Bus);
    sv_bus = string(cellfun(@(b) b.s_tag, net.a_Bus(l_load), "UniformOutput", false));
    if ~isempty(sv_bus)
        sct_value.LoadBus = "[" + join("""" + reshape(sv_bus, 1, []) + """", ", ") + "]";
    end
end
