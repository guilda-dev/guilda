function out = varrayfun(varargin)
% Apply a function to each array element and concatenate the results vertically.
    arguments (Input, Repeating)
        varargin  % Inputs of arrayfun: function handle, arrays and Name-Value options.
    end
    arguments (Output)
        out       % Vertical concatenation of the results.
    end
    out_ = arrayfun(varargin{:}, 'UniformOutput', false);
    out = vertcat(out_{:});
end
