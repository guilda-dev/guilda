function varargout = cellfun(varargin)
% Apply a function to each cell and return cells (cellfun with UniformOutput=false).
%
% Same inputs as cellfun; each output is a cell array.

    varargout = cell(nargout, 1);
    [varargout{:}] = cellfun(varargin{:}, 'UniformOutput', false);

end