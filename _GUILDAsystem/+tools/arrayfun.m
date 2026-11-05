function varargout = arrayfun(varargin)
% Apply a function to each array element and return cells (arrayfun with UniformOutput=false).
    arguments (Input, Repeating)
        varargin   % Inputs of arrayfun: function handle, arrays and Name-Value options.
    end
    arguments (Output, Repeating)
        varargout  % Cell array of the results for each output of the function.
    end

    varargout = cell(nargout, 1);
    [varargout{:}] = arrayfun(varargin{:}, 'UniformOutput', false);

end
