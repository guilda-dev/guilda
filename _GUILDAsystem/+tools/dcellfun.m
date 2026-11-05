function varargout = dcellfun(varargin)
% Apply a function to each cell and stack the results block-diagonally.
    arguments (Input, Repeating)
        varargin   % Inputs of cellfun: function handle, cell arrays and Name-Value options.
    end
    arguments (Output, Repeating)
        varargout  % Block-diagonal stack (blkdiag) of the results of all cells, one per output of the function.
    end

out = cell(nargout, 1);

[out{:}] = tools.cellfun(varargin{:});
varargout = tools.cellfun(@(c) blkdiag(c{:}), out);

end
