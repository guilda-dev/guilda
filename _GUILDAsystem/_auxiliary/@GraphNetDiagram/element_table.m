function tab = element_table(obj)
% Elements of the diagram: the buses, components, branches and links (tag of their component).
    arguments (Input)
        obj
    end
    arguments (Output)
        tab table  % Tag, Kind and Index of every element.
    end
    n_b = obj.n_bus;
    n_c = obj.n_component;
    n_e = obj.n_branch;
    Tag   = [obj.sv_bus(:); obj.sv_componentTag(:); obj.sv_branch(:); obj.sv_componentTag(:)];
    Kind  = [repmat("bus", n_b, 1); repmat("component", n_c, 1); repmat("branch", n_e, 1); repmat("link", n_c, 1)];
    Index = [(1:n_b)'; (1:n_c)'; (1:n_e)'; (1:n_c)'];
    tab = table(Tag, Kind, Index);
end
