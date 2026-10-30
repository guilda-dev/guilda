function varargout = vcellfun(varargin)
% Apply a function to each cell and concatenate the results vertically.
%
% Same inputs as cellfun; each output is the vertical concatenation of the results.
    varargout_ = cell(nargout, 1);
    [varargout_{:}] = cellfun(varargin{:}, 'UniformOutput', false);
    varargout = tools.cellfun(@(o) vertcat(o{:}), varargout_);
end