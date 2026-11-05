function out = harrayfun(varargin)
% Apply a function to each array element and concatenate the results horizontally.
    arguments (Input, Repeating)
        varargin  % Inputs of arrayfun: function handle, arrays and Name-Value options.
    end
    arguments (Output)
        out       % Horizontal concatenation of the results.
    end
    out_ = arrayfun(varargin{:}, 'UniformOutput', false);
    out = horzcat(out_{:});
end
