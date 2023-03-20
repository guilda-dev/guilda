function varargout = tools_vcellfun(varargin)
    varargout_ = cell(nargout, 1);
    [varargout_{:}] = cellfun(varargin{:}, 'UniformOutput', false);
    varargout = tools_cellfun(@(o) vertcat(o{:}), varargout_);
end