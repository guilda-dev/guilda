function out = hcellfun(varargin)
% Apply a function to each cell and concatenate the results horizontally.
%
% Same inputs as cellfun.
    out_ = cellfun(varargin{:}, 'UniformOutput', false);
    out = horzcat(out_{:});
end