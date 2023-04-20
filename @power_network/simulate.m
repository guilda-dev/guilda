function out = simulate(obj, t, varargin)

if nargin < 3 || isstruct(varargin{1}) || ischar(varargin{1})
    options = obj.simulate_options(varargin{:});
    u = [];
    idx_u = [];
else
    u = varargin{1};
    idx_u = varargin{2};
    options = obj.simulate_options(varargin{3:end});
end

out = obj.solve_odes(t, u, idx_u, options.fault,...
    options.x0_sys, options.x0_con_global,...
    options.x0_con_local,...
    tools.complex2vec(options.V0), tools.complex2vec(options.I0), options.linear, options);

if options.tools
    out = tools.simulationResult(out,obj,false);
end

end