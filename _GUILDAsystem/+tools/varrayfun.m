function out = varrayfun(varargin)
% Apply a function to each array element and concatenate the results vertically.
%
% Same inputs as arrayfun.
    out_ = arrayfun(varargin{:}, 'UniformOutput', false);
    out = vertcat(out_{:});
end