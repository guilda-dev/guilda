function out = simulate(obj, t, varargin)

if nargin < 3 || isstruct(varargin{1}) || ischar(varargin{1})
    options = obj.simulate_options(varargin{:});
    u = [];
    idx_u = [];
else
    u = varargin{3};
    idx_u = varargin{4};
    options = obj.simulate_options(varargin{5:end});
end

out = obj.solve_odes(t, u, idx_u, options.fault,...
    options.x0_sys, options.x0_con_global,...
    options.x0_con_local,...
    tools.complex2vec(options.V0), tools.complex2vec(options.I0), options.linear, options);
end