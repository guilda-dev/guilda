function str = default_port(obj)
% Port of the result (options.Port), "PQ" when it has none: the default Port of get_ss and plot_matrix
    arguments (Input)
        obj ResultLIN  % The result.
    end
    arguments (Output)
        str (1,1) string  % "PI", "PQ" or "I".
    end
    str = "PQ";
    if isfield(obj.options, "Port")
        str = obj.options.Port;
    end
end
