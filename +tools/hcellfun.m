function out = hcellfun(varargin)
    out_ = cellfun(varargin{:}, 'UniformOutput', false);
    out = horzcat(out_{:});
end