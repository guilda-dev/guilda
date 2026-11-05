function varargout = vcellfun(varargin)
% Apply a function to each cell and concatenate the results vertically.
    arguments (Input, Repeating)
        varargin   % Inputs of cellfun: function handle, cell arrays and Name-Value options.
    end
    arguments (Output, Repeating)
        varargout  % Vertical concatenation of the results, one per output of the function.
    end
    varargout_ = cell(nargout, 1);
    [varargout_{:}] = cellfun(varargin{:}, 'UniformOutput', false);
    varargout = tools.cellfun(@(o) vertcat(o{:}), varargout_);
end
