function varargout = darrayfun(varargin)
% Apply a function to each array element and stack the results block-diagonally.
%
% Same inputs as arrayfun; each output is blkdiag of the results of all elements.

out = cell(nargout, 1);

[out{:}] = tools.arrayfun(varargin{:});
varargout = tools.cellfun(@(c) blkdiag(c{:}), out);

end