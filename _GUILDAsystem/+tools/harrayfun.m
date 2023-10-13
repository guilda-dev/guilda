function out = harrayfun(varargin)
    out_ = arrayfun(varargin{:}, 'UniformOutput', false);
    out = horzcat(out_{:});
end