function varargout = darrayfun(varargin)
% Apply a function to each array element and stack the results block-diagonally.
    arguments (Input, Repeating)
        varargin   % Inputs of arrayfun: function handle, arrays and Name-Value options.
    end
    arguments (Output, Repeating)
        varargout  % Block-diagonal stack (blkdiag) of the results of all elements, one per output of the function.
    end

out = cell(nargout, 1);

[out{:}] = tools.arrayfun(varargin{:});
varargout = tools.cellfun(@(c) blkdiag(c{:}), out);

end
