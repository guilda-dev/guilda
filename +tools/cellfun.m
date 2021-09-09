function varargout = cellfun(varargin)

    varargout = cell(nargout, 1);
    [varargout{:}] = cellfun(varargin{:}, 'UniformOutput', false);

end