function varargout = dcellfun(varargin)
% Apply a function to each cell and stack the results block-diagonally.
%
% Same inputs as cellfun; each output is blkdiag of the results of all cells.

out = cell(nargout, 1);

[out{:}] = tools.cellfun(varargin{:});
varargout = tools.cellfun(@(c) blkdiag(c{:}), out);

end