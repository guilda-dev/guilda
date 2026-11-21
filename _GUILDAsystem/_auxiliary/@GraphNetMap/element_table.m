function tab = element_table(obj)
% Elements of the map: the buses, then the branches.
    arguments (Input)
        obj
    end
    arguments (Output)
        tab table  % Tag, Kind and Index of every element.
    end
    sv_bus = obj.sct_data.sv_bus;
    sv_br  = obj.sct_data.sv_branch;
    n_b = numel(sv_bus);
    n_e = numel(sv_br);
    Tag   = [sv_bus; sv_br];
    Kind  = [repmat("bus", n_b, 1); repmat("branch", n_e, 1)];
    Index = [(1:n_b)'; (1:n_e)'];
    tab = table(Tag, Kind, Index);
end
