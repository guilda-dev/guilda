function varargout = arrayfun(varargin)
% Apply a function to each array element and return cells (arrayfun with UniformOutput=false).
%
% Same inputs as arrayfun; each output is a cell array.

    varargout = cell(nargout, 1);
    [varargout{:}] = arrayfun(varargin{:}, 'UniformOutput', false);

end