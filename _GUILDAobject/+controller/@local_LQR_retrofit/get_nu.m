function nu = get_nu(obj)
% Return the number of controller outputs (2).
    arguments (Input)
        obj
    end
    arguments (Output)
        nu % Number of outputs.
    end
    nu = 2;
end
