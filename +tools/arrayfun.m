function varargout = arrayfun(varargin)

    varargout = cell(nargout, 1);
    [varargout{:}] = arrayfun(varargin{:}, 'UniformOutput', false);

end