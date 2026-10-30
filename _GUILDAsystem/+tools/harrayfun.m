function out = harrayfun(varargin)
% Apply a function to each array element and concatenate the results horizontally.
%
% Same inputs as arrayfun.
    out_ = arrayfun(varargin{:}, 'UniformOutput', false);
    out = horzcat(out_{:});
end