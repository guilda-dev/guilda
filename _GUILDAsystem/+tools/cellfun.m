function varargout = cellfun(varargin)
% Apply a function to each cell and return cells (cellfun with UniformOutput=false).
    arguments (Input, Repeating)
        varargin   % Inputs of cellfun: function handle, cell arrays and Name-Value options.
    end
    arguments (Output, Repeating)
        varargout  % Cell array of the results for each output of the function.
    end

    varargout = cell(nargout, 1);
    [varargout{:}] = cellfun(varargin{:}, 'UniformOutput', false);

end
