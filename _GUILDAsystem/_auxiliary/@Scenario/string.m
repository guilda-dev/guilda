function str = string(obj)
% Tag of the scenario.
    arguments (Input)
        obj
    end
    arguments (Output)
        str % Tag string.
    end
    str = obj.s_tag;
end
