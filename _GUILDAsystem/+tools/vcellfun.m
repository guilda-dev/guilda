function varargout = vcellfun(varargin)
    varargout_ = cell(nargout, 1);
    [varargout_{:}] = cellfun(varargin{:}, 'UniformOutput', false);
    varargout = tools.cellfun(@(o) vertcat(o{:}), varargout_);
end