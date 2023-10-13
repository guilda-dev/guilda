function varargout = dcellfun(varargin)

out = cell(nargout, 1);

[out{:}] = tools.cellfun(varargin{:});
varargout = tools.cellfun(@(c) blkdiag(c{:}), out);

end