function varargout = darrayfun(varargin)

out = cell(nargout, 1);

[out{:}] = tools.arrayfun(varargin{:});
varargout = tools.cellfun(@(c) blkdiag(c{:}), out);

end