function c_unit = get_units(net)
% What getODEFunction reads for each component, fixed during a run
    arguments (Input)
        net  % Network of the run.
    end
    arguments (Output)
        c_unit  % One struct per component (fields ue, idx_U, idx_V, idx_I, comp).
    end
    c_comp = tools.cellfun(@(b) b.a_Component, net.a_Bus);
    c_comp = vertcat(cell(0,1), c_comp{:});
    c_unit = cell(size(c_comp));
    for i = 1:numel(c_comp)
        cj = c_comp{i};
        c_unit{i} = struct("ue", cj.rv_Uequilibrium, "idx_U", cj.iv_odeU, ...
                           "idx_V", cj.a_Bus.iv_odeX, "idx_I", cj.a_Bus.iv_odeI);
        c_unit{i}.comp = cj;           % not an argument of struct: Component overloads it
    end
end
