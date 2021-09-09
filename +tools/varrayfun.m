function out = varrayfun(varargin)
    out_ = arrayfun(varargin{:}, 'UniformOutput', false);
    out = vertcat(out_{:});
end