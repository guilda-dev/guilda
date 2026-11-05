function nx = get_nx(obj)
% Return the number of controller states.
    arguments (Input)
        obj
    end
    arguments (Output)
        nx % Number of states.
    end
    nx = obj.nx;
end
