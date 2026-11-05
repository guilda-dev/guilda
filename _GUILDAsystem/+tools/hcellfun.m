function out = hcellfun(varargin)
% Apply a function to each cell and concatenate the results horizontally.
    arguments (Input, Repeating)
        varargin  % Inputs of cellfun: function handle, cell arrays and Name-Value options.
    end
    arguments (Output)
        out       % Horizontal concatenation of the results.
    end
    out_ = cellfun(varargin{:}, 'UniformOutput', false);
    out = horzcat(out_{:});
end
